String? droneDestinationBlockReason({
  Object? status,
  Object? online,
  Object? landingPadStatus,
}) {
  if (online == false) return 'mất kết nối';

  final lockerStatus = '${status ?? 'ACTIVE'}'.trim().toUpperCase();
  if (lockerStatus != 'ACTIVE') {
    return lockerStatus == 'MAINTENANCE' ? 'đang bảo trì' : 'tạm ngưng';
  }

  final padStatus = landingPadStatus == null
      ? 'OK'
      : '$landingPadStatus'.trim().toUpperCase();
  if (padStatus.isEmpty || padStatus == 'OK') return null;
  return padStatus == 'MAINTENANCE'
      ? 'bãi đáp đang bảo trì'
      : 'bãi đáp đang lỗi';
}
