import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/media/media_upload.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';
import 'package:smart_laundry_locker/core/media/widgets/photo_picker_field.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/installation_api.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/controller_pairing_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/installation_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checklist lắp đặt một tủ (F3-G12). Bước máy kiểm được do hệ thống tự xác nhận — KTV làm việc thật
/// (quét QR gán Pi, bấm mở thử từng ô, chạy nắp) rồi server đọc kết quả từ tủ; KTV chỉ tự xác nhận bước
/// làm tay (lắp khung, kiosk — bắt buộc ảnh; Bluetooth) và chụp ảnh hiện trường.
class InstallationDetailPage extends StatefulWidget {
  const InstallationDetailPage({super.key, required this.installationId, required this.api});

  final int installationId;
  final InstallationApi api;

  @override
  State<InstallationDetailPage> createState() => _InstallationDetailPageState();
}

class _InstallationDetailPageState extends State<InstallationDetailPage> {
  Installation? _data;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  Timer? _poll;
  final Map<int, String> _boxBusy = {};

  InstallationApi get _api => widget.api;

  @override
  void initState() {
    super.initState();
    _load();
    // Đang lắp: các bước tự động đổi theo tủ (Pi online, cài sơ đồ ô, admin áp cấu hình) ⇒ tự làm mới.
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_data?.status == InstallationStatus.inProgress && !_busy) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.detail(widget.installationId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) setState(() => _error = LockerOpsService.errorMessage(e));
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  /// Chạy một thao tác đổi hồ sơ; lỗi hiện SnackBar.
  Future<void> _run(Future<Installation> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await action();
      if (!mounted) return;
      setState(() => _data = data);
      if (success != null) _snack(success);
    } catch (e) {
      if (mounted) _snack(LockerOpsService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFDC2626) : null,
      ));
  }

  Future<String?> _askReason(String title) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(hintText: context.l10n.instReasonHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.commonCancel)),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _setCheck(InstallationCheck check, String status, {bool askNote = false}) async {
    String? note;
    if (askNote) {
      note = await _askReason(status == InstallationCheckStatus.failed
          ? context.l10n.instFailReasonTitle(check.label)
          : context.l10n.instNaReasonTitle(check.label));
      if (note == null) return;
    }
    await _run(() => _api.updateCheck(widget.installationId, check.item, status, note: note));
  }

  Future<void> _addPhotos(String? item, String title) async {
    final uploaded = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PhotoUploadSheet(title: title),
    );
    if (uploaded == null || uploaded.isEmpty || !mounted) return;
    await _run(() => _api.addPhotos(widget.installationId, item, uploaded),
        success: context.l10n.instPhotosAdded(uploaded.length));
  }

  Future<void> _deletePhoto(InstallationPhoto photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.instDeletePhotoTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.commonDelete)),
        ],
      ),
    );
    if (ok == true) await _run(() => _api.deletePhoto(widget.installationId, photo.id));
  }

  Future<void> _pairController(Installation data) async {
    final bound = await ControllerPairingSheet.show(context, lockerId: data.lockerId, api: _api);
    if (bound == true && mounted) {
      _snack(context.l10n.instPairSent);
      await _load(silent: true);
    }
  }

  Future<void> _openBox(Installation data, InstallationBoxResult box) async {
    if (_boxBusy.containsKey(box.boxId)) return;
    setState(() => _boxBusy[box.boxId] = 'RUNNING');
    try {
      final result = await _api.openBox(data.lockerId, box.boxId);
      final status = '${result['status'] ?? ''}'.toUpperCase();
      final ok = result['accepted'] == true || const {'SUCCESS', 'OPEN', 'ACCEPTED'}.contains(status);
      if (mounted) {
        _snack(ok
            ? context.l10n.instBoxOpened(box.boxNumber)
            : context.l10n.instBoxOpenFailed(box.boxNumber, '${result['message'] ?? status}'),
            error: !ok);
      }
    } catch (e) {
      if (mounted) _snack(LockerOpsService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _boxBusy.remove(box.boxId));
    }
    await _load(silent: true);
  }

  Future<void> _openAllBoxes(Installation data, List<InstallationBoxResult> boxes) async {
    for (final box in boxes.where((b) => b.status != InstallationCheckStatus.passed)) {
      if (!mounted) return;
      await _openBox(data, box);
    }
  }

  Future<void> _lid(Installation data, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _api.lid(data.lockerId, action);
      final status = '${result['status'] ?? ''}'.toUpperCase();
      final ok = result['accepted'] == true || const {'SUCCESS', 'OPEN', 'ACCEPTED'}.contains(status);
      if (mounted && !ok) _snack('${result['message'] ?? status}', error: true);
    } catch (e) {
      if (mounted) _snack(LockerOpsService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _load(silent: true);
  }

  Future<void> _submit(Installation data) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.instSubmitTitle),
        content: Text(context.l10n.instSubmitBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.l10n.instSubmit)),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(() => _api.submit(widget.installationId), success: context.l10n.instSubmitted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _data;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: Text(data?.displayName ?? l10n.instListTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonReload,
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: data == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator(color: opsPrimary)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: InstallationNotice(
                        icon: Icons.error_outline,
                        color: const Color(0xFFDC2626),
                        text: _error ?? l10n.commonError,
                      ),
                    ),
            )
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _header(data),
                      const SizedBox(height: 12),
                      ..._banners(data),
                      Text(l10n.instChecklistTitle(data.doneCount, data.checks.length),
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      for (final check in data.checks) ...[
                        _checkCard(data, check),
                        const SizedBox(height: 10),
                      ],
                      _sitePhotos(data),
                      if (data.editable && data.missing.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _missing(data),
                      ],
                    ],
                  ),
                ),
                if (_busy) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
              ],
            ),
      bottomNavigationBar: data == null ? null : _bottomAction(data),
    );
  }

  Widget? _bottomAction(Installation data) {
    final l10n = context.l10n;
    Widget? button;
    if (data.status == InstallationStatus.scheduled) {
      button = FilledButton.icon(
        onPressed: _busy
            ? null
            : () => _run(() => _api.start(widget.installationId), success: l10n.instStarted),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.instStart),
      );
    } else if (data.editable) {
      button = FilledButton.icon(
        onPressed: _busy || !data.readyToSubmit ? null : () => _submit(data),
        icon: const Icon(Icons.send_rounded),
        label: Text(data.readyToSubmit ? l10n.instSubmit : l10n.instSubmitNotReady(data.missing.length)),
      );
    }
    if (button == null) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(height: 50, child: button),
      ),
    );
  }

  Widget _header(Installation data) {
    final l10n = context.l10n;
    final rows = <(IconData, String)>[
      if (data.scheduledAt != null) (Icons.event_outlined, l10n.instScheduledAt(formatInstallationTime(data.scheduledAt))),
      if (data.powerSource != null) (Icons.power_outlined, l10n.instPowerSource(data.powerSource!)),
      if (data.networkType != null || data.networkNote != null)
        (Icons.wifi, l10n.instNetwork([data.networkType, data.networkNote].whereType<String>().join(' · '))),
      if (data.cabinetModel != null || data.cabinetSerial != null)
        (Icons.inventory_2_outlined,
            l10n.instCabinet([data.cabinetModel, data.cabinetSerial].whereType<String>().join(' · '))),
      if (data.notes != null) (Icons.sticky_note_2_outlined, data.notes!),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.lockerCode == null ? data.displayName : '${data.displayName} (${data.lockerCode})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              InstallationStatusChip(status: data.status),
            ],
          ),
          const SizedBox(height: 8),
          for (final (icon, text) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                ],
              ),
            ),
          if (data.siteContactName != null || data.siteContactPhone != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.instSiteContact(
                          [data.siteContactName, data.siteContactPhone].whereType<String>().join(' · ')),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                  ),
                  if (data.siteContactPhone != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.instCall,
                      icon: const Icon(Icons.call, size: 18, color: opsPrimary),
                      onPressed: () => launchUrl(Uri(scheme: 'tel', path: data.siteContactPhone)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _banners(Installation data) {
    final l10n = context.l10n;
    final banners = <Widget>[
      if (data.status == InstallationStatus.scheduled)
        InstallationNotice(icon: Icons.info_outline, color: opsPrimary, text: l10n.instScheduledHint),
      if (data.status == InstallationStatus.inProgress && data.returnReason != null)
        InstallationNotice(
          icon: Icons.undo,
          color: const Color(0xFFB45309),
          text: l10n.instReturnedReason(data.returnReason!),
        ),
      if (data.status == InstallationStatus.submitted)
        InstallationNotice(icon: Icons.hourglass_top, color: const Color(0xFFD97706), text: l10n.instSubmittedHint),
      if (data.status == InstallationStatus.approved)
        InstallationNotice(icon: Icons.verified, color: const Color(0xFF059669), text: l10n.instApprovedHint),
      if (data.status == InstallationStatus.cancelled)
        InstallationNotice(icon: Icons.block, color: const Color(0xFF64748B), text: l10n.instCancelledHint),
      if (!data.iotAvailable)
        InstallationNotice(icon: Icons.cloud_off, color: const Color(0xFFB45309), text: l10n.instIotUnavailable),
    ];
    return [
      for (final banner in banners) ...[banner, const SizedBox(height: 10)],
    ];
  }

  Widget _checkCard(Installation data, InstallationCheck check) {
    final l10n = context.l10n;
    final style = installationCheckStyle(check.status);
    final editable = data.editable && !_busy;
    final itemPhotos = data.photosOf(check.item);
    final actions = <Widget>[];

    switch (check.item) {
      case 'CONTROLLER':
        if (data.editable) {
          actions.add(FilledButton.tonalIcon(
            onPressed: editable ? () => _pairController(data) : null,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: Text(data.controllerMac == null ? l10n.instPairAction : l10n.instPairAgain),
          ));
        }
      case 'BOX_TEST':
        break; // danh sách ô bên dưới
      case 'LID':
        if (data.editable) {
          if (check.status == InstallationCheckStatus.notApplicable) {
            actions.add(OutlinedButton(
              onPressed: editable ? () => _setCheck(check, InstallationCheckStatus.pending) : null,
              child: Text(l10n.instUndoNa),
            ));
          } else {
            actions
              ..add(OutlinedButton.icon(
                onPressed: editable ? () => _lid(data, 'open') : null,
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: Text(l10n.instLidOpen),
              ))
              ..add(OutlinedButton.icon(
                onPressed: editable ? () => _lid(data, 'close') : null,
                icon: const Icon(Icons.arrow_downward, size: 18),
                label: Text(l10n.instLidClose),
              ))
              ..add(TextButton(
                onPressed: editable
                    ? () => _setCheck(check, InstallationCheckStatus.notApplicable, askNote: true)
                    : null,
                child: Text(l10n.instMarkNa),
              ));
          }
        }
      default:
        if (!check.auto && data.editable) {
          if (check.photoRequired) {
            actions.add(OutlinedButton.icon(
              onPressed: editable ? () => _addPhotos(check.item, check.label) : null,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(l10n.instTakePhoto),
            ));
          }
          if (check.status == InstallationCheckStatus.pending) {
            actions.add(FilledButton.tonalIcon(
              onPressed: editable && (!check.photoRequired || itemPhotos.isNotEmpty)
                  ? () => _setCheck(check, InstallationCheckStatus.passed)
                  : null,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.instConfirmPassed),
            ));
            actions.add(TextButton(
              onPressed: editable ? () => _setCheck(check, InstallationCheckStatus.failed, askNote: true) : null,
              child: Text(l10n.instReportFailed),
            ));
            if (check.notApplicableAllowed) {
              actions.add(TextButton(
                onPressed: editable
                    ? () => _setCheck(check, InstallationCheckStatus.notApplicable, askNote: true)
                    : null,
                child: Text(l10n.instMarkNa),
              ));
            }
          } else {
            actions.add(TextButton(
              onPressed: editable ? () => _setCheck(check, InstallationCheckStatus.pending) : null,
              child: Text(l10n.instUndo),
            ));
          }
        }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: check.status == InstallationCheckStatus.failed
            ? const Color(0xFFFCA5A5)
            : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, color: style.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(check.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
              Text(installationCheckStatusLabel(context, check.status),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: style.color)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(check.auto ? Icons.memory : Icons.person_outline, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  check.auto ? l10n.instByAuto : (check.photoRequired ? l10n.instByTechnicianPhoto : l10n.instByTechnician),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          if (check.note != null) ...[
            const SizedBox(height: 6),
            Text(check.note!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.35)),
          ],
          if (check.item == 'CONTROLLER' && data.controllerMac != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(data.controllerOnline == true ? Icons.wifi : Icons.wifi_off,
                    size: 16, color: data.controllerOnline == true ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text(data.controllerMac!, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ],
            ),
          ],
          if (check.item == 'BOX_TEST') ..._boxTest(data, check),
          if (itemPhotos.isNotEmpty) ...[
            const SizedBox(height: 8),
            _photoStrip(data, itemPhotos),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: actions),
          ],
        ],
      ),
    );
  }

  List<Widget> _boxTest(Installation data, InstallationCheck check) {
    final l10n = context.l10n;
    final boxes = check.boxes;
    if (boxes.isEmpty) return const [];
    final canTest = data.editable && data.controllerMac != null;
    return [
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final box in boxes)
            _BoxChip(
              box: box,
              running: _boxBusy.containsKey(box.boxId),
              onTap: canTest ? () => _openBox(data, box) : null,
            ),
        ],
      ),
      if (data.editable) ...[
        const SizedBox(height: 8),
        Text(canTest ? l10n.instBoxTestHint : l10n.instBoxTestNeedController,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        if (canTest)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: OutlinedButton.icon(
              onPressed: _boxBusy.isEmpty && !_busy ? () => _openAllBoxes(data, boxes) : null,
              icon: const Icon(Icons.playlist_play, size: 18),
              label: Text(l10n.instBoxTestAll),
            ),
          ),
      ],
    ];
  }

  Widget _photoStrip(Installation data, List<InstallationPhoto> photos) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final photo = photos[i];
          return GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => Dialog(
                insetPadding: const EdgeInsets.all(12),
                child: InteractiveViewer(child: CachedNetworkImage(imageUrl: photo.url, fit: BoxFit.contain)),
              ),
            ),
            onLongPress: data.editable && !_busy ? () => _deletePhoto(photo) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: photo.thumbnailUrl ?? photo.url,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sitePhotos(Installation data) {
    final l10n = context.l10n;
    final photos = data.photosOf(null);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined,
                  color: photos.length >= 2 ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.instSitePhotos(photos.length),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.instSitePhotosHint, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            _photoStrip(data, photos),
          ],
          if (data.editable) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _addPhotos(null, l10n.instSitePhotosTitle),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(l10n.instTakePhoto),
            ),
          ],
        ],
      ),
    );
  }

  Widget _missing(Installation data) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.instMissingTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          for (final item in data.missing)
            Text('• $item', style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4)),
        ],
      ),
    );
  }
}

