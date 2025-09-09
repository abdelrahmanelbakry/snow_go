import 'package:flutter/material.dart';
import '../models/service_type.dart';

class ServicePicker extends StatelessWidget {
  final ServiceType value;
  final ValueChanged<ServiceType> onChanged;
  const ServicePicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Use SegmentedButton if available; otherwise fall back to two toggles.
    return LayoutBuilder(
      builder: (_, __) {
        try {
          // This will throw on very old SDKs where SegmentedButton doesn't exist.
          return SegmentedButton<ServiceType>(
            segments: const [
              ButtonSegment(value: ServiceType.driveway, label: Text('Driveway'), icon: Text('🛻')),
              ButtonSegment(value: ServiceType.salting, label: Text('Salting'), icon: Text('🧂')),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (set) => onChanged(set.first),
          );
        } catch (_) {
          // Fallback style (still matches visual intent)
          return Row(
            children: ServiceType.values.map((s) {
              final selected = s == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Colors.black12),
                      backgroundColor: selected ? Theme.of(context).colorScheme.primary.withOpacity(.08) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => onChanged(s),
                    child: Text(
                      s == ServiceType.driveway ? '🛻 Driveway' : '🧂 Salting',
                      style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }
}
