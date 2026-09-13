import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_injection.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Delegation Provider
final ChangeNotifierProvider<DelegationProvider> delegationProvider =
    ChangeNotifierProvider<DelegationProvider>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return DelegationInjection.provideDelegationProvider(apiClient);
    });