class _BoxChip extends StatelessWidget {
  const _BoxChip({required this.box, required this.running, this.onTap});

  final InstallationBoxResult box;
  final bool running;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = installationCheckStyle(box.status);
    return Tooltip(
      message: [box.command, box.message].whereType<String>().join(' · '),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: running ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: style.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (running)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(style.icon, size: 14, color: style.color),
              const SizedBox(width: 4),
              Text('#${box.boxNumber}', style: TextStyle(fontWeight: FontWeight.w700, color: style.color)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chụp / chọn ảnh rồi upload Cloudinary (purpose INSTALLATION_PHOTO). Trả danh sách
/// ReportAttachmentRequest (JSON) để gắn vào hồ sơ.
class _PhotoUploadSheet extends StatefulWidget {
  const _PhotoUploadSheet({required this.title});

  final String title;

  @override
  State<_PhotoUploadSheet> createState() => _PhotoUploadSheetState();
}

class _PhotoUploadSheetState extends State<_PhotoUploadSheet> {
  final _photos = PhotoPickerController(maxPhotos: 10, purpose: MediaPurpose.installationPhoto);
  String? _error;

  @override
  void dispose() {
    _photos.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _error = null);
    try {
      final uploaded = await _photos.uploadAll();
      if (mounted) Navigator.of(context).pop(uploaded);
    } catch (e) {
      if (mounted) setState(() => _error = LockerOpsService.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: ListenableBuilder(
          listenable: _photos,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.instPhotoSheetTitle(widget.title),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              PhotoPickerField(
                controller: _photos,
                enabled: !_photos.isUploading,
                accentColor: opsPrimary,
                helperText: l10n.instPhotoSheetHint,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5)),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _photos.isEmpty || _photos.isUploading ? null : _upload,
                icon: _photos.isUploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(l10n.instPhotoUpload(_photos.length)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
