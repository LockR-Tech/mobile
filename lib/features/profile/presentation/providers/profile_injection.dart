import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/update_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_courier_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/verify_current_password_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/change_password_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/security_provider.dart';

class ProfileInjection {
  static ProfileProvider provideProfileProvider(ApiClient apiClient) {
    final remoteDataSource = ProfileRemoteDataSourceImpl(apiClient);
    final repository = ProfileRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    final getProfileUseCase = GetProfileUseCase(repository);
    final updateProfileUseCase = UpdateProfileUseCase(repository);
    final getCourierProfileUseCase = GetCourierProfileUseCase(repository);

    return ProfileProvider(
      getProfileUseCase: getProfileUseCase,
      updateProfileUseCase: updateProfileUseCase,
      getCourierProfileUseCase: getCourierProfileUseCase,
      apiClient: apiClient,
    );
  }

  static ProfileRepository provideProfileRepository(ApiClient apiClient) {
    final remoteDataSource = ProfileRemoteDataSourceImpl(apiClient);
    return ProfileRepositoryImpl(remoteDataSource: remoteDataSource);
  }

  static SecurityProvider provideSecurityProvider(ApiClient apiClient) {
    final repository = provideProfileRepository(apiClient);
    final verifyCurrentPasswordUseCase = VerifyCurrentPasswordUseCase(
      repository,
    );
    final changePasswordUseCase = ChangePasswordUseCase(repository);
    return SecurityProvider(
      verifyCurrentPasswordUseCase: verifyCurrentPasswordUseCase,
      changePasswordUseCase: changePasswordUseCase,
    );
  }
}
