import 'package:smart_laundry_locker/features/delegations/application/use_cases/create_delegation_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/find_user_by_phone_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/get_delegation_by_order_id_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/get_my_delegations_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/revoke_delegation_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/open_locker_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/infrastructure/data_sources/delegation_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/delegations/infrastructure/repositories/delegation_repository_impl.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';

class DelegationInjection {
  static DelegationProvider provideDelegationProvider(ApiClient apiClient) {
    final remoteDataSource = DelegationRemoteDataSourceImpl(apiClient);
    final repository = DelegationRepositoryImpl(remoteDataSource);
    final createDelegationUseCase = CreateDelegationUseCase(repository);
    final revokeDelegationUseCase = RevokeDelegationUseCase(repository);
    final getMyDelegationsUseCase = GetMyDelegationsUseCase(repository);
    final getDelegationByOrderIdUseCase = GetDelegationByOrderIdUseCase(
      repository,
    );
    final openLockerUseCase = OpenLockerUseCase(repository);
    final findUserByPhoneUseCase = FindUserByPhoneUseCase(repository);

    return DelegationProvider(
      createDelegationUseCase: createDelegationUseCase,
      revokeDelegationUseCase: revokeDelegationUseCase,
      getMyDelegationsUseCase: getMyDelegationsUseCase,
      getDelegationByOrderIdUseCase: getDelegationByOrderIdUseCase,
      openLockerUseCase: openLockerUseCase,
      findUserByPhoneUseCase: findUserByPhoneUseCase,
    );
  }
}
