import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';
import 'package:smart_laundry_locker/features/delegations/infrastructure/data_sources/delegation_remote_data_source.dart';
import 'package:smart_laundry_locker/features/delegations/infrastructure/models/delegation_model.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/models/user_profile_model.dart';

class DelegationRepositoryImpl implements DelegationRepository {
  final DelegationRemoteDataSource _remoteDataSource;

  DelegationRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserProfile?>> findUserByPhone(
    String phoneNumber,
  ) async {
    try {
      final response = await _remoteDataSource.findUserByPhone(phoneNumber);
      if (response['user'] == null) {
        return const Right(null);
      }
      final model = UserProfileModel.fromJson(
        response['user'] as Map<String, dynamic>,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Delegation>> createDelegation(
    String orderId,
    String delegateeEmail,
  ) async {
    try {
      final response = await _remoteDataSource.createDelegation(
        orderId,
        delegateeEmail,
      );
      final model = DelegationModel.fromJson(response);
      return Right(model.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Delegation>> getDelegationById(String id) async {
    try {
      final response = await _remoteDataSource.getDelegationById(id);
      final model = DelegationModel.fromJson(response);
      return Right(model.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Delegation>> revokeDelegation(String id) async {
    try {
      final response = await _remoteDataSource.revokeDelegation(id);
      final model = DelegationModel.fromJson(response);
      return Right(model.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Delegation>>> getMyDelegations() async {
    try {
      final response = await _remoteDataSource.getMyDelegations();
      final List<dynamic> delegationsList =
          (response['delegations'] as List<dynamic>?) ?? [];
      final delegations = delegationsList
          .map(
            (data) => DelegationModel.fromJson(
              data as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
      return Right(delegations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Delegation>>> getDelegationsByPhone(
    String phoneNumber,
  ) async {
    try {
      final response = await _remoteDataSource.getDelegationsByPhone(
        phoneNumber,
      );
      final List<dynamic> delegationsList =
          (response['delegations'] as List<dynamic>?) ?? [];
      final delegations = delegationsList
          .map(
            (data) => DelegationModel.fromJson(
              data as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
      return Right(delegations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Delegation>> getDelegationByOrderId(
    String orderId,
  ) async {
    try {
      final response = await _remoteDataSource.getDelegationByOrderId(orderId);
      final model = DelegationModel.fromJson(response);
      return Right(model.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> openLocker({required String accessCode}) async {
    try {
      await _remoteDataSource.openLocker(accessCode: accessCode);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
