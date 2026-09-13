import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetPricingsUseCase {
  final ISubscriptionRepository _repository;

  GetPricingsUseCase(this._repository);

  Future<Either<Failure, List<PricingEntity>>> call({String? orderType}) =>
      _repository.getPricings(orderType: orderType);
}
