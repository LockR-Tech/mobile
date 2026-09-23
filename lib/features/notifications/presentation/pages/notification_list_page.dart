import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/unauthenticated_placeholder.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    TokenService.authState.addListener(_onAuthStateChanged);
    _scrollController.addListener(_onScroll);
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    if (TokenService.authState.value && mounted) {
      context.read<NotificationProvider>().loadNotifications(refresh: true);
    }
  }

  @override
  void dispose() {
    TokenService.authState.removeListener(_onAuthStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    context.read<NotificationProvider>().markAsRead(notification.id);

    final payload = notification.dataPayload;
    // Không có payload (hoặc payload không chỉ tới màn nào) thì trước đây bấm
    // vào thông báo không xảy ra gì cả. Mở sheet nội dung đầy đủ để người dùng
    // ít nhất đọc được thông báo.
    if (payload == null) {
      _showNotificationSheet(notification);
      return;
    }

    switch (payload.actionType) {
      // Noti đơn hàng + noti trạng thái giao hàng (drone) -> mở chi tiết đơn.
      case 'OPEN_ORDER_DETAIL':
      case 'ORDER_STATUS_CHANGED':
        if (payload.referenceId != null) {
          context.push(AppRouter.orderDetail, extra: payload.referenceId);
        } else {
          _showNotificationSheet(notification);
        }
        break;
      case 'OPEN_PROMOTION_TAB':
        context.push(AppRouter.promotions);
        break;
      default:
        // Phiếu/lịch của KTV tủ -> tab tương ứng trên trang KTV tủ.
        final technicianRoute = technicianRouteForNotification(
          payload.actionType,
        );
        if (technicianRoute != null) {
          context.go(technicianRoute);
        } else {
          _showNotificationSheet(notification);
        }
        break;
    }
  }

  /// Nội dung đầy đủ của thông báo khi không có màn nào để mở.
  void _showNotificationSheet(NotificationModel notification) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14171F).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getIconForType(notification.dataPayload?.actionType),
                      size: 21,
                      color: const Color(0xFF14171F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    notification.body,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                formatDateTimeVn(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TokenService.authState,
      builder: (context, isLoggedIn, child) {
        if (!isLoggedIn) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FAFC),
            body: Column(
              children: [
                BrandHeroHeader(
                  title: 'Thông báo',
                  subtitle: 'Cập nhật mới nhất từ Lock.R',
                  onBack: () => AppRouter.backOrHome(context),
                ),
                const Expanded(
                  child: UnauthenticatedPlaceholder(
                    message: 'Bạn cần đăng nhập để xem thông báo',
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFC),
          body: BrandHeroScaffold(
            header: (collapse) => BrandHeroHeader(
              title: 'Thông báo',
              subtitle: 'Cập nhật mới nhất từ Lock.R',
              onBack: () => AppRouter.backOrHome(context),
              collapseProgress: collapse,
              trailing: Consumer<NotificationProvider>(
                  builder: (context, provider, _) {
                    final showMarkAll = provider.unreadCount > 0 &&
                        provider.notifications.isNotEmpty;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showMarkAll) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => provider.markAllAsRead(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.checkCheck,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đọc tất cả',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        BrandCircleIconButton(
                          icon: LucideIcons.refreshCw,
                          onTap: () =>
                              provider.loadNotifications(refresh: true),
                        ),
                      ],
                    );
                  },
                ),
              ),
            child: Consumer<NotificationProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.notifications.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AislBrand.navy),
                      );
                    }

                    if (provider.error != null &&
                        provider.notifications.isEmpty) {
                      return _buildErrorState(provider);
                    }

                    if (provider.notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          provider.loadNotifications(refresh: true),
                      color: AislBrand.navy,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(top: 4),
                        itemCount: provider.notifications.length + 1,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          if (index == provider.notifications.length) {
                            if (provider.isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (!provider.hasMore &&
                                provider.notifications.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'Đã xem hết thông báo',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox(height: 32);
                          }

                          final notification = provider.notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellRing, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khi có thông báo mới, chúng sẽ xuất hiện ở đây',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(NotificationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.serverCrash, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Lỗi kết nối',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              provider.error!,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => provider.loadNotifications(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AislBrand.navy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final bool isUnread = !notification.isRead;
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        color: isUnread ? const Color(0xFFEFF6FF) : Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnread
                    ? AislBrand.navy.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.dataPayload?.actionType),
                color: isUnread ? AislBrand.navy : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15,
                            color: isUnread
                                ? Colors.black87
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: AislBrand.cyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread ? Colors.black87 : Colors.grey.shade600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String? actionType) {
    if (actionType == null) return LucideIcons.bell;
    switch (actionType) {
      case 'OPEN_ORDER_DETAIL':
        return LucideIcons.package;
      case 'ORDER_STATUS_CHANGED':
        return LucideIcons.truck; // trạng thái giao hàng (drone)
      case 'OPEN_PROMOTION_TAB':
        return LucideIcons.tag;
      default:
        return LucideIcons.bell;
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return '${time.day}/${time.month}/${time.year}';
  }
}
