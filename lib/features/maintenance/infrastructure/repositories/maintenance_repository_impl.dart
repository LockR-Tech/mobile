import 'dart:io';

import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/entities/maintenance_report.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:smart_laundry_locker/features/maintenance/infrastructure/data_sources/maintenance_remote_datasource.dart';
import 'package:dartz/dartz.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final MaintenanceRemoteDataSource _remoteDataSource;

  MaintenanceRepositoryImpl({
    required MaintenanceRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, MaintenanceReport>> createReport({
    required String lockerId,
    required String cabinetId,
    required String title,
    required String description,
    List<File>? photos,
  }) async {
    try {
      final report = await _remoteDataSource.createReport(
        lockerId: lockerId,
        cabinetId: cabinetId,
        title: title,
        description: description,
        photos: photos,
      );
      return Right(report);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MaintenanceReport>>> getMyReports({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await _remoteDataSource.getMyReports(
        page: page,
        limit: limit,
      );
      final reports = result['reports'] as List<MaintenanceReport>;
      return Right(reports);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
