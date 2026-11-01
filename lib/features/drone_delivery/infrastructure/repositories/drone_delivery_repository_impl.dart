import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/repositories/drone_delivery_repository.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/data_sources/drone_delivery_remote_datasource.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class DroneDeliveryRepositoryImpl implements DroneDeliveryRepository {
  final DroneDeliveryRemoteDataSource _remoteDataSource;

  DroneDeliveryRepositoryImpl({DroneDeliveryRemoteDataSource? remoteDataSource})
    : _remoteDataSource =
          remoteDataSource ?? DroneDeliveryRemoteDataSourceImpl();

  @override
  Future<Either<Failure, DroneDeliveryStatus>> getDeliveryStatus(
    String orderId,
  ) async {
    try {
      final response = await _remoteDataSource.getDeliveryStatus(orderId);
      return Right(response.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on AuthorizationException {
      return Left(
        ServerFailure(
          L10n.current.droneNoPermission,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(ServerFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(
        UnknownFailure(L10n.current.droneStatusLoadFailedRetrying),
      );
    }
  }
}
