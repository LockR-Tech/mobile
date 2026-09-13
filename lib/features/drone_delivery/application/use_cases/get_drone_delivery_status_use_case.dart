import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/repositories/drone_delivery_repository.dart';

class GetDroneDeliveryStatusUseCase {
  final DroneDeliveryRepository _repository;

  GetDroneDeliveryStatusUseCase(this._repository);

  Future<Either<Failure, DroneDeliveryStatus>> execute(String orderId) {
    return _repository.getDeliveryStatus(orderId);
  }
}
