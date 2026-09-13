import 'package:smart_laundry_locker/features/maintenance/application/use_cases/create_report_use_case.dart';
import 'package:smart_laundry_locker/features/maintenance/application/use_cases/get_my_reports_use_case.dart';
import 'package:smart_laundry_locker/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:smart_laundry_locker/features/maintenance/infrastructure/data_sources/maintenance_remote_datasource.dart';
import 'package:smart_laundry_locker/features/maintenance/infrastructure/repositories/maintenance_repository_impl.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/providers/maintenance_provider.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';

class MaintenanceInjection {
  static MaintenanceRemoteDataSource provideMaintenanceRemoteDataSource(
    ApiClient apiClient,
  ) {
    return MaintenanceRemoteDataSourceImpl(apiClient);
  }

  static MaintenanceRepository provideMaintenanceRepository(
    ApiClient apiClient,
  ) {
    final remoteDataSource = provideMaintenanceRemoteDataSource(apiClient);
    return MaintenanceRepositoryImpl(remoteDataSource: remoteDataSource);
  }

  static MaintenanceProvider provideMaintenanceProvider(ApiClient apiClient) {
    final repository = provideMaintenanceRepository(apiClient);
    return MaintenanceProvider(
      createReportUseCase: CreateReportUseCase(repository),
      getMyReportsUseCase: GetMyReportsUseCase(repository),
    );
  }
}
