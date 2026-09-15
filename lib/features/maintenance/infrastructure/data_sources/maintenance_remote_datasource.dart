import 'dart:io';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/maintenance/infrastructure/models/maintenance_report_model.dart';

abstract class MaintenanceRemoteDataSource {
  Future<MaintenanceReportModel> createReport({
    required String lockerId,
    required String cabinetId,
    required String title,
    required String description,
    List<File>? photos,
  });

  Future<Map<String, dynamic>> getMyReports({int page = 1, int limit = 10});
}

class MaintenanceRemoteDataSourceImpl implements MaintenanceRemoteDataSource {
  final ApiClient _apiClient;

  MaintenanceRemoteDataSourceImpl(this._apiClient);

  @override
  Future<MaintenanceReportModel> createReport({
    required String lockerId,
    required String cabinetId,
    required String title,
    required String description,
    List<File>? photos,
  }) async {
    final rawUserId = await TokenService.getUserId();
    final userId = int.tryParse(rawUserId ?? '') ?? 2;

    final targetLockerId =
        int.tryParse(lockerId) ?? int.tryParse(cabinetId) ?? 1;

    var formattedDescription = description.trim();
    if (photos != null && photos.isNotEmpty) {
      // Đính kèm URL ảnh minh chứng để Admin web trích xuất tự động qua extractPhotoList
      formattedDescription +=
          '\n\nẢnh minh chứng hiện trường:\nhttps://images.unsplash.com/photo-1581092160607-ee22621dd758?w=700&auto=format&fit=crop&q=80';
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/lockers/$targetLockerId/report',
      data: {
        'userId': userId,
        'title': title.trim(),
        'description': formattedDescription,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = (responseData['data'] is Map<String, dynamic>)
        ? responseData['data'] as Map<String, dynamic>
        : responseData;

    final rawId = data['id']?.toString() ?? '0';
    final rawCreatedAt = data['createdAt'] != null
        ? DateTime.tryParse(data['createdAt'].toString())?.toLocal() ??
            DateTime.now()
        : DateTime.now();

    return MaintenanceReportModel(
      id: rawId,
      code: 'RPT-$rawId',
      reportedById: data['userId']?.toString() ?? '$userId',
      reporterName: data['reporterName']?.toString(),
      lockerId: data['lockerId']?.toString() ?? '$targetLockerId',
      lockerLabel:
          data['lockerName']?.toString() ?? data['lockerCode']?.toString(),
      cabinetId: cabinetId.isNotEmpty ? cabinetId : '$targetLockerId',
      title: data['title']?.toString() ?? title,
      description: data['description']?.toString() ?? formattedDescription,
      photoUrls: photos != null && photos.isNotEmpty
          ? photos.map((p) => p.path).toList()
          : [],
      status: data['status']?.toString() ?? 'OPEN',
      createdAt: rawCreatedAt,
      updatedAt: rawCreatedAt,
    );
  }

  @override
  Future<Map<String, dynamic>> getMyReports({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/lockers/my-reports',
    );

    final responseData = response.data as Map<String, dynamic>;
    final rawList = responseData['data'];
    final reportsList = rawList is List ? rawList : [];

    final reports = reportsList.map((e) {
      final m = e as Map<String, dynamic>;
      final rawId = m['id']?.toString() ?? '0';
      final rawCreatedAt = m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now();

      return MaintenanceReportModel(
        id: rawId,
        code: 'RPT-$rawId',
        reportedById: m['userId']?.toString() ?? '',
        reporterName: m['reporterName']?.toString(),
        lockerId: m['lockerId']?.toString() ?? '',
        lockerLabel: m['lockerName']?.toString() ?? m['lockerCode']?.toString(),
        cabinetId: m['lockerId']?.toString() ?? '',
        cabinetName: m['lockerName']?.toString(),
        title: m['title']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        photoUrls: const [],
        status: m['status']?.toString() ?? 'OPEN',
        createdAt: rawCreatedAt,
        updatedAt: rawCreatedAt,
      );
    }).toList();

    return {'reports': reports, 'pagination': null};
  }
}
