import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/get_active_orders_use_case.dart';
import 'package:smart_laundry_locker/features/orders/domain/repositories/order_repository.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/get_my_orders_use_case.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/get_order_detail_use_case.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/pay_overdue_fee_use_case.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/recreate_access_code_use_case.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/data_sources/order_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/repositories/order_repository_impl.dart';
import 'package:smart_laundry_locker/features/orders/presentation/providers/order_provider.dart';

/// Factory class wire các dependency layers cho orders feature
class OrderInjection {
  static OrderProvider provideOrderProvider(ApiClient apiClient) {
    final dataSource = OrderRemoteDataSourceImpl(apiClient);
    final repository = OrderRepositoryImpl(dataSource);

    final getMyOrdersUseCase = GetMyOrdersUseCase(repository);
    final getOrderDetailUseCase = GetOrderDetailUseCase(repository);
    final getActiveOrdersUseCase = GetActiveOrdersUseCase(repository);
    final payOverdueFeeUseCase = PayOverdueFeeUseCase(repository);
    final recreateAccessCodeUseCase = RecreateAccessCodeUseCase(repository);

    return OrderProvider(
      getMyOrdersUseCase: getMyOrdersUseCase,
      getOrderDetailUseCase: getOrderDetailUseCase,
      getActiveOrdersUseCase: getActiveOrdersUseCase,
      payOverdueFeeUseCase: payOverdueFeeUseCase,
      recreateAccessCodeUseCase: recreateAccessCodeUseCase,
    );
  }

  static OrderRepository provideOrderRepository(ApiClient apiClient) {
    final dataSource = OrderRemoteDataSourceImpl(apiClient);
    return OrderRepositoryImpl(dataSource);
  }
}
