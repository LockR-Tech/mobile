import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/entities/maintenance_report.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:dartz/dartz.dart';

class GetMyReportsUseCase {
  final MaintenanceRepository _repository;

  GetMyReportsUseCase(this._repository);

  Future<Either<Failure, List<MaintenanceReport>>> call(
    GetMyReportsParams params,
  ) async {
    return _repository.getMyReports(page: params.page, limit: params.limit);
  }
}

class GetMyReportsParams {
  final int page;
  final int limit;

  const GetMyReportsParams({this.page = 1, this.limit = 10});
}
