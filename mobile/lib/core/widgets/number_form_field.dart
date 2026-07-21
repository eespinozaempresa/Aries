import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TextFormField para valores numéricos: selecciona todo el contenido al
/// recibir foco (para reemplazar rápidamente el valor existente) y
/// restringe la entrada a dígitos y el separador decimal '.'.
class NumberFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final InputDecoration? decoration;
  final bool enabled;
  final bool autofocus;
  final bool allowDecimal;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;

  const NumberFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.decoration,
    this.enabled = true,
    this.autofocus = false,
    this.allowDecimal = true,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
    this.validator,
    this.onChanged,
  });

  @override
  State<NumberFormField> createState() => _NumberFormFieldState();
}

class _NumberFormFieldState extends State<NumberFormField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController(text: widget.initialValue);
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      decoration: widget.decoration,
      maxLength: widget.maxLength,
      textAlign: widget.textAlign,
      style: widget.style,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(widget.allowDecimal ? r'[0-9.]' : r'[0-9]'),
        ),
      ],
      validator: widget.validator,
      onChanged: widget.onChanged,
    );
  }
}
