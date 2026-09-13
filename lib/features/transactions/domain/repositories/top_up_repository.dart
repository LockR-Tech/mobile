import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/top_up_result.dart';
import 'package:dartz/dartz.dart';

abstract class TopUpRepository {
  Future<Either<Failure, TopUpResult>> createTopUpUrl({required int amount});
}
