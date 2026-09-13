import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/subscription_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class PurchaseSubscriptionUseCase {
  final ISubscriptionRepository _repository;

  PurchaseSubscriptionUseCase(this._repository);

  Future<Either<Failure, SubscriptionEntity>> call({
    required String planId,
    int durationMonths = 1,
  }) => _repository.purchaseSubscription(
    planId: planId,
    durationMonths: durationMonths,
  );
}
