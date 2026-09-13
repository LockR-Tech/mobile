import 'package:smart_laundry_locker/features/orders/application/use_cases/get_my_orders_use_case.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/get_order_detail_use_case.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/get_active_orders_use_case.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/pay_overdue_fee_use_case.dart';
import 'package:smart_laundry_locker/features/orders/application/use_cases/recreate_access_code_use_case.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order_detail.dart';
import 'package:smart_laundry_locker/core/domain/entities/pagination.dart';
import 'package:flutter/material.dart';

/// OrderProvider - ChangeNotifier quản lý state của orders
class OrderProvider extends ChangeNotifier {
  final GetMyOrdersUseCase _getMyOrdersUseCase;
  final GetOrderDetailUseCase _getOrderDetailUseCase;
  final GetActiveOrdersUseCase _getActiveOrdersUseCase;
  final PayOverdueFeeUseCase _payOverdueFeeUseCase;
  final RecreateAccessCodeUseCase _recreateAccessCodeUseCase;

  OrderProvider({
    required GetMyOrdersUseCase getMyOrdersUseCase,
    required GetOrderDetailUseCase getOrderDetailUseCase,
    required GetActiveOrdersUseCase getActiveOrdersUseCase,
    required PayOverdueFeeUseCase payOverdueFeeUseCase,
    required RecreateAccessCodeUseCase recreateAccessCodeUseCase,
  }) : _getMyOrdersUseCase = getMyOrdersUseCase,
       _getOrderDetailUseCase = getOrderDetailUseCase,
       _getActiveOrdersUseCase = getActiveOrdersUseCase,
       _payOverdueFeeUseCase = payOverdueFeeUseCase,
       _recreateAccessCodeUseCase = recreateAccessCodeUseCase;

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

  // ==================== State ====================
  List<Order> _orders = [];
  List<Order> get orders => _orders;

  Pagination? _pagination;
  Pagination? get pagination => _pagination;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  // Detail state
  Order? _selectedOrder;
  Order? get selectedOrder => _selectedOrder;

  List<OrderDetail> _orderDetails = [];
  List<OrderDetail> get orderDetails => _orderDetails;

  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

  String? _detailError;
  String? get detailError => _detailError;

  // Active orders state
  List<Order> _activeOrders = [];
  List<Order> get activeOrders => _activeOrders;

  bool _isPayingFee = false;
  bool get isPayingFee => _isPayingFee;

  // Filter state
  String? _statusFilter;
  String? get statusFilter => _statusFilter;

  String? _orderTypeFilter; // 'PERSONAL_RENTAL' or 'LOGISTICS' or null (All)
  String? get orderTypeFilter => _orderTypeFilter;

  String? _userIdFilter;
  String? get userIdFilter => _userIdFilter;

  String? _orderCodeFilter;
  String? get orderCodeFilter => _orderCodeFilter;

  String? _searchFilter;
  String? get searchFilter => _searchFilter;

  String? _orderByFilter = 'createdAt';
  String? get orderByFilter => _orderByFilter;

  String? _orderDirectionFilter = 'DESC';
  String? get orderDirectionFilter => _orderDirectionFilter;

  // ==================== Actions ====================

  /// Lấy danh sách orders (lần đầu)
  Future<void> fetchOrders({
    String? status,
    String? orderCode,
    String? userId,
    String? search,
    String? orderBy,
    String? orderDirection,
    String? orderType,
  }) async {
    _isLoading = true;
    _error = null;

    // Update filters
    _statusFilter = status;
    _orderCodeFilter = orderCode;
    _userIdFilter = userId;
    _searchFilter = search;
    _orderByFilter = orderBy ?? _orderByFilter;
    _orderDirectionFilter = orderDirection ?? _orderDirectionFilter;
    _orderTypeFilter = orderType ?? _orderTypeFilter;

    notifyListeners();

    final result = await _getMyOrdersUseCase(
      page: 1,
      limit: 10,
      status: status,
      orderCode: orderCode,
      userId: userId,
      search: search,
      orderBy: _orderByFilter,
      orderDirection: _orderDirectionFilter,
      orderType: _orderTypeFilter == 'ALL' ? null : _orderTypeFilter,
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _orders = [];
        _pagination = null;
      },
      (paginatedResult) {
        // Option to filter client-side if API doesn't support orderType yet,
        // but user expects it to be part of the unified fetch.
        // For now, assume API might handle it or we use status/orderType interchangeably if aligned.
        _orders = paginatedResult.items;
        _pagination = paginatedResult.pagination;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Load thêm orders (infinite scroll / load more)
  Future<void> fetchMoreOrders() async {
    if (_isLoadingMore || _pagination == null || !_pagination!.hasNextPage) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final result = await _getMyOrdersUseCase(
      page: _pagination!.page + 1,
      limit: _pagination!.limit,
      status: _statusFilter,
      orderCode: _orderCodeFilter,
      userId: _userIdFilter,
      search: _searchFilter,
      orderBy: _orderByFilter,
      orderDirection: _orderDirectionFilter,
      orderType: _orderTypeFilter == 'ALL' ? null : _orderTypeFilter,
    );

    result.fold(
      (failure) {
        // Silently fail for load-more
      },
      (paginatedResult) {
        _orders = [..._orders, ...paginatedResult.items];
        _pagination = paginatedResult.pagination;
      },
    );

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Lấy chi tiết order
  Future<void> fetchOrderDetail(String id) async {
    _isLoadingDetail = true;
    _detailError = null;
    _selectedOrder = null;
    _orderDetails = [];
    notifyListeners();

    final result = await _getOrderDetailUseCase(id);

    result.fold(
      (failure) {
        _detailError = failure.message;
      },
      (orderWithDetails) {
        _selectedOrder = orderWithDetails.order;
        _orderDetails = orderWithDetails.orderDetails;
      },
    );

    _isLoadingDetail = false;
    notifyListeners();
  }

  /// Lấy active orders
  Future<void> fetchActiveOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getActiveOrdersUseCase();

    result.fold(
      (failure) {
        _error = failure.message;
        _activeOrders = [];
      },
      (orders) {
        _activeOrders = orders;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Thanh toán nợ phí
  Future<bool> payOverdueFee(String orderId) async {
    _isPayingFee = true;
    _error = null;
    notifyListeners();

    final result = await _payOverdueFeeUseCase(orderId);

    bool isSuccess = false;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (amountPaid) {
        isSuccess = true;
      },
    );

    _isPayingFee = false;
    notifyListeners();

    if (isSuccess) {
      await fetchOrderDetail(orderId);
    }
    return isSuccess;
  }

  /// Tạo mới mã mở tủ kiosk
  Future<bool> recreateAccessCode(String orderDetailId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _recreateAccessCodeUseCase(orderDetailId);

    bool isSuccess = false;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (success) {
        isSuccess = success;
      },
    );

    _isLoading = false;
    notifyListeners();
    return isSuccess;
  }

  /// Refresh orders
  Future<void> refresh() async {
    await fetchOrders(
      status: _statusFilter,
      orderCode: _orderCodeFilter,
      userId: _userIdFilter,
      search: _searchFilter,
      orderBy: _orderByFilter,
      orderDirection: _orderDirectionFilter,
      orderType: _orderTypeFilter,
    );
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    _statusFilter = status;
    fetchOrders(status: status);
  }

  /// Clear error
  void clearError() {
    _error = null;
    _detailError = null;
    notifyListeners();
  }
}
