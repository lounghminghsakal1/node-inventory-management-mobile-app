import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'password123');

  late AnimationController _bgController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          username: _usernameCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!success && mounted) {
      final error = ref.read(authProvider).error ?? 'Login failed';
      _showError(error);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary))),
          ],
        ),
        backgroundColor: AppColors.cardElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated background ──────────────────────────────────────────
          _AnimatedBackground(controller: _bgController, size: size),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo + brand
                        _buildLogo(),
                        const SizedBox(height: 40),

                        // Login card
                        _buildLoginCard(authState),

                        const SizedBox(height: 24),
                        Text(
                          'NodeOps v1.0.0  •  Secure Login',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.warehouse_rounded, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 18),
        Text('NodeOps', style: AppTextStyles.displayMedium),
        const SizedBox(height: 6),
        Text(
          'Inventory Management System',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthState authState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back', style: AppTextStyles.headingXL),
            const SizedBox(height: 4),
            Text(
              'Sign in to continue',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 28),

            // Username
            AppTextField(
              label: 'Username',
              hint: 'Enter username',
              controller: _usernameCtrl,
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),

            // Password
            AppTextField(
              label: 'Password',
              hint: 'Enter password',
              controller: _passwordCtrl,
              obscureText: true,
              showToggle: true,
              prefixIcon: Icons.lock_outline_rounded,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Password is required' : null,
            ),
            const SizedBox(height: 24),

            // Login button
            AppButton(
              label: 'Sign In',
              icon: Icons.arrow_forward_rounded,
              isLoading: authState.isLoading,
              onPressed: _handleLogin,
            ),

            const SizedBox(height: 20),

            // Hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo: admin / password123',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated background ───────────────────────────────────────────────────────
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _AnimatedBackground({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _BgPainter(progress: controller.value),
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  final double progress;
  _BgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF080B18), Color(0xFF0C1228)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Glowing orbs
    _drawOrb(canvas, size,
        cx: size.width * 0.15 + 40 * math.sin(progress * math.pi * 2),
        cy: size.height * 0.2 + 20 * math.cos(progress * math.pi * 2),
        radius: 180,
        color: const Color(0xFF5B8AF6));

    _drawOrb(canvas, size,
        cx: size.width * 0.85 + 30 * math.cos(progress * math.pi * 2),
        cy: size.height * 0.75 + 30 * math.sin(progress * math.pi * 2),
        radius: 200,
        color: const Color(0xFFA855F7));

    _drawOrb(canvas, size,
        cx: size.width * 0.5,
        cy: size.height * 0.5 + 20 * math.sin(progress * math.pi),
        radius: 120,
        color: const Color(0xFF00D4FF));

    // Dot grid pattern
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _drawOrb(Canvas canvas, Size size,
      {required double cx,
      required double cy,
      required double radius,
      required Color color}) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.25), Colors.transparent],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.progress != progress;
}
