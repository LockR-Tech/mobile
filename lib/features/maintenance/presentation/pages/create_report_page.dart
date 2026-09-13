import 'dart:io';
import 'dart:convert';

import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_injection.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/providers/maintenance_injection.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:smart_laundry_locker/shared/widgets/custom_input.dart';
import 'package:smart_laundry_locker/shared/widgets/custom_textarea.dart';
import 'package:image_picker/image_picker.dart';

class CreateReportPage extends StatefulWidget {
  final String lockerId;
  final String cabinetId;
  final String? lockerName;
  final String? cabinetName;
  final String? locationName;

  const CreateReportPage({
    Key? key,
    required this.lockerId,
    required this.cabinetId,
    this.lockerName,
    this.cabinetName,
    this.locationName,
  }) : super(key: key);

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<File> _capturedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  late MaintenanceProvider _provider;
  late LockerProvider _lockerProvider;

  bool _isLoadingLockerOptions = true;
  String? _lockerOptionsError;
  List<_LockerAddressOption> _lockerOptions = [];
  String? _selectedLockerOptionId;

  String _friendlyErrorMessage(String? rawError) {
    if (rawError == null || rawError.trim().isEmpty) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }

    var message = rawError.trim();

    try {
      if (message.startsWith('{') || message.startsWith('[')) {
        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic>) {
          final apiMessage = decoded['message'];
          if (apiMessage is String && apiMessage.trim().isNotEmpty) {
            message = apiMessage.trim();
          }
        }
      }
    } catch (_) {}

    final normalized = message.toLowerCase();
    if (normalized.contains('hardware') ||
        normalized.contains('phần cứng') ||
        normalized.contains('locker')) {
      return 'Lỗi phần cứng';
    }
    if (normalized.contains('iot') ||
        normalized.contains('mqtt') ||
        normalized.contains('device')) {
      return 'Lỗi IOT';
    }
    if (normalized.contains('network') ||
        normalized.contains('timeout') ||
        normalized.contains('socket') ||
        normalized.contains('kết nối')) {
      return 'Lỗi kết nối mạng';
    }
    if (normalized.contains('auth') ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('token')) {
      return 'Lỗi xác thực';
    }

    return message;
  }

  @override
  void initState() {
    super.initState();
    _provider = MaintenanceInjection.provideMaintenanceProvider(ApiClient());
    _lockerProvider = LockerInjection.provideLockerProvider(ApiClient());
    _loadLockerAddressOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _lockerProvider.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _loadLockerAddressOptions() async {
    setState(() {
      _isLoadingLockerOptions = true;
      _lockerOptionsError = null;
    });

    if (widget.lockerId.isNotEmpty && widget.cabinetId.isNotEmpty) {
      final address = widget.locationName ?? 'Địa chỉ trạm';
      final cabinetName = widget.cabinetName ?? 'Trạm';
      final lockerLabel = widget.lockerName ?? 'Ô tủ';
      final optionId = '${widget.cabinetId}::${widget.lockerId}';

      final option = _LockerAddressOption(
        id: optionId,
        lockerId: widget.lockerId,
        cabinetId: widget.cabinetId,
        displayLabel: '$address - $cabinetName - Ô $lockerLabel',
      );

      setState(() {
        _lockerOptions = [option];
        _selectedLockerOptionId = optionId;
        _isLoadingLockerOptions = false;
      });
      return;
    }

    await _lockerProvider.getLocations();
    if (!mounted) return;
    if (_lockerProvider.state.error != null) {
      setState(() {
        _isLoadingLockerOptions = false;
        _lockerOptionsError = _friendlyErrorMessage(
          _lockerProvider.state.error,
        );
      });
      return;
    }

    final options = <_LockerAddressOption>[];
    final locations = _lockerProvider.state.locations;

    for (final location in locations) {
      await _lockerProvider.getCustomerCabinets(location.id);
      if (!mounted) return;

      final cabinets = List.of(_lockerProvider.state.cabinets);
      for (final cabinet in cabinets) {
        await _lockerProvider.getCabinetLockers(cabinet.id);
        if (!mounted) return;

        final lockers = _lockerProvider.state.lockers
            .where((locker) => locker.isActive)
            .toList();

        for (final locker in lockers) {
          final address = (cabinet.address?.trim().isNotEmpty ?? false)
              ? cabinet.address!.trim()
              : location.address;
          final lockerLabel = locker.displayPosition;
          final optionId = '${cabinet.id}::${locker.id}';

          options.add(
            _LockerAddressOption(
              id: optionId,
              lockerId: locker.id,
              cabinetId: cabinet.id,
              displayLabel: '$address - ${cabinet.name} - Ô $lockerLabel',
            ),
          );
        }
      }
    }

    options.sort((a, b) => a.displayLabel.compareTo(b.displayLabel));

    String? selectedId;
    if (widget.lockerId.isNotEmpty && widget.cabinetId.isNotEmpty) {
      final matched = options.where(
        (o) => o.lockerId == widget.lockerId && o.cabinetId == widget.cabinetId,
      );
      if (matched.isNotEmpty) {
        selectedId = matched.first.id;
      }
    }
    selectedId ??= options.isNotEmpty ? options.first.id : null;

    setState(() {
      _lockerOptions = options;
      _selectedLockerOptionId = selectedId;
      _isLoadingLockerOptions = false;
      _lockerOptionsError = options.isEmpty
          ? 'Không tìm thấy locker khả dụng để báo cáo'
          : null;
    });
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().isEmpty) {
      SmartDialog.showToast('Vui lòng nhập tiêu đề');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      SmartDialog.showToast('Vui lòng nhập mô tả chi tiết');
      return;
    }
    if (_selectedLockerOptionId == null) {
      SmartDialog.showToast('Vui lòng chọn tủ đồ bị lỗi');
      return;
    }
    if (_capturedPhotos.length != 2) {
      SmartDialog.showToast('Vui lòng chụp đủ 2 ảnh sự cố');
      return;
    }

    SmartDialog.showLoading<void>(msg: 'Đang gửi báo cáo...');

    final selectedOption = _lockerOptions.firstWhere(
      (o) => o.id == _selectedLockerOptionId,
      orElse: () => _lockerOptions.first,
    );
    final lockerId = widget.lockerId.isNotEmpty
        ? widget.lockerId
        : selectedOption.lockerId;
    final cabinetId = widget.cabinetId.isNotEmpty
        ? widget.cabinetId
        : selectedOption.cabinetId;

    final result = await _provider.createReport(
      lockerId: lockerId,
      cabinetId: cabinetId,
      title: _titleController.text,
      description: _descriptionController.text,
      photos: _capturedPhotos,
    );

    SmartDialog.dismiss<void>();

    if (result != null) {
      SmartDialog.showToast('Gửi báo cáo thành công');
      if (mounted) Navigator.of(context).pop();
    } else {
      final friendlyError = _friendlyErrorMessage(_provider.error);
      SmartDialog.showToast('Gửi báo cáo thất bại: $friendlyError');
    }
  }

  Future<void> _capturePhoto() async {
    if (_capturedPhotos.length >= 2) {
      SmartDialog.showToast('Bạn chỉ có thể chụp tối đa 2 ảnh');
      return;
    }

    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _capturedPhotos.add(File(image.path));
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _capturedPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: const CustomAppBar(
        title: 'Báo cáo sự cố',
        centerTitle: true,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Tiêu đề',
              hint: 'Nhập tiêu đề sự cố',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả chi tiết',
              hint: 'Mô tả rõ vấn đề bạn gặp phải',
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            _buildLockerAddressDropdown(),
            const SizedBox(height: 16),
            _buildPhotoSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Trở về',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AISLShadcnTheme.navyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Gửi báo cáo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (maxLines > 1)
          CustomTextarea(
            controller: controller,
            placeholder: hint,
            maxLines: maxLines,
            minLines: maxLines,
            backgroundColor: Colors.white,
            borderColor: Colors.grey.shade300,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          CustomInput(
            controller: controller,
            placeholder: hint,
            backgroundColor: Colors.white,
            borderColor: Colors.grey.shade300,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Colors.black,
          ),
      ],
    );
  }

  Widget _buildLockerAddressDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tủ đồ bị lỗi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingLockerOptions)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_lockerOptionsError != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _lockerOptionsError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _loadLockerAddressOptions,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else
          CustomInput(
            controller: TextEditingController(
              text: _lockerOptions
                  .firstWhere(
                    (o) => o.id == _selectedLockerOptionId,
                    orElse: () => const _LockerAddressOption(
                      id: '',
                      lockerId: '',
                      cabinetId: '',
                      displayLabel: '',
                    ),
                  )
                  .displayLabel,
            ),
            enabled: false,
            backgroundColor: Colors.white,
            borderColor: Colors.grey.shade300,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh sự cố (chụp 2 ảnh)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(2, (index) {
            final hasImage = index < _capturedPhotos.length;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
                child: InkWell(
                  onTap: hasImage ? null : _capturePhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: hasImage
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(
                                  _capturedPhotos[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.camera,
                                color: Colors.grey.shade500,
                                size: 22,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chụp ảnh ${index + 1}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _LockerAddressOption {
  final String id;
  final String lockerId;
  final String cabinetId;
  final String displayLabel;

  const _LockerAddressOption({
    required this.id,
    required this.lockerId,
    required this.cabinetId,
    required this.displayLabel,
  });
}
