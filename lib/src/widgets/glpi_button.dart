import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glpi_theme.dart';

class _PressFeedback extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _PressFeedback({required this.child, this.enabled = true});

  @override
  State<_PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<_PressFeedback> {
  bool _pressed = false;

  void _set(bool v) {
    if (!widget.enabled || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class GlpiButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool loading;
  final Color? backgroundColor;
  final double height;
  final VoidCallback? onPressed;

  const GlpiButton({
    super.key,
    required this.label,
    this.icon,
    this.loading = false,
    this.backgroundColor,
    this.height = GlpiTheme.buttonHeight,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final desabilitado = loading || onPressed == null;

    return _PressFeedback(
      enabled: !desabilitado,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: desabilitado
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed?.call();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? GlpiTheme.glpiPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                (backgroundColor ?? GlpiTheme.glpiPrimary).withAlpha(120),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
            ),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }
}

class GlpiOutlinedButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final double height;
  final VoidCallback? onPressed;

  const GlpiOutlinedButton({
    super.key,
    required this.label,
    this.icon,
    this.foregroundColor,
    this.height = GlpiTheme.buttonHeight,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cor = foregroundColor ?? GlpiTheme.glpiPrimary;

    return _PressFeedback(
      enabled: onPressed != null,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: cor,
            side: BorderSide(color: cor, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
            ),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class GlpiDestructiveButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double height;
  final VoidCallback? onPressed;

  const GlpiDestructiveButton({
    super.key,
    required this.label,
    this.icon,
    this.height = GlpiTheme.buttonHeight,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlpiOutlinedButton(
      label: label,
      icon: icon,
      height: height,
      foregroundColor: GlpiTheme.glpiError,
      onPressed: onPressed,
    );
  }
}

class GlpiTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onPressed;

  const GlpiTextButton({
    super.key,
    required this.label,
    this.icon,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _PressFeedback(
      enabled: onPressed != null,
      child: TextButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        style: TextButton.styleFrom(
          foregroundColor: color ?? GlpiTheme.glpiPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
