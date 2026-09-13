import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/top_up_result.dart';
import 'package:smart_laundry_locker/features/transactions/domain/repositories/top_up_repository.dart';
import 'package:dartz/dartz.dart';

@Deprecated('Dùng InitiateTopUpUseCase thay thế.')
class CreateTopUpUrlUseCase {
  final TopUpRepository repository;

  CreateTopUpUrlUseCase(this.repository);

  Future<Either<Failure, TopUpResult>> call({required int amount}) {
    return repository.createTopUpUrl(amount: amount);
  }
}
