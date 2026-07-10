import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/data/models/auth_response.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/node_provider.dart';

class NodeSelectionScreen extends ConsumerStatefulWidget {
  /// When true the user came from within the app (via AppBar tap), so we show
  /// a back button and don't treat this as a mandatory step.
  final bool canGoBack;

  const NodeSelectionScreen({super.key, this.canGoBack = false});

  @override
  ConsumerState<NodeSelectionScreen> createState() => _NodeSelectionScreenState();
}

class _NodeSelectionScreenState extends ConsumerState<NodeSelectionScreen>
    with SingleTickerProviderStateMixin {
  NodeModel? _selected;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    await ref.read(authProvider.notifier).selectNode(_selected!);
    if (mounted) {
      if (widget.canGoBack && context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(nodeListProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated background ────────────────────────────────────────
          _AnimatedBg(controller: _bgController, size: size),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────────────────
                _buildTopBar(context),

                // ── Header text ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Node', style: AppTextStyles.displayMedium),
                      const SizedBox(height: 6),
                      Text(
                        'Choose the warehouse or node you want to work with',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                // ── Node list ────────────────────────────────────────────
                Expanded(
                  child: nodesAsync.when(
                    skipLoadingOnReload: false,
                    skipLoadingOnRefresh: false,
                    loading: () => _buildLoading(),
                    error: (e, _) => _buildError(e),
                    data: (nodes) {
                      // Pre-select first node when data loads
                      if (_selected == null && nodes.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selected = nodes.first);
                        });
                      }
                      return _buildNodeList(nodes);
                    },
                  ),
                ),

                // ── Continue button ──────────────────────────────────────
                _buildContinueButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (widget.canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 18, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          // Logout (only on mandatory first-time selection; hide if canGoBack)
          if (!widget.canGoBack)
            TextButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded,
                  size: 16, color: AppColors.error),
              label: Text('Logout',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.error)),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Loading nodes…', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load nodes', style: AppTextStyles.headingMedium),
            const SizedBox(height: 8),
            Text(e.toString(),
                style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(nodeListProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeList(List<NodeModel> nodes) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: nodes.length,
      itemBuilder: (context, i) => _NodeCard(
        node: nodes[i],
        isSelected: _selected?.id == nodes[i].id,
        onTap: () => setState(() => _selected = nodes[i]),
      ),
    );
  }

  Widget _buildContinueButton() {
    final isLoading = ref.watch(authProvider).isLoading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: AnimatedOpacity(
          opacity: _selected != null ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _selected != null
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [AppColors.cardBorder, AppColors.cardBorder]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _selected != null
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _selected != null && !isLoading ? _confirm : null,
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.canGoBack ? 'Apply Node' : 'Continue',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Node Card ─────────────────────────────────────────────────────────────────
class _NodeCard extends StatelessWidget {
  final NodeModel node;
  final bool isSelected;
  final VoidCallback onTap;

  const _NodeCard({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Code badge / icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.primaryGradient
                    : const LinearGradient(
                        colors: [AppColors.cardElevated, AppColors.cardElevated]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  node.code,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(node.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        node.location,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Check indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.cardBorder, width: 1.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated background (reused from login) ───────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  final Size size;
  const _AnimatedBg({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        size: size,
        painter: _BgPainter(t: controller.value),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: AppColors.backgroundGradient.colors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    _orb(canvas,
        cx: size.width * 0.8 + 30 * math.cos(t * math.pi * 2),
        cy: size.height * 0.15 + 20 * math.sin(t * math.pi * 2),
        r: 200,
        color: AppColors.primary.withValues(alpha: 0.12));
    _orb(canvas,
        cx: size.width * 0.2 + 20 * math.sin(t * math.pi * 2),
        cy: size.height * 0.85 + 20 * math.cos(t * math.pi * 2),
        r: 180,
        color: AppColors.secondary.withValues(alpha: 0.12));

    final dots = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    const sp = 28.0;
    for (double x = 0; x < size.width; x += sp) {
      for (double y = 0; y < size.height; y += sp) {
        canvas.drawCircle(Offset(x, y), 1.2, dots);
      }
    }
  }

  void _orb(Canvas canvas,
      {required double cx,
      required double cy,
      required double r,
      required Color color}) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.20), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, p);
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.t != t;
}
