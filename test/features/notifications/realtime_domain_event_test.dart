import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_provider.dart';

/// Gom các sự kiện miền phát ra trong một lần dịch tin realtime.
Future<List<AppEvent>> _eventsOf(void Function() emit) async {
  final events = <AppEvent>[];
  final sub = AppEventBus.instance.events.listen(events.add);
  emit();
  await Future<void>.delayed(Duration.zero);
  await sub.cancel();
  return events;
}

void main() {
  test('hoàn tiền gắn đơn (REFUND_COMPLETED, ORDER) làm mới đơn và hoàn tiền', () async {
    final events = await _eventsOf(
      () => NotificationProvider.emitDomainEvent(
        'REFUND_COMPLETED',
        '42',
        referenceType: 'ORDER',
      ),
    );

    final order = events.whereType<OrderChangedEvent>().single;
    expect(order.orderId, '42');
    expect(events.whereType<RefundUpdatedEvent>().single.orderId, '42');
  });

  test('trả lời phản hồi chỉ có referenceType ORDER vẫn làm mới đơn', () async {
    final events = await _eventsOf(
      () => NotificationProvider.emitDomainEvent(
        'FEEDBACK_REPLY',
        '7',
        referenceType: 'ORDER',
      ),
    );

    expect(events.whereType<OrderChangedEvent>().single.orderId, '7');
  });

  test('wallet.updated (ví đã gỡ khỏi app) không làm mới đơn', () async {
    final events = await _eventsOf(
      () => NotificationProvider.emitDomainEvent(
        'wallet.updated',
        '55',
        referenceType: 'WALLET',
      ),
    );

    expect(events.whereType<OrderChangedEvent>(), isEmpty);
  });

  test('loyalty.points.changed làm mới điểm thưởng, không đụng đơn', () async {
    final events = await _eventsOf(
      () => NotificationProvider.emitDomainEvent(
        'loyalty.points.changed',
        null,
        referenceType: 'LOYALTY',
      ),
    );

    expect(events.whereType<LoyaltyUpdatedEvent>().single, isNotNull);
    expect(events.whereType<OrderChangedEvent>(), isEmpty);
  });

  test('phiếu sự cố KTV xử lý xong làm mới báo cáo của khách', () async {
    final events = await _eventsOf(
      () => NotificationProvider.emitDomainEvent(
        'locker.report.resolved',
        '9',
        referenceType: 'LOCKER_REPORT',
      ),
    );

    expect(events.whereType<ReportUpdatedEvent>().first.reportId, '9');
  });

  test('tin danh mục công khai: thiếu entity thì bỏ, có thì chuẩn hoá', () {
    expect(CatalogChangeMessage.fromJson({'id': 3}), isNull);

    final change = CatalogChangeMessage.fromJson({'entity': 'promotion', 'id': 12});
    expect(change!.entity, CatalogChangedEvent.promotion);
    expect(change.id, '12');
  });

  test('tin đồng bộ /user/queue/events đọc type + tham chiếu', () {
    final sync = UserSyncMessage.fromJson({
      'type': 'wallet.updated',
      'referenceType': 'WALLET',
      'referenceId': 55,
    });
    expect(sync.type, 'wallet.updated');
    expect(sync.referenceType, 'WALLET');
    expect(sync.referenceId, '55');
  });

  test('tin bảo trì cho KTV: đọc loại, mã, mã tủ; thiếu loại thì bỏ', () {
    expect(MaintenanceChangeMessage.fromJson({'id': 3}), isNull);

    final change = MaintenanceChangeMessage.fromJson({
      'entity': 'report',
      'id': 34,
      'lockerId': 5,
    });
    expect(change!.entity, MaintenanceChangedEvent.report);
    expect(change.id, '34');
    expect(change.lockerId, '5');
  });

  test('chỉ KTV và ADMIN đăng ký topic nhân viên (khách bị server từ chối)', () {
    expect(isMaintenanceStaff(['LOCKER_TECHNICIAN']), isTrue);
    expect(isMaintenanceStaff(['ROLE_DRONE_TECHNICIAN']), isTrue);
    expect(isMaintenanceStaff(['ROLE_ADMIN', 'ROLE_USER']), isTrue);
    expect(isMaintenanceStaff(['USER']), isFalse);
    expect(isMaintenanceStaff(const []), isFalse);
  });
}
