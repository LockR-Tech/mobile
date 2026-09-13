import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';

abstract class DelegationRepository {
  Future<Either<Failure, Delegation>> createDelegation(
    String orderId,
    String delegateeEmail,
  );

  Future<Either<Failure, Delegation>> getDelegationById(String id);

  Future<Either<Failure, Delegation>> revokeDelegation(String id);

  Future<Either<Failure, List<Delegation>>> getMyDelegations();

  Future<Either<Failure, List<Delegation>>> getDelegationsByPhone(
    String phoneNumber,
  );

  Future<Either<Failure, Delegation>> getDelegationByOrderId(String orderId);

  Future<Either<Failure, UserProfile?>> findUserByPhone(String phoneNumber);

  Future<Either<Failure, void>> openLocker({required String accessCode});
}
