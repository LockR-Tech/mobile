import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/get_active_subscription_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/get_plans_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/get_pricings_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/purchase_subscription_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/data_sources/subscription_remote_data_source.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/data_sources/subscription_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/repositories/subscription_repository_impl.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/bloc/subscription_bloc.dart';

class InjectionContainer {
  static SubscriptionRemoteDataSource provideSubscriptionRemoteDataSource(
    ApiClient apiClient,
  ) => SubscriptionRemoteDataSourceImpl(apiClient);

  static SubscriptionRepositoryImpl provideSubscriptionRepository(
    ApiClient apiClient,
  ) => SubscriptionRepositoryImpl(
    provideSubscriptionRemoteDataSource(apiClient),
  );

  static GetPlansUseCase provideGetPlansUseCase(ApiClient apiClient) =>
      GetPlansUseCase(provideSubscriptionRepository(apiClient));

  static GetPricingsUseCase provideGetPricingsUseCase(ApiClient apiClient) =>
      GetPricingsUseCase(provideSubscriptionRepository(apiClient));

  static GetActiveSubscriptionUseCase provideGetActiveSubscriptionUseCase(
    ApiClient apiClient,
  ) => GetActiveSubscriptionUseCase(provideSubscriptionRepository(apiClient));

  static PurchaseSubscriptionUseCase providePurchaseSubscriptionUseCase(
    ApiClient apiClient,
  ) => PurchaseSubscriptionUseCase(provideSubscriptionRepository(apiClient));

  static SubscriptionBloc provideSubscriptionBloc(ApiClient apiClient) =>
      SubscriptionBloc(
        getPlansUseCase: provideGetPlansUseCase(apiClient),
        getActiveSubscriptionUseCase: provideGetActiveSubscriptionUseCase(
          apiClient,
        ),
        purchaseSubscriptionUseCase: providePurchaseSubscriptionUseCase(
          apiClient,
        ),
      );
}
