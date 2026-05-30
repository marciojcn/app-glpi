import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glpi_theme.dart';

class GlpiTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final String? helperText;
  final String? hintText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;

  const GlpiTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.helperText,
    this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
        hintText: hintText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: GlpiTheme.glpiTextSecondary),
        suffixIcon: suffixIcon,
        counterText: maxLength == null ? null : '',
      ),
    );
  }
}

class GlpiPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  const GlpiPasswordField({
    super.key,
    this.controller,
    this.labelText = 'Senha',
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  State<GlpiPasswordField> createState() => _GlpiPasswordFieldState();
}

class _GlpiPasswordFieldState extends State<GlpiPasswordField> {
  bool _ocultar = true;

  @override
  Widget build(BuildContext context) {
    return GlpiTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      prefixIcon: Icons.lock_outline,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLines: 1,
      obscureText: _ocultar,
      suffixIcon: IconButton(
        icon: Icon(
          _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: GlpiTheme.glpiTextSecondary,
        ),
        onPressed: () {
          HapticFeedback.selectionClick();
          setState(() => _ocultar = !_ocultar);
        },
      ),
    );
  }
}

class GlpiSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String)? onSearch;
  final void Function(String)? onChanged;
  final VoidCallback? onScanner;

  const GlpiSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Buscar por nome, serial ou patrimônio…',
    this.onSearch,
    this.onChanged,
    this.onScanner,
  });

  @override
  Widget build(BuildContext context) {
    final campo = GlpiTextField(
      controller: controller,
      labelText: hint,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
      onSubmitted: onSearch,
      onChanged: onChanged,
    );

    if (onScanner == null) return campo;

    return Row(
      children: [
        Expanded(child: campo),
        const SizedBox(width: 8),
        Material(
          color: GlpiTheme.glpiPrimary,
          borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(GlpiTheme.borderRadius),
            onTap: () {
              HapticFeedback.lightImpact();
              onScanner!();
            },
            child: const Tooltip(
              message: 'Escanear QR code da etiqueta',
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
