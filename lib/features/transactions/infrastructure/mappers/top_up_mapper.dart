import 'package:smart_laundry_locker/features/transactions/domain/entities/top_up_result.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/models/top_up_response_dto.dart';

class TopUpMapper {
  const TopUpMapper._();

  static TopUpResult toEntity(TopUpResponseDto dto) {
    return TopUpResult(paymentUrl: dto.paymentUrl, txnRef: dto.txnRef);
  }
}
