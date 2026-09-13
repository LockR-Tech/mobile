import 'dart:io';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/maintenance/infrastructure/models/maintenance_report_model.dart';
import 'package:dio/dio.dart';

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

  Future<MaintenanceReportModel> createReport({
    required String lockerId,
    required String cabinetId,
    required String title,
    required String description,
    List<File>? photos,
  }) async {
    final Map<String, dynamic> formDataMap = {
      'lockerId': lockerId,
      'cabinetId': cabinetId,
      'title': title,
      'description': description,
    };

    if (photos != null && photos.isNotEmpty) {
      final photoFiles = <MultipartFile>[];
      for (final photo in photos) {
        final fileName = photo.path.split('/').last;
        photoFiles.add(
          await MultipartFile.fromFile(photo.path, filename: fileName),
        );
      }
      formDataMap['photos'] = photoFiles;
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/maintenance/reports/customer',
      data: formData,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] ?? responseData;

    return MaintenanceReportModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMyReports({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/maintenance/reports/my-reports',
      queryParameters: {'page': page, 'limit': limit},
    );

    final responseData = response.data as Map<String, dynamic>;
    final payload = responseData['data'] as Map<String, dynamic>? ?? {};
    final reportsList = payload['reports'] as List? ?? [];

    final reports = reportsList
        .map((e) => MaintenanceReportModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return {'reports': reports, 'pagination': payload['pagination']};
  }
}
