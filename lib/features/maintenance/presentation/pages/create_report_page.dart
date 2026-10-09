import 'dart:io';
import 'dart:convert';

import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_injection.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/maintenance/infrastructure/data_sources/maintenance_remote_datasource.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/providers/maintenance_injection.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:smart_laundry_locker/shared/widgets/custom_input.dart';
import 'package:smart_laundry_locker/shared/widgets/custom_textarea.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CreateReportPage extends StatefulWidget {
  final String lockerId;
  final String cabinetId;
  final String? lockerName;
  final String? cabinetName;
  final String? locationName;
  final int? initialBoxId;

  const CreateReportPage({
    Key? key,
    required this.lockerId,
    required this.cabinetId,
    this.lockerName,
    this.cabinetName,
    this.locationName,
    this.initialBoxId,
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
  final ApiClient _apiClient = ApiClient();

  bool _isLoadingLockerOptions = true;
  String? _lockerOptionsError;
  List<_LockerAddressOption> _lockerOptions = [];
  String? _selectedLockerOptionId;

  List<Map<String, dynamic>> _boxes = [];
  int? _selectedBoxId;
  bool _isLoadingBoxes = false;

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
    if (widget.initialBoxId != null) {
      _selectedBoxId = widget.initialBoxId;
    }
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

  Future<void> _loadBoxesForLocker(String lockerId) async {
    final parsedId = int.tryParse(lockerId);
    if (parsedId == null) return;
    setState(() => _isLoadingBoxes = true);
    try {
      final res = await _apiClient.get('/api/lockers/$parsedId/layout');
      final raw = res.data;
      final data = raw is Map ? raw['data'] : null;
      final cellsRaw = data is Map ? data['cells'] : null;
      if (cellsRaw is List) {
        final cells = cellsRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        cells.sort((a, b) =>
            ((a['boxNumber'] as num?) ?? 0).compareTo((b['boxNumber'] as num?) ?? 0));
        if (mounted) {
          setState(() {
            _boxes = cells;
            if (_selectedBoxId == null && widget.initialBoxId != null) {
              _selectedBoxId = widget.initialBoxId;
            }
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingBoxes = false);
    }
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
      _loadBoxesForLocker(widget.lockerId);
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

    if (selectedId != null) {
      final matchedOpt = options.firstWhere(
        (o) => o.id == selectedId,
        orElse: () => options.first,
      );
      _loadBoxesForLocker(matchedOpt.lockerId);
    }
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
    if (_capturedPhotos.isEmpty) {
      SmartDialog.showToast('Vui lòng đính kèm ít nhất 1 ảnh sự cố');
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
      boxId: _selectedBoxId,
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

  /// Số ảnh tối đa khi tạo phiếu — admin cấu hình
  /// (`app.maintenance.report-photos-per-request-reporter`).
  int get _maxPhotos => MaintenanceRemoteDataSourceImpl.maxReportPhotos;

  int get _remainingPhotos => _maxPhotos - _capturedPhotos.length;

  /// Chụp ảnh bằng camera (1 ảnh)
  Future<void> _capturePhoto() async {
    if (_remainingPhotos <= 0) {
      SmartDialog.showToast('Tối đa $_maxPhotos ảnh');
      return;
    }
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() {
      _capturedPhotos.add(File(image.path));
    });
  }

  /// Chọn nhiều ảnh cùng lúc từ thư viện
  Future<void> _pickMultiplePhotos() async {
    if (_remainingPhotos <= 0) {
      SmartDialog.showToast('Tối đa $_maxPhotos ảnh');
      return;
    }
    final images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      limit: _remainingPhotos,
    );
    if (images.isEmpty) return;
    if (images.length > _remainingPhotos) {
      SmartDialog.showToast(
        'Chỉ lấy $_remainingPhotos ảnh đầu (tối đa $_maxPhotos)',
      );
    }
    setState(() {
      _capturedPhotos.addAll(
        images.take(_remainingPhotos).map((x) => File(x.path)),
      );
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
            _buildBoxSelectionSection(),
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

  Widget _buildBoxSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Chọn ô gặp sự cố tại Kiosk:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(Tuỳ chọn)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (_selectedBoxId != null)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedBoxId = null);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: Color(0xFFDC2626)),
                      SizedBox(width: 3),
                      Text(
                        'Bỏ chọn',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_isLoadingBoxes)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_boxes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'Không tìm thấy danh sách ô hoặc sự cố xảy ra chung toàn trạm.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          )
        else ...[
          // Thanh Chú thích trực quan (Legend) nhận diện theo sơ đồ tủ
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildBoxLegendItem(
                  icon: LucideIcons.luggage,
                  label: 'Vali (XL)',
                  bg: const Color(0xFF00B4D8),
                ),
                _buildBoxLegendItem(
                  icon: Icons.flight_rounded,
                  label: 'Drone',
                  bg: const Color(0xFF6366F1),
                ),
                _buildBoxLegendItem(
                  icon: LucideIcons.box,
                  label: 'Tiêu chuẩn',
                  bg: const Color(0xFF0284C7),
                ),
                _buildBoxLegendItem(
                  icon: LucideIcons.doorOpen,
                  label: 'Cửa đang mở',
                  bg: const Color(0xFFD97706),
                ),
              ],
            ),
          ),

          // Lưới ô Kiosk trực quan theo màu sắc sơ đồ tủ
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _boxes.map((c) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildVisualBoxCard(c),
                  );
                }).toList(),
              );
            },
          ),

          // Card thông tin xác nhận khi khách hàng đã chọn ô
          if (_selectedBoxId != null) ...[
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final match = _boxes.firstWhere(
                  (b) => (b['id'] as num?)?.toInt() == _selectedBoxId,
                  orElse: () => {},
                );
                final numVal = match['boxNumber'] ?? _selectedBoxId;
                final bCol = (match['colIndex'] as num?)?.toInt();
                final bType = ((match['cellType'] as String?) ?? '').toUpperCase();
                final bIsXl = bType == 'XL' || numVal == 1 || bCol == 0;
                final bIsDrone = !bIsXl &&
                    (match['isDrone'] == true ||
                        bType == 'DRONE' ||
                        ((bType.isEmpty) && (numVal == 2 || numVal == 3)));
                final bIsDoorOpen = match['doorOpen'] == true ||
                    ((match['hwState'] as String?)?.toUpperCase() == 'OPEN');

                final String typeLabel = bIsDrone
                    ? 'Ô Drone (Nóc tủ)'
                    : (bIsXl ? 'Ô lớn Vali (XL - Cột 1)' : 'Ô Tiêu chuẩn (Vừa)');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đang chọn: Ô #$numVal • $typeLabel',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            if (bIsDoorOpen) ...[
                              const SizedBox(height: 2),
                              const Text(
                                '⚠️ Cửa ô này hiện đang MỞ trên hệ thống.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBoxLegendItem({
    required IconData icon,
    required String label,
    required Color bg,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(icon, size: 9, color: Colors.white),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualBoxCard(Map<String, dynamic> c) {
    final cId = (c['id'] as num?)?.toInt();
    final isSel = cId != null && cId == _selectedBoxId;
    final boxNum = (c['boxNumber'] as num?)?.toInt() ?? 0;
    final col = (c['colIndex'] as num?)?.toInt();
    final cellType = ((c['cellType'] as String?) ?? '').toUpperCase();
    final st = ((c['status'] as String?) ?? 'AVAILABLE').toUpperCase();
    final isDoorOpen = c['doorOpen'] == true ||
        ((c['hwState'] as String?)?.toUpperCase() == 'OPEN');

    final isXl = cellType == 'XL' || boxNum == 1 || col == 0;
    final isDrone = !isXl &&
        (c['isDrone'] == true ||
            cellType == 'DRONE' ||
            ((cellType.isEmpty) && (boxNum == 2 || boxNum == 3)));

    final IconData boxIcon = isDrone
        ? Icons.flight_rounded
        : (isXl ? LucideIcons.luggage : LucideIcons.box);

    final String typeNote = isDrone
        ? 'Drone'
        : (isXl ? 'Vali (XL)' : 'Tiêu chuẩn');

    final String statusNote = switch (st) {
      'AVAILABLE' => isDrone ? 'Nhận Drone' : 'Sẵn sàng',
      'OCCUPIED' || 'IN_USE' => 'Đang dùng',
      'RESERVED' => 'Đã đặt',
      'FAULT' => 'Hỏng',
      'CLEANING' => 'Bảo trì',
      _ => st,
    };

    // Màu nền gradient giống 100% sơ đồ ô Tủ
    final LinearGradient bgGradient;
    if (isDrone && st == 'AVAILABLE') {
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      );
    } else {
      bgGradient = switch (st) {
        'AVAILABLE' when isXl => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
          ),
        'AVAILABLE' => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          ),
        'OCCUPIED' || 'IN_USE' => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
          ),
        'RESERVED' => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
        'FAULT' => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
        'CLEANING' => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          ),
        _ => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
          ),
      };
    }

    return GestureDetector(
      onTap: () {
        if (cId != null) {
          setState(() {
            _selectedBoxId = isSel ? null : cId;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel
                ? Colors.black87
                : (isDoorOpen ? const Color(0xFFFBBF24) : Colors.white.withValues(alpha: 0.35)),
            width: isSel ? 2.5 : (isDoorOpen ? 2.0 : 1.0),
          ),
          boxShadow: [
            if (isSel)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hàng 1: Số ô + Cửa mở/Checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Ô #$boxNum',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSel)
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Color(0xFF0F172A),
                    ),
                  )
                else if (isDoorOpen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF08A),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFFEAB308), width: 0.6),
                    ),
                    child: const Text(
                      'Mở',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF854D0E),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Hàng 2: Biểu tượng loại ô
            Center(
              child: Icon(
                boxIcon,
                color: Colors.white.withValues(alpha: 0.95),
                size: 20,
              ),
            ),
            const SizedBox(height: 4),

            // Hàng 3: Note loại ô / trạng thái
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$typeNote • $statusNote',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ảnh hiện trường sự cố',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_capturedPhotos.length} ảnh',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Có thể thêm nhiều ảnh cùng lúc từ thư viện hoặc dùng camera chụp từng ảnh (tối đa $_maxPhotos ảnh)',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        // Action buttons: Camera + Gallery
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _capturePhoto,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Chụp ảnh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickMultiplePhotos,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Chọn nhiều ảnh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_capturedPhotos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _capturedPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _capturedPhotos[index],
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Photo count badge
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ảnh ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Remove button
                    Positioned(
                      top: 3,
                      right: 3,
                      child: InkWell(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
