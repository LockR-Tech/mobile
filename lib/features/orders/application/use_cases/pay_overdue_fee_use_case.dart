import 'package:smart_laundry_locker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';

class PayOverdueFeeUseCase {
  final OrderRepository repository;

  PayOverdueFeeUseCase(this.repository);

  Future<Either<Failure, double>> call(String orderId) async {
    return await repository.payOverdueFee(orderId);
  }
}
