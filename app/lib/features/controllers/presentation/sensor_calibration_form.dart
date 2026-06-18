import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/security/pairing_exception.dart';
import '../domain/entities/sensor_config.dart';

/// Lets the user pick the active sensor and calibrate the distance offset, then
/// writes the config back to the rear controller.
class SensorCalibrationForm extends ConsumerStatefulWidget {
  const SensorCalibrationForm({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<SensorCalibrationForm> createState() =>
      _SensorCalibrationFormState();
}

class _SensorCalibrationFormState extends ConsumerState<SensorCalibrationForm> {
  SensorConfig? _config;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(controllerRepositoryProvider);
    final cfg = await repo.readSensorConfig(widget.deviceId);
    if (!mounted) return;
    setState(() {
      _config = cfg;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final repo = ref.read(controllerRepositoryProvider);
    final l10n = AppLocalizations.of(context);
    try {
      await repo.writeSensorConfig(widget.deviceId, _config!);
      setState(() => _message = l10n.save);
    } on NotPairedException {
      setState(() => _message = l10n.notPaired);
    }
  }

  String _sensorLabel(AppLocalizations l10n, SensorType t) => switch (t) {
        SensorType.left => l10n.sensorLeft,
        SensorType.center => l10n.sensorCenter,
        SensorType.right => l10n.sensorRight,
        SensorType.fused => l10n.sensorFused,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading || _config == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final cfg = _config!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.activeSensor, style: Theme.of(context).textTheme.labelLarge),
        DropdownButton<SensorType>(
          key: const Key('sensorDropdown'),
          value: cfg.activeSensor,
          isExpanded: true,
          items: [
            for (final t in SensorType.values)
              DropdownMenuItem(value: t, child: Text(_sensorLabel(l10n, t))),
          ],
          onChanged: (t) => setState(() =>
              _config = cfg.copyWith(activeSensor: t ?? cfg.activeSensor)),
        ),
        const SizedBox(height: 16),
        Text('${l10n.calibration}: ${cfg.calibrationOffsetCm} cm'),
        Slider(
          key: const Key('calibrationSlider'),
          min: -50,
          max: 50,
          divisions: 100,
          value: cfg.calibrationOffsetCm.toDouble().clamp(-50, 50),
          onChanged: (v) => setState(
              () => _config = cfg.copyWith(calibrationOffsetCm: v.round())),
        ),
        const SizedBox(height: 16),
        Text('${l10n.maxRange}: ${cfg.maxRangeCm} cm'),
        Slider(
          min: 50,
          max: 500,
          divisions: 45,
          value: cfg.maxRangeCm.toDouble().clamp(50, 500),
          onChanged: (v) =>
              setState(() => _config = cfg.copyWith(maxRangeCm: v.round())),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('saveSensorConfig'),
          onPressed: cfg.isValid ? _save : null,
          icon: const Icon(Icons.tune),
          label: Text(l10n.calibrate),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message!),
          ),
      ],
    );
  }
}
