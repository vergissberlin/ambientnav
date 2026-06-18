import 'package:flutter/material.dart';

/// Compact battery gauge showing voltage and an approximate state-of-charge.
///
/// Maps a single-cell Li-ion range (3.0 V empty … 4.2 V full) to a fill level.
class BatteryGauge extends StatelessWidget {
  const BatteryGauge({super.key, required this.voltage});

  /// Voltage in volts, or null when unknown.
  final double? voltage;

  double get _soc {
    final v = voltage;
    if (v == null) return 0;
    return ((v - 3.0) / (4.2 - 3.0)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final soc = _soc;
    final color = soc > 0.5
        ? Colors.green
        : soc > 0.2
            ? Colors.orange
            : Colors.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          soc > 0.66
              ? Icons.battery_full
              : soc > 0.33
                  ? Icons.battery_5_bar
                  : Icons.battery_2_bar,
          color: voltage == null ? Theme.of(context).disabledColor : color,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          voltage == null ? '—' : '${voltage!.toStringAsFixed(2)} V',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
