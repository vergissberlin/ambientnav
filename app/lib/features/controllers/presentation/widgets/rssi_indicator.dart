import 'package:flutter/material.dart';

/// Four-bar signal strength indicator derived from a 0.0 … 1.0 quality value.
class RssiIndicator extends StatelessWidget {
  const RssiIndicator({super.key, required this.quality, this.rssi});

  final double quality;
  final int? rssi;

  @override
  Widget build(BuildContext context) {
    final activeBars = (quality * 4).ceil().clamp(0, 4);
    final color = quality > 0.5
        ? Colors.green
        : quality > 0.25
            ? Colors.orange
            : Colors.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 4,
              height: 5.0 + i * 4,
              decoration: BoxDecoration(
                color: i < activeBars
                    ? color
                    : Theme.of(context).disabledColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        if (rssi != null) ...[
          const SizedBox(width: 6),
          Text('$rssi dBm', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
