import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Primary gradient button used throughout the app.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isDestructive;
  final IconData? icon;
  final double? width;
  final double height;
  final Gradient? gradient;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isDestructive = false,
    this.icon,
    this.width,
    this.height = 52,
    this.gradient,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) _controller.reverse();
  }

  void _onTapUp(TapUpDetails _) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null && !widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double? buttonWidth = widget.width ??
                (constraints.maxWidth == double.infinity ? null : double.infinity);
            return SizedBox(
              width: buttonWidth,
              height: widget.height,
              child: widget.isOutlined
                  ? _buildOutlined(isDisabled)
                  : _buildFilled(isDisabled),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilled(bool isDisabled) {
    final gradient = widget.isDestructive
        ? const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          )
        : (widget.gradient ?? AppColors.primaryGradient);

    return AnimatedOpacity(
      opacity: isDisabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: _buildContent(Colors.white),
      ),
    );
  }

  Widget _buildOutlined(bool isDisabled) {
    final color =
        widget.isDestructive ? AppColors.error : AppColors.primary;
    return AnimatedOpacity(
      opacity: isDisabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _buildContent(color),
      ),
    );
  }

  Widget _buildContent(Color contentColor) {
    return Center(
      child: widget.isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(contentColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: contentColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
