import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Trang xem và chỉnh sửa hồ sơ dành riêng cho Kỹ thuật viên Kiosk (KTV).
/// Cho phép cập nhật Họ và tên, Số điện thoại, và Đổi ảnh đại diện trực tiếp.
class TechnicianProfilePage extends StatefulWidget {
  const TechnicianProfilePage({super.key});

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
  String? _jwtUserName;
  String? _jwtUserEmail;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profile == null) {
      await profileProvider.loadProfile();
    }

    final p = profileProvider.profile;
    _jwtUserName = await TokenService.getUserName();
    _jwtUserEmail = await TokenService.getUserEmail();

    if (p != null) {
      _fullNameController.text =
          (p.fullName.isNotEmpty && p.fullName != 'Người dùng')
              ? p.fullName
              : (_jwtUserName ?? '');
      _phoneController.text = p.phoneNumber;
    } else if (_jwtUserName != null) {
      _fullNameController.text = _jwtUserName!;
    }

    try {
      final reports = await _service.reports(mine: true);
      Map<String, dynamic>? rating;
      try {
        rating = await _service.myRatingAverage();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _myReports = reports;
          _ratingAverage = rating;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    SmartDialog.showLoading(msg: 'Đang lưu thay đổi...');

    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    SmartDialog.dismiss();
    setState(() => _isSaving = false);

    if (profileProvider.isSuccess) {
      SmartDialog.showToast('Cập nhật thông tin hồ sơ thành công!');
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
              const Text(
                'Ảnh đại diện KTV',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: opsPrimary),
                title: const Text('Chụp ảnh mới'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: opsPrimary),
                title: const Text('Chọn từ bộ sưu tập'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              if (currentAvatar.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                  title: const Text(
                    'Xóa ảnh đại diện',
                    style: TextStyle(color: Color(0xFFDC2626)),
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
      SmartDialog.showLoading(msg: 'Đang tải lên ảnh đại diện...');

      final userId = profile?.id ?? await TokenService.getUserId();
      if (userId == null || userId.isEmpty) {
        SmartDialog.dismiss();
        setState(() {
          _isUploadingAvatar = false;
          _localAvatarFile = null;
        });
        SmartDialog.showToast('Không xác định được ID tài khoản');
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
          SmartDialog.showToast('Tải ảnh thất bại: ${failure.message}');
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
          SmartDialog.showToast('Đã cập nhật ảnh đại diện thành công');
        },
      );
    } catch (e) {
      if (!mounted) return;
      SmartDialog.dismiss();
      SmartDialog.showToast('Lỗi tải ảnh: $e');
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
        title: const Text('Xóa ảnh đại diện?'),
        content: const Text('Bạn có chắc chắn muốn gỡ ảnh đại diện hiện tại?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    SmartDialog.showLoading(msg: 'Đang xóa ảnh...');

    try {
      final repository = ProfileRepositoryImpl(
        remoteDataSource: ProfileRemoteDataSourceImpl(ApiClient()),
      );
      final result = await repository.deleteAvatar();
      SmartDialog.dismiss();

      if (!mounted) return;
      await result.fold(
        (failure) async => SmartDialog.showToast('Xóa ảnh thất bại: ${failure.message}'),
        (_) async {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          await context.read<ProfileProvider>().loadProfile();
          SmartDialog.showToast('Đã xóa ảnh đại diện');
        },
      );
    } catch (e) {
      if (!mounted) return;
      SmartDialog.dismiss();
      SmartDialog.showToast('Lỗi xóa ảnh: $e');
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
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text('Đăng xuất ca trực'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn kết thúc ca trực và đăng xuất khỏi tài khoản KTV Kiosk không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TokenService.clearTokens();
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final displayName = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName
        : (_jwtUserName ?? 'Kỹ thuật viên Kiosk');
    final email = (profile?.email.trim().isNotEmpty ?? false)
        ? profile!.email
        : (_jwtUserEmail ?? 'kiosk1@gmail.com');
    final avatarUrl = profile?.avatarUrl;

    // Shift metrics calculation
    final totalAssigned = _myReports.length;
    final inProgress = _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;
    final resolved = _myReports.where((r) => r['status'] == 'RESOLVED').length;
    final overdue = _myReports.where((r) => r['status'] == 'IN_PROGRESS' && r['overdue'] == true).length;
    final avgRating = _ratingAverage?['average']?.toString() ?? '5.0';

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
                  _buildShiftMetricsCard(
                    total: totalAssigned,
                    inProgress: inProgress,
                    resolved: resolved,
                    overdue: overdue,
                    avgRating: avgRating,
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
                      _isSaving ? 'Đang lưu...' : 'Lưu thay đổi thông tin',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),

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
                    label: const Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                  const Text(
                    'Hồ sơ kỹ thuật viên',
                    style: TextStyle(
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.precision_manufacturing_rounded, size: 12, color: Color(0xFF7DD3FC)),
                        SizedBox(width: 4),
                        Text(
                          'KIOSK · Kỹ thuật viên trạm tủ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFBAE6FD),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: Color(0xFF34D399)),
                        SizedBox(width: 4),
                        Text(
                          'Trực ca',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA7F3D0),
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

  Widget _buildShiftMetricsCard({
    required int total,
    required int inProgress,
    required int resolved,
    required int overdue,
    required String avgRating,
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
              const Row(
                children: [
                  Icon(Icons.query_stats_rounded, size: 18, color: opsPrimary),
                  SizedBox(width: 6),
                  Text(
                    'Chỉ số vận hành ca trực',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: opsDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: overdue == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: overdue == 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                ),
                child: Text(
                  overdue == 0 ? 'Đạt chuẩn SLA' : 'Cảnh báo SLA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: overdue == 0 ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricTile('Tổng ca', '$total', const Color(0xFF475569))),
              const SizedBox(width: 6),
              Expanded(child: _metricTile('Đang làm', '$inProgress', const Color(0xFF2563EB))),
              const SizedBox(width: 6),
              Expanded(child: _metricTile('Đã xong', '$resolved', const Color(0xFF059669))),
              const SizedBox(width: 6),
              Expanded(
                child: _metricTile(
                  'Quá hạn',
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
                const Text('Đánh giá chất lượng: ', style: TextStyle(fontSize: 12.5, color: opsDark)),
                Text('$avgRating/5.0', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: opsDark)),
                const Spacer(),
                const Text('SLA 4h tiêu chuẩn', style: TextStyle(fontSize: 11.5, color: opsMutedText)),
              ],
            ),
          ),
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

  Widget _buildFormCard({required String email}) {
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
            const Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 20, color: opsPrimary),
                SizedBox(width: 6),
                Text(
                  'Chỉnh sửa thông tin cá nhân',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: opsDark),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Họ và tên
            const Text(
              'Họ và tên kỹ thuật viên *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: opsDark),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: 'Nhập họ và tên đầy đủ',
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
                if (trimmed.isEmpty) return 'Vui lòng nhập họ và tên';
                if (trimmed.length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Số điện thoại
            const Text(
              'Số điện thoại liên hệ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: opsDark),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ví dụ: 0912345678',
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
                  return 'Số điện thoại phải có ít nhất 9 chữ số';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // Email (Cố định định danh)
            const Text(
              'Email tài khoản (Cố định)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: opsDark),
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
                      email,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 12, color: opsMutedText),
                        SizedBox(width: 3),
                        Text('Định danh', style: TextStyle(fontSize: 10, color: opsMutedText, fontWeight: FontWeight.bold)),
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
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kỹ thuật viên Kiosk (Tủ & Phần cứng)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quyền quản trị ô tủ vật lý, thiết bị IoT và xử lý sự cố trạm Kiosk.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)),
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
