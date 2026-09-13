import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/data_sources/locker_remote_data_source.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/data_sources/locker_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/repositories/locker_repository_impl.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_injection.dart';
import 'locker_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// ============================================================
/// LOCKER FEATURE - RIVERPOD PROVIDERS
/// ============================================================
///
/// Cách sử dụng trong Widget:
/// ```dart
/// class LockerPage extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<LockerPage> createState() => _LockerPageState();
/// }
///
/// class _LockerPageState extends ConsumerState<LockerPage> {
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addPostFrameCallback((_) {
///       ref.read(lockerNotifierProvider).getLocations();
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     final provider = ref.watch(lockerNotifierProvider);
///     final state = provider.state;
///     // Dùng state.locations, state.isLoading, etc.
///   }
/// }
/// ```

// ==================== CORE PROVIDERS ====================

/// ApiClient Provider
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  // Đảm bảo DioClient đã được init trong main.dart
  return ApiClient();
});

// ==================== DATA LAYER PROVIDERS ====================

/// Remote Data Source Provider
final Provider<LockerRemoteDataSource> lockerRemoteDataSourceProvider =
    Provider<LockerRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return LockerRemoteDataSourceImpl(apiClient);
    });

/// Repository Provider
final Provider<LockerRepository> lockerRepositoryProvider =
    Provider<LockerRepository>((ref) {
      final remoteDataSource = ref.watch(lockerRemoteDataSourceProvider);
      return LockerRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: null, // TODO: implement local caching
      );
    });

// ==================== USE CASE PROVIDERS ====================

/// Use Cases Provider
final Provider<LockerUseCases> lockerUseCasesProvider =
    Provider<LockerUseCases>((ref) {
      final repository = ref.watch(lockerRepositoryProvider);
      final apiClient = ref.watch(apiClientProvider);
      return LockerInjection.provideUseCases(repository, apiClient);
    });

// ==================== STATE MANAGEMENT ====================

/// LockerNotifier Provider
///
/// Đây là main provider để quản lý state cho Locker feature.
/// Sử dụng ChangeNotifierProvider từ flutter_riverpod package.
final ChangeNotifierProvider<LockerProvider> lockerNotifierProvider =
    ChangeNotifierProvider<LockerProvider>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return LockerInjection.provideLockerProvider(apiClient);
    });
