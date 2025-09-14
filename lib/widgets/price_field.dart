import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PriceField extends StatelessWidget {
  final TextEditingController controller;

  const PriceField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: const InputDecoration(
        labelText: 'Price',
        prefixText: 'CA\$ ',
        hintText: '0.00',
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter a price';
        final parsed = double.tryParse(v);
        if (parsed == null) return 'Invalid number';
        if (parsed < 0) return 'Must be ≥ 0';
        return null;
      },
    );
  }
}
