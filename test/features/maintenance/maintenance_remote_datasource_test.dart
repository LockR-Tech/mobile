import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/maintenance/infrastructure/data_sources/maintenance_remote_datasource.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() => useBusinessConfig());

  test('báo sự cố gửi đúng tủ đã chọn, không kèm userId', () async {
    final mock = createMockApiClient();
    // Body khớp chính xác: có `userId` hay tủ khác là không khớp ⇒ ném lỗi.
    mock.adapter.onPost(
      '/api/lockers/7/report',
      (server) => server.reply(
        200,
        apiOk({
          'id': 55,
          'lockerId': 7,
          'title': 'Ô kẹt',
          'description': 'Không mở được',
          'status': 'OPEN',
          'createdAt': '2026-10-12T08:00:00',
        }),
      ),
      data: {'title': 'Ô kẹt', 'description': 'Không mở được', 'boxId': 701},
    );
    final ds = MaintenanceRemoteDataSourceImpl(mock.apiClient);

    final report = await ds.createReport(
      lockerId: '7',
      cabinetId: '7',
      title: 'Ô kẹt',
      description: 'Không mở được',
      boxId: 701,
    );
    expect(report.id, '55');
    expect(report.lockerId, '7');
  });

  test('chưa chọn tủ ⇒ dừng, không bao giờ mặc định tủ 1', () async {
    final mock = createMockApiClient();
    final ds = MaintenanceRemoteDataSourceImpl(mock.apiClient);
    await expectLater(
      ds.createReport(
        lockerId: '',
        cabinetId: '',
        title: 'Ô kẹt',
        description: 'Không mở được',
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}
