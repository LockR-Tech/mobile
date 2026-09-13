import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

abstract class QrLoginRemoteDataSource {
  Future<void> confirmQrLogin(String sessionId);
}

class QrLoginRemoteDataSourceImpl implements QrLoginRemoteDataSource {
  final Dio dio;

  QrLoginRemoteDataSourceImpl({Dio? dioOverride})
    : dio = dioOverride ?? DioClient.instance.dio;

  @override
  Future<void> confirmQrLogin(String sessionId) async {
    try {
      final response = await dio.post<dynamic>(
        '/auth/qr/confirm',
        data: {'sessionId': sessionId},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Lỗi xác nhận mã QR');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception(
          'Mã QR đã hết hạn hoặc không hợp lệ. Vui lòng quét lại.',
        );
      }
      throw Exception(
        e.response?.data?['message'] ?? e.message ?? 'Lỗi hệ thống',
      );
    }
  }
}
