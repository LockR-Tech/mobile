import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/subscription_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/data_sources/subscription_remote_data_source.dart';
import 'package:dartz/dartz.dart';

class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;

  SubscriptionRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<PlanEntity>>> getPlans() async {
    try {
      final data = await _remoteDataSource.getPlans();
      return Right(data);
    } on ServerException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PricingEntity>>> getPricings({
    String? orderType,
  }) async {
    try {
      final data = await _remoteDataSource.getPricings(orderType: orderType);
      return Right(data);
    } on ServerException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(_mapPlanFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> getActiveSubscription() async {
    try {
      final data = await _remoteDataSource.getActiveSubscription();
      return Right(data);
    } on NotFoundException {
      return const Left(
        NotFoundFailure('Bạn chưa có gói cước đang hoạt động.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> purchaseSubscription({
    required String planId,
    int durationMonths = 1,
  }) async {
    try {
      final data = await _remoteDataSource.purchaseSubscription(
        planId: planId,
        durationMonths: durationMonths,
      );
      return Right(data);
    } on ServerException catch (e) {
      return Left(_mapPurchaseFailure(e.message));
    } on ValidationException catch (e) {
      return Left(_mapPurchaseFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

Failure _mapPurchaseFailure(String message) {
  final m = message.toLowerCase();
  if (m.contains('ord-sub-001') || m.contains('ord-pln-001')) {
    return ValidationFailure(
      message.isNotEmpty ? message : 'Dữ liệu gói cước không còn hợp lệ.',
    );
  }
  if (m.contains('insufficient') || m.contains('không đủ')) {
    return const ValidationFailure('Số dư không đủ để mua gói.');
  }
  if (m.contains('không thể hạ cấp gói')) {
    return const ValidationFailure(
      'Hệ thống hiện chưa hỗ trợ hạ cấp gói cước.',
    );
  }
  if ((m.contains('active') && m.contains('subscription')) ||
      (m.contains('đã có') && m.contains('active'))) {
    return const ValidationFailure('Bạn đã có gói đang ACTIVE.');
  }
  return ValidationFailure(
    message.isNotEmpty ? message : 'Mua gói thất bại. Vui lòng thử lại.',
  );
}

Failure _mapPlanFailure(String message) {
  final m = message.toLowerCase();
  if (m.contains('ord-pln-001') ||
      m.contains('không tồn tại') ||
      m.contains('not found')) {
    return const NotFoundFailure(
      'Gói cước không còn hoạt động hoặc không tồn tại.',
    );
  }
  if (m.contains('forbidden') || m.contains('permission')) {
    return const AuthorizationFailure(
      'Bạn không có quyền truy cập danh sách gói cước customer.',
    );
  }
  return ValidationFailure(
    message.isNotEmpty ? message : 'Không thể tải danh sách gói cước.',
  );
}
