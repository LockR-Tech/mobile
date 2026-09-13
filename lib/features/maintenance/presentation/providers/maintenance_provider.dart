import 'dart:io';
import 'package:smart_laundry_locker/features/maintenance/application/use_cases/create_report_use_case.dart';
import 'package:smart_laundry_locker/features/maintenance/application/use_cases/get_my_reports_use_case.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/entities/maintenance_report.dart';
import 'package:flutter/material.dart';

class MaintenanceProvider extends ChangeNotifier {
  final CreateReportUseCase _createReportUseCase;
  final GetMyReportsUseCase _getMyReportsUseCase;

  MaintenanceProvider({
    required CreateReportUseCase createReportUseCase,
    required GetMyReportsUseCase getMyReportsUseCase,
  }) : _createReportUseCase = createReportUseCase,
       _getMyReportsUseCase = getMyReportsUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<MaintenanceReport> _myReports = [];
  List<MaintenanceReport> get myReports => _myReports;

  Map<String, dynamic>? _pagination;
  Map<String, dynamic>? get pagination => _pagination;

  Future<MaintenanceReport?> createReport({
    required String lockerId,
    required String cabinetId,
    required String title,
    required String description,
    List<File>? photos,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _createReportUseCase(
      CreateReportParams(
        lockerId: lockerId,
        cabinetId: cabinetId,
        title: title,
        description: description,
        photos: photos,
      ),
    );

    return result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
        return null;
      },
      (report) {
        _isLoading = false;
        notifyListeners();
        return report;
      },
    );
  }

  Future<void> fetchMyReports({int page = 1, int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getMyReportsUseCase(
      GetMyReportsParams(page: page, limit: limit),
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
      },
      (reports) {
        _myReports = reports;
        _pagination = {'page': page, 'limit': limit};
        _isLoading = false;
      },
    );
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
