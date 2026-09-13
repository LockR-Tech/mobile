class MaintenanceReport {
  final String id;
  final String code;
  final String reportedById;
  final String? reporterName;
  final String lockerId;
  final String? lockerLabel;
  final String cabinetId;
  final String? cabinetName;
  final String title;
  final String description;
  final List<String> photoUrls;
  final String status;
  final String? staffNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceReport({
    required this.id,
    required this.code,
    required this.reportedById,
    this.reporterName,
    required this.lockerId,
    this.lockerLabel,
    required this.cabinetId,
    this.cabinetName,
    required this.title,
    required this.description,
    required this.photoUrls,
    required this.status,
    this.staffNote,
    required this.createdAt,
    required this.updatedAt,
  });
}
