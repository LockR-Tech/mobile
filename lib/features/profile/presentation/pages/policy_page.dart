import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class PolicyPage extends StatefulWidget {
  final String title;
  final String assetPath;

  const PolicyPage({super.key, required this.title, required this.assetPath});

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  late ScrollController _scrollController;
  late Future<String> _markdownFuture;
  bool _isAgreed = false;
  bool _isScrolledToBottom = false;
  bool _isScrolledToTop = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _markdownFuture = _loadMarkdownContent();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll - 50;
    final topThreshold = 50;

    // cuộn xuống dưới
    if (currentScroll >= threshold && !_isScrolledToBottom) {
      setState(() {
        _isScrolledToBottom = true;
      });
    } else if (currentScroll < threshold && _isScrolledToBottom) {
      setState(() {
        _isScrolledToBottom = false;
      });
    }

    // cuộn lên đầu
    if (currentScroll <= topThreshold && !_isScrolledToTop) {
      setState(() {
        _isScrolledToTop = true;
      });
    } else if (currentScroll > topThreshold && _isScrolledToTop) {
      setState(() {
        _isScrolledToTop = false;
      });
    }
  }

  void _handleBack() {
    context.go(AppRouter.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShadTheme.of(context).colorScheme.muted,
      body: FutureBuilder<String>(
        future: _markdownFuture,
        builder: (context, snapshot) {
          // loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                CustomSliverAppBar(
                  title: widget.title,
                  showBackButton: true,
                  onBackPressed: _handleBack,
                  backgroundColor: ShadTheme.of(context).colorScheme.muted,
                  foregroundColor: ShadTheme.of(context).colorScheme.foreground,
                ),
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }

          // error status
          if (snapshot.hasError) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                CustomSliverAppBar(
                  title: widget.title,
                  showBackButton: true,
                  onBackPressed: _handleBack,
                  backgroundColor: ShadTheme.of(context).colorScheme.muted,
                  foregroundColor: ShadTheme.of(context).colorScheme.foreground,
                ),
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: ShadTheme.of(
                              context,
                            ).colorScheme.destructive,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không thể tải nội dung',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ShadTheme.of(
                                context,
                              ).colorScheme.foreground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ShadTheme.of(
                                context,
                              ).colorScheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShadButton(
                            onPressed: () {
                              (context as Element).markNeedsBuild();
                            },
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // success status - hiện nội dung markdown
          final String markdownData = snapshot.data ?? '';

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              CustomSliverAppBar(
                title: widget.title,
                showBackButton: true,
                onBackPressed: _handleBack,
                backgroundColor: ShadTheme.of(context).colorScheme.muted,
                foregroundColor: ShadTheme.of(context).colorScheme.foreground,
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ShadTheme.of(context).colorScheme.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MarkdownBody(
                    data: markdownData,
                    styleSheet: MarkdownStyleSheet(
                      h1: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ShadTheme.of(context).colorScheme.foreground,
                        height: 1.4,
                      ),
                      h2: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ShadTheme.of(context).colorScheme.foreground,
                        height: 1.4,
                      ),
                      h3: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ShadTheme.of(context).colorScheme.foreground,
                        height: 1.4,
                      ),

                      p: TextStyle(
                        fontSize: 16,
                        color: ShadTheme.of(context).colorScheme.foreground,
                        height: 1.6,
                      ),

                      listBullet: TextStyle(
                        fontSize: 16,
                        color: ShadTheme.of(context).colorScheme.foreground,
                      ),

                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ShadTheme.of(context).colorScheme.foreground,
                      ),

                      em: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: ShadTheme.of(context).colorScheme.foreground,
                      ),

                      blockquote: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: ShadTheme.of(
                          context,
                        ).colorScheme.mutedForeground,
                      ),

                      code: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        backgroundColor: ShadTheme.of(
                          context,
                        ).colorScheme.muted,
                        color: ShadTheme.of(context).colorScheme.foreground,
                      ),

                      horizontalRuleDecoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: ShadTheme.of(context).colorScheme.border,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    selectable: true,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ShadTheme.of(context).colorScheme.card,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        onChanged: _isScrolledToBottom
                            ? (value) {
                                setState(() {
                                  _isAgreed = value ?? false;
                                });
                              }
                            : null,
                        activeColor: AISLShadcnTheme.navyPrimary,
                      ),
                      Expanded(
                        child: Text(
                          'Tôi đồng ý với điều khoản sử dụng',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isScrolledToBottom
                                ? ShadTheme.of(context).colorScheme.foreground
                                : ShadTheme.of(
                                    context,
                                  ).colorScheme.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // tải nội dung markdown từ assets
  Future<String> _loadMarkdownContent() async {
    try {
      return await rootBundle.loadString(widget.assetPath);
    } catch (e) {
      throw Exception('Không thể tải file: ${widget.assetPath}. Lỗi: $e');
    }
  }

  // nút lên đầu và xuống cuối
  Widget _buildFloatingActionButtons(BuildContext context) {
    final List<Widget> buttons = [];
    final bool showTopButton = !_isScrolledToTop;
    final bool showBottomButton = !_isScrolledToBottom;

    // tắt nút scroll to top khi đã ở trên cùng
    if (showTopButton) {
      buttons.add(
        FloatingActionButton.small(
          heroTag: 'scroll_to_top',
          onPressed: () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
          backgroundColor: AISLShadcnTheme.navyPrimary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.arrow_upward),
        ),
      );
    }

    // tắt nút scroll to bottom khi đã ở dưới cùng
    if (showBottomButton) {
      if (showTopButton) {
        buttons.add(const SizedBox(height: 12));
      }
      buttons.add(
        FloatingActionButton.small(
          heroTag: 'scroll_to_bottom',
          onPressed: () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
          backgroundColor: AISLShadcnTheme.navyPrimary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.arrow_downward),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  // nút "Xong" cố định ở dưới màn hình
  Widget _buildBottomNavigationBar(BuildContext context) {
    final bool isEnabled = _isAgreed && _isScrolledToBottom;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled
                ? () {
                    context.pop();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? AISLShadcnTheme.navyPrimary
                  : ShadTheme.of(context).colorScheme.muted,
              foregroundColor: isEnabled
                  ? Colors.white
                  : ShadTheme.of(context).colorScheme.mutedForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Xong',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
