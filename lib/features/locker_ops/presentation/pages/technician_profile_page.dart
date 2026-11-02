import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/l10n/language_picker.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/technician_rules.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/technician_session.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Trang xem và chỉnh sửa hồ sơ dùng chung cho KTV tủ và KTV drone: cập nhật
/// họ tên, số điện thoại, ảnh đại diện; chỉ số công việc lấy theo VAI TRÒ
/// (`/api/locker-technician/*` hoặc `/api/drone-technician/*`).
class TechnicianProfilePage extends StatefulWidget {
  const TechnicianProfilePage({this.droneTechnician, super.key});

  /// `true` = KTV drone, `false` = KTV tủ; `null` ⇒ tự xác định theo vai trò
  /// trong token đăng nhập.
  final bool? droneTechnician;

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final _service = LockerOpsService();

  File? _localAvatarFile;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;

  List<Map<String, dynamic>> _myReports = [];
  Map<String, dynamic>? _ratingAverage;
  Map<String, dynamic>? _performance;
  bool _statsLoading = true;
  String? _statsError;
  String? _jwtUserName;
  String? _jwtUserEmail;
  late bool _isDrone = widget.droneTechnician ?? false;
  StreamSubscription<AppEvent>? _eventSub;
  Timer? _statsDebounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Phiếu được giao/đóng, khách đánh giá, đơn drone hoàn tất ⇒ chỉ số công
    // việc đổi; tải ngầm (gom tin dồn dập).
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (!mounted || event is! MaintenanceChangedEvent) return;
      final relevant = _isDrone
          ? event.isReport || event.isDroneOrder
          : event.isReport;
      if (!relevant) return;
      _statsDebounce?.cancel();
      _statsDebounce = Timer(
        const Duration(seconds: 2),
        () => _loadStats(silent: true),
      );
    });
  }

  Future<void> _loadInitialData() async {
    final profileProvider = context.read<ProfileProvider>();
    if (widget.droneTechnician == null) {
      final roles = await TokenService.getCurrentRoles();
      if (mounted) setState(() => _isDrone = isDroneTechnicianRoles(roles));
    }
    if (profileProvider.profile == null) {
      await profileProvider.loadProfile();
    }

    final p = profileProvider.profile;
    _jwtUserName = await TokenService.getUserName();
    _jwtUserEmail = await TokenService.getUserEmail();

    if (p != null) {
      _fullNameController.text =
          (p.fullName.isNotEmpty &&
                  p.fullName != 'Người dùng' &&
                  p.fullName != L10n.current.commonUser)
              ? p.fullName
              : (_jwtUserName ?? '');
      _phoneController.text = p.phoneNumber;
    } else if (_jwtUserName != null) {
      _fullNameController.text = _jwtUserName!;
    }

    await _loadStats();
  }

  /// Chỉ số công việc theo vai trò. Lỗi ⇒ báo lỗi + "Thử lại", không hiện số 0.
  Future<void> _loadStats({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        _statsLoading = true;
        _statsError = null;
      });
    }
    final drone = _isDrone;
    final errors = <String>{};
    List<Map<String, dynamic>>? reports;
    Map<String, dynamic>? rating;
    Map<String, dynamic>? performance;
    try {
      reports = drone
          ? await _service.droneReports(mine: true)
          : await _service.reports(mine: true);
    } catch (e) {
      errors.add(LockerOpsService.errorMessage(e));
    }
    try {
      rating = await _service.myRatingAverage(drone: drone);
    } catch (e) {
      errors.add(LockerOpsService.errorMessage(e));
    }
    try {
      performance = await _service.myPerformance(drone: drone);
    } catch (e) {
      errors.add(LockerOpsService.errorMessage(e));
    }
    if (!mounted) return;
    setState(() {
      if (reports != null) _myReports = reports;
      if (rating != null) _ratingAverage = rating;
      if (performance != null) _performance = performance;
      _statsLoading = false;
      if (!silent || errors.isEmpty) {
        _statsError = errors.isEmpty ? null : errors.join(' · ');
      }
    });
  }

  @override
  void dispose() {
    _statsDebounce?.cancel();
    _eventSub?.cancel();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    SmartDialog.showLoading(msg: context.l10n.techUiSavingChanges);

    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    SmartDialog.dismiss();
    setState(() => _isSaving = false);

    if (profileProvider.isSuccess) {
      SmartDialog.showToast(context.l10n.techUiProfileUpdated);
      // Reload profile to propagate changes globally
      await profileProvider.loadProfile();
    } else if (profileProvider.error != null) {
      SmartDialog.showToast(profileProvider.error!);
    }
  }

  Future<void> _handlePickAvatar() async {
    if (_isUploadingAvatar) return;

    final profile = context.read<ProfileProvider>().profile;
    final currentAvatar = profile?.avatarUrl ?? '';

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.techUiAvatar,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: opsPrimary),
                title: Text(context.l10n.techUiTakeNewPhoto),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: opsPrimary),
                title: Text(context.l10n.techUiChooseFromGallery),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              if (currentAvatar.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                  title: Text(
                    context.l10n.techUiDeleteAvatar,
                    style: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _handleDeleteAvatar();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null || !mounted) return;

      setState(() {
        _localAvatarFile = File(picked.path);
        _isUploadingAvatar = true;
      });
      SmartDialog.showLoading(msg: context.l10n.techUiUploadingAvatar);

      final userId = profile?.id ?? await TokenService.getUserId();
      if (userId == null || userId.isEmpty) {
        SmartDialog.dismiss();
        setState(() {
          _isUploadingAvatar = false;
          _localAvatarFile = null;
        });
        SmartDialog.showToast(L10n.current.techUiAccountIdUnknown);
        return;
      }

      final repository = ProfileRepositoryImpl(
        remoteDataSource: ProfileRemoteDataSourceImpl(ApiClient()),
      );
      final result = await repository.uploadAvatar(
        userId: userId,
        filePath: picked.path,
      );

      if (!mounted) return;
      SmartDialog.dismiss();

      await result.fold(
        (failure) async {
          SmartDialog.showToast(
            L10n.current.techUiPhotoUploadFailed(failure.message),
          );
          if (mounted) {
            setState(() {
              _localAvatarFile = null;
            });
          }
        },
        (updatedProfile) async {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          await context.read<ProfileProvider>().loadProfile();
          if (mounted) {
            setState(() {
              _localAvatarFile = null;
            });
          }
          SmartDialog.showToast(L10n.current.techUiAvatarUpdated);
        },
      );
    } catch (e) {
      if (!mounted) return;
      SmartDialog.dismiss();
      SmartDialog.showToast(L10n.current.techUiPhotoUploadError('$e'));
      if (mounted) {
        setState(() {
          _localAvatarFile = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _handleDeleteAvatar() async {
    if (_isUploadingAvatar) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.techUiDeleteAvatarQuestion),
        content: Text(context.l10n.techUiDeleteAvatarBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.techUiDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    SmartDialog.showLoading(msg: context.l10n.techUiDeletingPhoto);

    try {
      final repository = ProfileRepositoryImpl(
        remoteDataSource: ProfileRemoteDataSourceImpl(ApiClient()),
      );
      final result = await repository.deleteAvatar();
      SmartDialog.dismiss();

      if (!mounted) return;
      await result.fold(
        (failure) async => SmartDialog.showToast(
          L10n.current.techUiPhotoDeleteFailed(failure.message),
        ),
        (_) async {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          await context.read<ProfileProvider>().loadProfile();
          SmartDialog.showToast(L10n.current.techUiAvatarDeleted);
        },
      );
    } catch (e) {
      if (!mounted) return;
      SmartDialog.dismiss();
      SmartDialog.showToast(L10n.current.techUiPhotoDeleteError('$e'));
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 10),
            Text(context.l10n.techUiLogoutShift),
          ],
        ),
        content: Text(
          context.l10n.techUiLogoutConfirm(
            technicianRoleLabel(drone: _isDrone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.l10n.commonCancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.commonLogout),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await logoutTechnician(context, drone: _isDrone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final displayName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName
        : (_jwtUserName ??
            (_isDrone
                ? context.l10n.ddDroneTech
                : context.l10n.techUiLockerTechnician));
    final email = (profile?.email.trim().isNotEmpty ?? false)
        ? profile!.email
        : _jwtUserEmail;
    final avatarUrl = profile?.avatarUrl;

    // Số liệu thật: danh sách phiếu đang/đã được giao + trạng thái SLA server tính.
    final sla = TechnicianSlaStatus.fromPerformance(_performance);
    final totalAssigned = _myReports.length;
    final inProgress = _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;
    final resolved = _myReports.where((r) => r['status'] == 'RESOLVED').length;
    final overdue = sla.overdue ??
        _myReports.where((r) => r['status'] == 'IN_PROGRESS' && r['overdue'] == true).length;
    final rating = ratingSummary(_ratingAverage);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Hero Banner
            _buildHeroBanner(
              displayName: displayName,
              avatarUrl: avatarUrl,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Operational summary cards
                  if (_statsError != null) ...[
                    _buildStatsError(),
                    const SizedBox(height: 12),
                  ],
                  if (_statsLoading && _myReports.isEmpty && _performance == null)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(color: opsPrimary)),
                    )
                  else
                    _buildShiftMetricsCard(
                      total: totalAssigned,
                      inProgress: inProgress,
                      resolved: resolved,
                      overdue: overdue,
                      rating: rating,
                      sla: sla,
                    ),

                  const SizedBox(height: 16),

                  // Editable Information Form Card
                  _buildFormCard(email: email),

                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opsPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _isSaving
                          ? context.l10n.techUiSaving
                          : context.l10n.techUiSaveProfileChanges,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Ngôn ngữ giao diện (dùng chung sheet với Hồ sơ khách hàng)
                  _buildLanguageTile(),

                  const SizedBox(height: 12),

                  // Logout button
                  OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      context.l10n.techUiLogoutAccount,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dòng "Ngôn ngữ" — mở sheet chọn ngôn ngữ dùng chung với Hồ sơ khách hàng.
  Widget _buildLanguageTile() {
    return Material(
      key: const ValueKey('technician-language-tile'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => pickAppLanguage(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.translate_rounded, size: 20, color: opsPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.profileLanguage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: opsDark,
                  ),
                ),
              ),
              Text(
                L10n.isEnglish
                    ? context.l10n.languageEnglish
                    : context.l10n.languageVietnamese,
                style: const TextStyle(fontSize: 13, color: opsMutedText),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: opsMutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner({
    required String displayName,
    required String? avatarUrl,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF061A30),
            Color(0xFF0A2544),
            Color(0xFF103A63),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x38061A30),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              // Top nav row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.techUiTechnicianProfile,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 38), // Balance spacer
                ],
              ),

              const SizedBox(height: 18),

              // Interactive Avatar with Camera Badge
              GestureDetector(
                onTap: _handlePickAvatar,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3.5),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0A2342),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _localAvatarFile != null
                                ? Image.file(_localAvatarFile!, fit: BoxFit.cover)
                                : (avatarUrl != null && avatarUrl.isNotEmpty)
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatarInitials(displayName),
                                      )
                                    : _avatarInitials(displayName),
                            if (_isUploadingAvatar)
                              Container(
                                color: Colors.black.withValues(alpha: 0.45),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Camera Badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Full name
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              // Role & Active Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDrone
                              ? Icons.flight_rounded
                              : Icons.precision_manufacturing_rounded,
                          size: 12,
                          color: const Color(0xFF7DD3FC),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isDrone
                              ? context.l10n.techUiRoleBadgeDrone
                              : context.l10n.techUiRoleBadgeLocker,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBAE6FD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarInitials(String name) {
    return Center(
      child: Text(
        AislBrand.initials(name),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsError() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.techUiStatsLoadFailed('$_statsError'),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(
            onPressed: _statsLoading ? null : _loadStats,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Color _slaColor(String? level) => switch (level) {
    'NORMAL' => const Color(0xFF166534),
    'WARNING' => const Color(0xFF92400E),
    'RESTRICTED' || 'SUSPENDED' => const Color(0xFF991B1B),
    _ => opsMutedText,
  };

  Widget _buildShiftMetricsCard({
    required int total,
    required int inProgress,
    required int resolved,
    required int overdue,
    required String? rating,
    required TechnicianSlaStatus sla,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.query_stats_rounded, size: 18, color: opsPrimary),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.techUiShiftMetrics,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: opsDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _slaColor(sla.level).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _slaColor(sla.level).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'SLA: ${sla.label}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _slaColor(sla.level),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricTile(context.l10n.techUiMetricReceived, '$total', const Color(0xFF475569))),
              const SizedBox(width: 6),
              Expanded(child: _metricTile(context.l10n.techUiMetricInProgress, '$inProgress', const Color(0xFF2563EB))),
              const SizedBox(width: 6),
              Expanded(child: _metricTile(context.l10n.stDone, '$resolved', const Color(0xFF059669))),
              const SizedBox(width: 6),
              Expanded(
                child: _metricTile(
                  context.l10n.enumOverdue,
                  '$overdue',
                  overdue > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 6),
                Text(
                  context.l10n.techUiQualityRating,
                  style: const TextStyle(fontSize: 12.5, color: opsDark),
                ),
                Expanded(
                  child: Text(
                    rating ?? context.l10n.techUiNoRatingYet,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: rating == null ? FontWeight.w500 : FontWeight.bold,
                      color: rating == null ? opsMutedText : opsDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (sla.reason != null) ...[
            const SizedBox(height: 8),
            Text(
              sla.reason!,
              style: TextStyle(fontSize: 11.5, color: _slaColor(sla.level)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String? email}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, size: 20, color: opsPrimary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.techUiEditPersonalInfo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: opsDark),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Họ và tên
            Text(
              context.l10n.techUiFullNameLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: opsDark),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: context.l10n.techUiFullNameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: opsPrimary),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: opsPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) {
                final trimmed = (v ?? '').trim();
                if (trimmed.isEmpty) return context.l10n.authEnterFullName;
                if (trimmed.length < 2) return context.l10n.techUiFullNameMin;
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Số điện thoại
            Text(
              context.l10n.techUiContactPhone,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: opsDark),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: context.l10n.techUiPhoneHint,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: opsPrimary),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: opsPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) {
                final trimmed = (v ?? '').trim();
                if (trimmed.isNotEmpty && trimmed.length < 9) {
                  return context.l10n.techUiPhoneMin;
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Email (Cố định định danh)
            Text(
              context.l10n.techUiAccountEmailFixed,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: opsDark),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 20, color: opsMutedText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      email == null || email.isEmpty
                          ? context.l10n.recvNoEmail
                          : email,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 12, color: opsMutedText),
                        const SizedBox(width: 3),
                        Text(
                          context.l10n.techUiIdentity,
                          style: const TextStyle(fontSize: 10, color: opsMutedText, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Phân quyền vai trò
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDrone
                              ? context.l10n.techUiRoleDroneLong
                              : context.l10n.techUiRoleLockerLong,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isDrone
                              ? context.l10n.techUiRoleDroneDesc
                              : context.l10n.techUiRoleLockerDesc,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
