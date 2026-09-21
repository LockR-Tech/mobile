import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import '../../data/assistant_service.dart';
import '../../data/models/assistant_models.dart';
import '../providers/assistant_chat_controller.dart';

/// Lịch sử hỏi đáp của tôi. Chạm để mở lại, vuốt trái hoặc nhấn giữ để xoá.
/// Luôn đóng bằng [AssistantHistoryResult] để màn chat biết hội thoại nào cần
/// mở và hội thoại nào vừa bị xoá.
class AssistantHistoryPage extends StatefulWidget {
  const AssistantHistoryPage({super.key, this.service});

  final AssistantService? service;

  @override
  State<AssistantHistoryPage> createState() => _AssistantHistoryPageState();
}

class _AssistantHistoryPageState extends State<AssistantHistoryPage> {
  late final AssistantService _service = widget.service ?? AssistantService();
  List<AssistantConversation> _items = const [];
  bool _loading = true;
  String? _error;
  final Set<int> _deleted = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.conversations();
      if (!mounted) return;
      setState(() => _items = items);
    } on AssistantException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _close({int? openId}) {
    context.pop(
      AssistantHistoryResult(
        openConversationId: openId,
        deletedIds: Set.unmodifiable(_deleted),
      ),
    );
  }

  /// Hỏi xác nhận rồi xoá; true nếu đã xoá trên máy chủ.
  Future<bool> _confirmAndDelete(AssistantConversation item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá cuộc hội thoại?'),
        content: Text(
          'Cuộc hội thoại “${item.title}” sẽ bị xoá vĩnh viễn và không '
          'khôi phục được.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    try {
      await _service.deleteConversation(item.id);
      _deleted.add(item.id);
      _toast('Đã xoá cuộc hội thoại');
      return true;
    } on AssistantException catch (e) {
      _toast(e.message);
      return false;
    }
  }

  void _removeLocally(AssistantConversation item) {
    setState(() => _items = _items.where((c) => c.id != item.id).toList());
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: context.pageBg,
        body: Column(
          children: [
            BrandHeroHeader(
              eyebrow: 'LOCK.R • TRỢ LÝ',
              title: 'Lịch sử hỏi đáp',
              subtitle: 'Các cuộc hội thoại của bạn với trợ lý',
              onBack: _close,
              trailing: BrandCircleIconButton(
                icon: LucideIcons.refreshCw,
                onTap: _load,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AislBrand.navy),
      );
    }
    final error = _error;
    if (error != null) {
      return _CenteredMessage(
        icon: LucideIcons.circleAlert,
        title: error,
        actionLabel: 'Thử lại',
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return _CenteredMessage(
        icon: LucideIcons.messagesSquare,
        title: 'Chưa có cuộc hội thoại nào',
        body: 'Các câu bạn hỏi trợ lý sẽ được lưu ở đây để xem lại.',
        actionLabel: 'Đặt câu hỏi',
        onAction: _close,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AislBrand.navy,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Dismissible(
            key: ValueKey('assistant-conversation-${item.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmAndDelete(item),
            onDismissed: (_) => _removeLocally(item),
            background: const _DeleteBackground(),
            child: _ConversationTile(
              item: item,
              onTap: () => _close(openId: item.id),
              onLongPress: () async {
                if (await _confirmAndDelete(item) && mounted) {
                  _removeLocally(item);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  final AssistantConversation item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final time = _timeLabel(item.updatedAt ?? item.createdAt);
    return Material(
      color: context.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AislBrand.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.messagesSquare,
                  size: 20,
                  color: AislBrand.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        '${item.messageCount} tin nhắn',
                        if (time != null) time,
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: context.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _timeLabel(DateTime? time) {
    if (time == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final clock = '${two(time.hour)}:${two(time.minute)}';
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay, $clock';
    if (diff == 1) return 'Hôm qua, $clock';
    return '${two(time.day)}/${two(time.month)}/${time.year}';
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.trash2, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            'Xoá',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: AislBrand.navy),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
