import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/profile/domain/account_reminders.dart';
import 'package:smart_laundry_locker/features/profile/domain/legal_document.dart';
import 'package:smart_laundry_locker/features/profile/domain/legal_text.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/terms_consent_dialog.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Trang đọc Điều khoản dịch vụ / Chính sách bảo mật: thẻ trạng thái đồng ý, mục lục, từng mục một thẻ.
///
/// Khách đã đăng nhập mà chưa đồng ý (tài khoản có từ trước khi có bước đồng ý) thấy thanh "Đồng ý" ở
/// cuối trang ⇒ `POST /api/user/terms`. Một lần đồng ý áp dụng cho cả hai văn bản.
class PolicyPage extends StatefulWidget {
  const PolicyPage({super.key, required this.document});

  final LegalDocument document;

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  final ScrollController _scroll = ScrollController();
  late LegalDocument _document = widget.document;
  Future<LegalText>? _text;
  Locale? _textLocale;
  List<GlobalKey> _sectionKeys = const [];

  bool _isCustomer = false;
  bool _checked = false;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_text == null || locale != _textLocale) _load(locale);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _load(Locale locale) {
    _textLocale = locale;
    _text = rootBundle.loadString(_document.assetPath(locale)).then((md) {
      final text = LegalText.parse(md);
      _sectionKeys = List.generate(text.sections.length, (_) => GlobalKey());
      return text;
    });
  }

  Future<void> _loadRole() async {
    if (!TokenService.authState.value) return;
    final roles = await TokenService.getCurrentRoles();
    if (!mounted || primaryRole(roles) != AppRole.customer) return;
    setState(() => _isCustomer = true);
    final provider = context.read<ProfileProvider>();
    if (!provider.hasServerProfile) await provider.loadProfile();
  }

  void _switchTo(LegalDocument document) {
    if (document == _document) return;
    setState(() {
      _document = document;
      _load(_textLocale ?? Localizations.localeOf(context));
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _scrollToSection(int index) {
    final target = _sectionKeys[index].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onLink(String? href) async {
    if (href == null) return;
    final doc = LegalDocument.fromId(href);
    if (doc != null) {
      _switchTo(doc);
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri != null && uri.hasScheme)
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _accept(ProfileProvider provider) async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final error = await provider.acceptTerms(currentTermsVersion);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveError = error;
    });
    if (error == null) SmartDialog.showToast(context.l10n.legalAcceptedToast);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;
    // Chỉ hỏi khi đã có hồ sơ thật từ máy chủ — hồ sơ dựng tạm lúc mất mạng luôn coi như đã đồng ý.
    final consentKnown =
        _isCustomer && provider.hasServerProfile && profile != null;
    final needsConsent = consentKnown && !profile.termsAccepted;
    final showConsentBar = needsConsent && !TermsConsentDialog.isShowing;

    return Scaffold(
      backgroundColor: context.pageBg,
      body: BrandHeroScaffold(
        header: (collapse) => BrandHeroHeader(
          art: _document == LegalDocument.terms
              ? HeroArt.report
              : HeroArt.security,
          title: _document.title(context.l10n),
          subtitle: _document == LegalDocument.terms
              ? context.l10n.legalTermsSubtitle
              : context.l10n.legalPrivacySubtitle,
          onBack: () => AppRouter.backOrHome(context),
          collapseProgress: collapse,
        ),
        child: FutureBuilder<LegalText>(
          future: _text,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _buildError();
            final text = snapshot.data;
            if (text == null)
              return const Center(child: CircularProgressIndicator());
            return SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDocumentSwitch(),
                  const SizedBox(height: 12),
                  if (consentKnown) ...[
                    _ConsentStatusCard(
                      acceptedAt: profile.termsAcceptedAt,
                      accepted: !needsConsent,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildIntro(text),
                  if (text.sections.length > 1) ...[
                    const SizedBox(height: 12),
                    _buildContents(text),
                  ],
                  for (var i = 0; i < text.sections.length; i++) ...[
                    const SizedBox(height: 12),
                    _SectionCard(
                      key: _sectionKeys[i],
                      section: text.sections[i],
                      styleSheet: _markdownStyle(context),
                      onTapLink: _onLink,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: showConsentBar ? _buildConsentBar(provider) : null,
    );
  }

  Widget _buildDocumentSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final doc in LegalDocument.values)
            Expanded(
              child: GestureDetector(
                key: ValueKey('legal-tab-${doc.id}'),
                onTap: () => _switchTo(doc),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: doc == _document
                        ? context.cardBg
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: doc == _document
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        doc == LegalDocument.terms
                            ? LucideIcons.fileText
                            : LucideIcons.shieldCheck,
                        size: 16,
                        color: doc == _document
                            ? AislBrand.blue
                            : context.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          doc.title(context.l10n),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: doc == _document
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: doc == _document
                                ? context.textPrimary
                                : context.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntro(LegalText text) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (text.meta.isNotEmpty)
            Row(
              children: [
                Icon(
                  LucideIcons.calendarCheck,
                  size: 15,
                  color: context.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text.meta,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          if (text.intro.isNotEmpty) ...[
            const SizedBox(height: 10),
            MarkdownBody(
              data: text.intro,
              styleSheet: _markdownStyle(context),
              onTapLink: (_, href, _) => _onLink(href),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContents(LegalText text) {
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.legalContents,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < text.sections.length; i++)
            InkWell(
              onTap: () => _scrollToSection(i),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        text.sections[i].number,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AislBrand.blue,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text.sections[i].title,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: context.textMuted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConsentBar(ProfileProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: const ValueKey('legal-consent-check'),
                onTap: _saving
                    ? null
                    : () => setState(() => _checked = !_checked),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _checked,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _checked = v ?? false),
                      activeColor: AislBrand.blue,
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.tcAgreeCheckbox,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 0, 4),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12.5),
                  ),
                ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: FilledButton(
                  key: const ValueKey('legal-consent-accept'),
                  onPressed: _checked && !_saving
                      ? () => _accept(provider)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AislBrand.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.legalAgreeButton,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileWarning, size: 48, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              context.l10n.polLoadFailed,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => setState(
                () => _load(_textLocale ?? Localizations.localeOf(context)),
              ),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final body = TextStyle(
      fontSize: 14.5,
      height: 1.6,
      color: context.textPrimary,
    );
    return MarkdownStyleSheet(
      p: body,
      listBullet: body,
      listIndent: 20,
      blockSpacing: 10,
      strong: const TextStyle(fontWeight: FontWeight.w700),
      a: const TextStyle(
        color: AislBrand.blue,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.section,
    required this.styleSheet,
    required this.onTapLink,
  });

  final LegalSection section;
  final MarkdownStyleSheet styleSheet;
  final void Function(String? href) onTapLink;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AislBrand.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  section.number,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AislBrand.blue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownBody(
            data: section.body,
            styleSheet: styleSheet,
            onTapLink: (_, href, _) => onTapLink(href),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "Bạn đã đồng ý lúc …" / "Bạn chưa đồng ý" ở đầu trang.
class _ConsentStatusCard extends StatelessWidget {
  const _ConsentStatusCard({required this.accepted, this.acceptedAt});

  final bool accepted;
  final DateTime? acceptedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = accepted
        ? (context.isDark ? const Color(0xFF68D391) : AislBrand.statusGreenText)
        : (context.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309));
    final at = acceptedAt;
    final detail = !accepted
        ? l10n.legalConsentPendingBody
        : at == null
        ? l10n.legalConsentAcceptedBoth
        : l10n.legalConsentAcceptedAt(
            DateFormat('HH:mm dd/MM/yyyy').format(at.toLocal()),
          );
    return Container(
      key: ValueKey(
        accepted ? 'legal-consent-accepted' : 'legal-consent-pending',
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            accepted ? LucideIcons.badgeCheck : LucideIcons.triangleAlert,
            size: 22,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepted ? l10n.legalStatusAccepted : l10n.legalStatusPending,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
