import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/entities/maintenance_report.dart';
import 'package:json_annotation/json_annotation.dart';

part 'maintenance_report_model.g.dart';

@JsonSerializable()
class MaintenanceReportModel extends MaintenanceReport {
  MaintenanceReportModel({
    required super.id,
    required super.code,
    required super.reportedById,
    super.reporterName,
    required super.lockerId,
    super.lockerLabel,
    required super.cabinetId,
    super.cabinetName,
    required super.title,
    required super.description,
    required super.photoUrls,
    required super.status,
    super.staffNote,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MaintenanceReportModel.fromJson(Map<String, dynamic> json) =>
      MaintenanceReportModel(
        id: json['id'] as String,
        code: json['code'] as String,
        reportedById: json['reportedById'] as String,
        reporterName: json['reporterName'] as String?,
        lockerId: json['lockerId'] as String,
        lockerLabel: json['lockerLabel'] as String?,
        cabinetId: json['cabinetId'] as String,
        cabinetName: json['cabinetName'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        photoUrls:
            (json['photoUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        status: json['status'] as String,
        staffNote: json['staffNote'] as String?,
        createdAt: parseServerDateTimeOr(json['createdAt']),
        updatedAt: parseServerDateTimeOr(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => _$MaintenanceReportModelToJson(this);
}
