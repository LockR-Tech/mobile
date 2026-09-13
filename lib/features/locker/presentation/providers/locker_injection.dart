import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_available_lockers_use_case.dart';
import 'package:smart_laundry_locker/injection_container.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_cabinet_lockers_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_location_cabinets_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_location_detail_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_cabinet_by_id_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_locker_by_id_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_locker_count_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_locations_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_customer_cabinets_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_least_used_lockers_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/rent_locker_flexible_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/get_rented_locker_detail_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/open_locker_temporarily_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/finish_rental_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/fixed_rent_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/control_locker_use_case.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/data_sources/locker_remote_data_source.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/data_sources/locker_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/repositories/locker_repository_impl.dart';
import 'package:smart_laundry_locker/features/locker/presentation/bloc/locker_rent_bloc.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/get_pricings_use_case.dart';
import 'locker_provider.dart';

/// Dependency Injection cho Locker Feature
///
/// Cách sử dụng với Provider:
/// ```dart
/// // Trong main.dart hoặc app.dart
/// final apiClient = ApiClient(); // Sử dụng singleton DioClient
///
/// ChangeNotifierProvider(
///   create: (context) => LockerInjection.provideLockerProvider(apiClient),
///   child: LockerPage(),
/// )
/// ```
///
/// Hoặc với Riverpod:
/// ```dart
/// final apiClientProvider = Provider((ref) => ApiClient());
///
/// final lockerRepositoryProvider = Provider((ref) {
///   return LockerInjection.provideRepository(ref.watch(apiClientProvider));
/// });
///
/// final lockerProvider = ChangeNotifierProvider((ref) {
///   return LockerInjection.provideLockerProvider(ref.watch(apiClientProvider));
/// });
/// ```
class LockerInjection {
  LockerInjection._();

  /// Provide LockerRemoteDataSource
  static LockerRemoteDataSource provideRemoteDataSource(ApiClient apiClient) {
    return LockerRemoteDataSourceImpl(apiClient);
  }

  /// Provide LockerRepository
  static LockerRepository provideRepository(ApiClient apiClient) {
    final remoteDataSource = provideRemoteDataSource(apiClient);
    return LockerRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: null, // Optional: implement để cache offline
    );
  }

  /// Provide all Use Cases
  static LockerUseCases provideUseCases(
    LockerRepository repository,
    ApiClient apiClient,
  ) {
    return LockerUseCases(
      getLocations: GetLocationsUseCase(repository),
      getLocationDetail: GetLocationDetailUseCase(repository),
      getLocationCabinets: GetLocationCabinetsUseCase(repository),
      getCabinetLockers: GetCabinetLockersUseCase(repository),
      getAvailableLockers: GetAvailableLockersUseCase(repository),
      getLockerCount: GetLockerCountBySizeUseCase(repository),
      getCustomerCabinets: GetCustomerCabinetsUseCase(repository),
      getLeastUsedLockers: GetLeastUsedLockersUseCase(repository),
      rentLockerFlexible: RentLockerFlexibleUseCase(repository),
      getRentedLockerDetail: GetRentedLockerDetailUseCase(repository),
      openLockerTemporarily: OpenLockerTemporarilyUseCase(repository),
      finishRental: FinishRentalUseCase(repository),
      getCabinetById: GetCabinetByIdUseCase(repository),
      getLockerById: GetLockerByIdUseCase(repository),
      getPricings: InjectionContainer.provideGetPricingsUseCase(apiClient),
    );
  }

  /// Provide LockerProvider với tất cả dependencies
  static LockerProvider provideLockerProvider(ApiClient apiClient) {
    final repository = provideRepository(apiClient);
    final useCases = provideUseCases(repository, apiClient);

    return LockerProvider(
      getLocationsUseCase: useCases.getLocations,
      getLocationDetailUseCase: useCases.getLocationDetail,
      getLocationCabinetsUseCase: useCases.getLocationCabinets,
      getCabinetLockersUseCase: useCases.getCabinetLockers,
      getAvailableLockersUseCase: useCases.getAvailableLockers,
      getLockerCountUseCase: useCases.getLockerCount,
      getCustomerCabinetsUseCase: useCases.getCustomerCabinets,
      getLeastUsedLockersUseCase: useCases.getLeastUsedLockers,
      rentLockerFlexibleUseCase: useCases.rentLockerFlexible,
      getRentedLockerDetailUseCase: useCases.getRentedLockerDetail,
      openLockerTemporarilyUseCase: useCases.openLockerTemporarily,
      finishRentalUseCase: useCases.finishRental,
      getCabinetByIdUseCase: useCases.getCabinetById,
      getLockerByIdUseCase: useCases.getLockerById,
      getPricingsUseCase: useCases.getPricings,
    );
  }

  static LockerRentBloc provideLockerRentBloc(ApiClient apiClient) {
    final repository = provideRepository(apiClient);
    return LockerRentBloc(
      fixedRentUseCase: FixedRentUseCase(repository),
      rentLockerFlexibleUseCase: RentLockerFlexibleUseCase(repository),
      controlLockerUseCase: ControlLockerUseCase(repository),
    );
  }
}

/// Container cho tất cả Use Cases
class LockerUseCases {
  final GetLocationsUseCase getLocations;
  final GetLocationDetailUseCase getLocationDetail;
  final GetLocationCabinetsUseCase getLocationCabinets;
  final GetCabinetLockersUseCase getCabinetLockers;
  final GetAvailableLockersUseCase getAvailableLockers;
  final GetLockerCountBySizeUseCase getLockerCount;
  final GetCustomerCabinetsUseCase getCustomerCabinets;
  final GetLeastUsedLockersUseCase getLeastUsedLockers;
  final RentLockerFlexibleUseCase rentLockerFlexible;
  final GetRentedLockerDetailUseCase getRentedLockerDetail;
  final OpenLockerTemporarilyUseCase openLockerTemporarily;
  final FinishRentalUseCase finishRental;
  final GetCabinetByIdUseCase getCabinetById;
  final GetLockerByIdUseCase getLockerById;
  final GetPricingsUseCase getPricings;

  const LockerUseCases({
    required this.getLocations,
    required this.getLocationDetail,
    required this.getLocationCabinets,
    required this.getCabinetLockers,
    required this.getAvailableLockers,
    required this.getLockerCount,
    required this.getCustomerCabinets,
    required this.getLeastUsedLockers,
    required this.rentLockerFlexible,
    required this.getRentedLockerDetail,
    required this.openLockerTemporarily,
    required this.finishRental,
    required this.getCabinetById,
    required this.getLockerById,
    required this.getPricings,
  });
}
