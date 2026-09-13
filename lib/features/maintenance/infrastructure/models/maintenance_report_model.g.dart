// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceReportModel _$MaintenanceReportModelFromJson(
  Map<String, dynamic> json,
) => MaintenanceReportModel(
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
  photoUrls: (json['photoUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  status: json['status'] as String,
  staffNote: json['staffNote'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$MaintenanceReportModelToJson(
  MaintenanceReportModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'reportedById': instance.reportedById,
  'reporterName': instance.reporterName,
  'lockerId': instance.lockerId,
  'lockerLabel': instance.lockerLabel,
  'cabinetId': instance.cabinetId,
  'cabinetName': instance.cabinetName,
  'title': instance.title,
  'description': instance.description,
  'photoUrls': instance.photoUrls,
  'status': instance.status,
  'staffNote': instance.staffNote,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
