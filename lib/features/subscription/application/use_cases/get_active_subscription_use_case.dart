import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/subscription_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetActiveSubscriptionUseCase {
  final ISubscriptionRepository _repository;

  GetActiveSubscriptionUseCase(this._repository);

  Future<Either<Failure, SubscriptionEntity>> call() =>
      _repository.getActiveSubscription();
}
