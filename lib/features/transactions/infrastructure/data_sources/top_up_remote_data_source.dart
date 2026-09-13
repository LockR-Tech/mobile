import 'package:smart_laundry_locker/features/transactions/infrastructure/models/top_up_response_dto.dart';

abstract class TopUpRemoteDataSource {
  Future<TopUpResponseDto> createTopUpUrl({required int amount});
}
