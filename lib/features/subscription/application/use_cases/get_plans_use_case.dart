import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetPlansUseCase {
  final ISubscriptionRepository _repository;

  GetPlansUseCase(this._repository);

  Future<Either<Failure, List<PlanEntity>>> call() => _repository.getPlans();
}
