import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';

abstract class DroneDeliveryRepository {
  /// Lấy trạng thái giao drone hiện tại theo [orderId] (dùng cho pull-to-refresh
  /// và refetch khi có event FCM mới).
  Future<Either<Failure, DroneDeliveryStatus>> getDeliveryStatus(String orderId);
}
