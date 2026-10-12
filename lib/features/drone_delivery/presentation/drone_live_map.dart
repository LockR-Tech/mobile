import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';

/// Đơn chạy chế độ mô phỏng (DEMO): vị trí drone do server nội suy, không phải
/// GPS thật — mọi nơi hiện vị trí phải ghi rõ "mô phỏng".
bool droneIsSimulated(DroneDeliveryStatus status) =>
    (status.fulfillmentMode ?? '').toUpperCase() == 'DEMO';

/// Có mời khách mở bản đồ theo dõi trực tiếp không: cờ Phase 2 bật, đơn có
/// nguồn vị trí (đơn DEMO hoặc drone thật còn gửi telemetry — server cũ chưa
/// trả `liveTracking` thì chỉ đơn DEMO) và drone đang trên đường.
bool droneLiveMapAvailable(DroneDeliveryStatus status) =>
    FeatureFlags.droneLiveMapEnabled &&
    (status.liveTracking ?? droneIsSimulated(status)) &&
    (status.stage == DroneDeliveryStage.departed ||
        status.stage == DroneDeliveryStage.enRoute ||
        status.stage == DroneDeliveryStage.approaching);
