import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_injection.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class MyDelegationsPage extends StatelessWidget {
  const MyDelegationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DelegationInjection.provideDelegationProvider(ApiClient())
            ..fetchMyDelegations(),
      child: const _MyDelegationsView(),
    );
  }
}

class _MyDelegationsView extends StatelessWidget {
  const _MyDelegationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<DelegationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text(
                    'Đơn ủy quyền',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  centerTitle: true,
                  pinned: true,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.black87,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }

          final delegations = provider.myDelegations
              .where((d) => d.isActive && d.usedAt == null)
              .toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
                  'Đơn ủy quyền',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                centerTitle: true,
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    color: Colors.black87,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              if (delegations.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.packageOpen,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có đơn ủy quyền nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final delegation = delegations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.package,
                              color: Colors.blue,
                            ),
                          ),
                          title: const Text(
                            'Ủy quyền từ người khác',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Mã OTP: ${delegation.accessCode ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (delegation.orderDetail?.lockerLabel !=
                                  null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Tủ: ${delegation.orderDetail!.formattedLockerLabel}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              context.push(
                                AppRouter.authorizedOpening,
                                extra: {
                                  'orderId': delegation.orderId,
                                  'lockerId': delegation.orderDetail?.lockerId,
                                  'accessCode': delegation.accessCode,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Mở tủ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            context.push(
                              AppRouter.authorizedOpening,
                              extra: {
                                'orderId': delegation.orderId,
                                'lockerId': delegation.orderDetail?.lockerId,
                                'accessCode': delegation.accessCode,
                              },
                            );
                          },
                        ),
                      );
                    }, childCount: delegations.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
