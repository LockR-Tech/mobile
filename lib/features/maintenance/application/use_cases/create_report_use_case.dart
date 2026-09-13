import 'dart:io';

import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/entities/maintenance_report.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:dartz/dartz.dart';

class CreateReportUseCase {
  final MaintenanceRepository _repository;

  CreateReportUseCase(this._repository);

  Future<Either<Failure, MaintenanceReport>> call(
    CreateReportParams params,
  ) async {
    return _repository.createReport(
      lockerId: params.lockerId,
      cabinetId: params.cabinetId,
      title: params.title,
      description: params.description,
      photos: params.photos,
    );
  }
}

class CreateReportParams {
  final String lockerId;
  final String cabinetId;
  final String title;
  final String description;
  final List<File>? photos;

  const CreateReportParams({
    required this.lockerId,
    required this.cabinetId,
    required this.title,
    required this.description,
    this.photos,
  });
}
