import 'dart:io';

import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/entities/maintenance_report.dart';
import 'package:dartz/dartz.dart';

abstract class MaintenanceRepository {
  Future<Either<Failure, MaintenanceReport>> createReport({
    required String lockerId,
    required String cabinetId,
    required String title,
    required String description,
    List<File>? photos,
  });

  Future<Either<Failure, List<MaintenanceReport>>> getMyReports({
    int page = 1,
    int limit = 10,
  });
}
