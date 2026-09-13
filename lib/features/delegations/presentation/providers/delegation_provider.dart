import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/create_delegation_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/revoke_delegation_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/get_my_delegations_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/get_delegation_by_order_id_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/open_locker_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/application/use_cases/find_user_by_phone_use_case.dart';
import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';

class DelegationProvider extends ChangeNotifier {
  final CreateDelegationUseCase _createDelegationUseCase;
  final RevokeDelegationUseCase _revokeDelegationUseCase;
  final GetMyDelegationsUseCase _getMyDelegationsUseCase;
  final GetDelegationByOrderIdUseCase _getDelegationByOrderIdUseCase;
  final OpenLockerUseCase _openLockerUseCase;
  final FindUserByPhoneUseCase _findUserByPhoneUseCase;

  DelegationProvider({
    required CreateDelegationUseCase createDelegationUseCase,
    required RevokeDelegationUseCase revokeDelegationUseCase,
    required GetMyDelegationsUseCase getMyDelegationsUseCase,
    required GetDelegationByOrderIdUseCase getDelegationByOrderIdUseCase,
    required OpenLockerUseCase openLockerUseCase,
    required FindUserByPhoneUseCase findUserByPhoneUseCase,
  }) : this._createDelegationUseCase = createDelegationUseCase,
       this._revokeDelegationUseCase = revokeDelegationUseCase,
       this._getMyDelegationsUseCase = getMyDelegationsUseCase,
       this._getDelegationByOrderIdUseCase = getDelegationByOrderIdUseCase,
       this._openLockerUseCase = openLockerUseCase,
       this._findUserByPhoneUseCase = findUserByPhoneUseCase;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // --- State ---
  Delegation? _currentDelegation;
  Delegation? get currentDelegation => _currentDelegation;

  List<Delegation> _myDelegations = [];
  List<Delegation> get myDelegations => _myDelegations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // --- Actions ---

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchDelegationByOrderId(String orderId) async {
    _isLoading = true;
    _error = null;
    _currentDelegation = null;
    notifyListeners();

    final result = await _getDelegationByOrderIdUseCase(orderId);

    result.fold(
      (failure) {
        if (failure is NotFoundFailure) {
          // It's normal for an order not to have a delegation
          _currentDelegation = null;
        } else {
          _error = failure.message;
        }
      },
      (delegation) {
        _currentDelegation = delegation;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createDelegation(String orderId, String delegateeEmail) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _createDelegationUseCase(
      orderId: orderId,
      delegateeEmail: delegateeEmail,
    );

    bool success = false;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (delegation) {
        _currentDelegation = delegation;
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> revokeDelegation(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _revokeDelegationUseCase(id);

    bool success = false;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (delegation) {
        // Option 1: Update current delegation's status
        // Option 2: Just refetch or we can set it to the updated delegation
        _currentDelegation = delegation;
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> fetchMyDelegations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getMyDelegationsUseCase();

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (delegations) {
        _myDelegations = delegations;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> openLocker({required String accessCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _openLockerUseCase(accessCode: accessCode);

    bool success = false;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (_) {
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<UserProfile?> searchUserByPhone(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _findUserByPhoneUseCase.call(phone);

    UserProfile? found;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (user) {
        found = user;
      },
    );

    _isLoading = false;
    notifyListeners();
    return found;
  }
}
