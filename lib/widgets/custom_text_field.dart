import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool isRequired;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.onChanged,
    this.controller,
    this.validator,
    this.inputFormatters,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        validator:
            validator ??
            (isRequired
                ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bu alan zorunludur';
                  }
                  return null;
                }
                : null),
        decoration: InputDecoration(
          labelText: isRequired ? '$labelText *' : labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          hintText: hintText,
        ),
      ),
    );
  }
}
