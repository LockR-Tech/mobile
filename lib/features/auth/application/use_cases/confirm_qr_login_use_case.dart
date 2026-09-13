import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class ConfirmQrLoginUseCase {
  final AuthRepository _repository;

  ConfirmQrLoginUseCase(this._repository);

  Future<Either<Failure, bool>> call(ConfirmQrLoginParams params) {
    return _repository.confirmQrLogin(params.sessionId);
  }
}

class ConfirmQrLoginParams {
  final String sessionId;

  const ConfirmQrLoginParams({required this.sessionId});
}
