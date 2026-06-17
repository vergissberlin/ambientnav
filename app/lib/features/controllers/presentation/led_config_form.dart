import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/security/pairing_exception.dart';
import '../domain/entities/led_config.dart';

/// Auto-populates from the controller's current LED configuration on open,
/// lets the user edit LED count / brightness / effect, and writes it back.
class LedConfigForm extends ConsumerStatefulWidget {
  const LedConfigForm({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<LedConfigForm> createState() => _LedConfigFormState();
}

class _LedConfigFormState extends ConsumerState<LedConfigForm> {
  LedConfig? _config;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(controllerRepositoryProvider);
    final cfg = await repo.readLedConfig(widget.deviceId);
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
      await repo.writeLedConfig(widget.deviceId, _config!);
      setState(() => _message = l10n.save);
    } on NotPairedException {
      setState(() => _message = l10n.notPaired);
    }
  }

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
        Text(l10n.ledCount, style: Theme.of(context).textTheme.labelLarge),
        TextFormField(
          key: const Key('ledCountField'),
          initialValue: cfg.ledCount.toString(),
          keyboardType: TextInputType.number,
          onChanged: (v) => setState(() => _config =
              cfg.copyWith(ledCount: int.tryParse(v) ?? cfg.ledCount)),
        ),
        const SizedBox(height: 16),
        Text('${l10n.brightness}: ${cfg.brightness}'),
        Slider(
          key: const Key('brightnessSlider'),
          min: 0,
          max: 255,
          value: cfg.brightness.toDouble(),
          onChanged: (v) =>
              setState(() => _config = cfg.copyWith(brightness: v.round())),
        ),
        const SizedBox(height: 16),
        Text('${l10n.effect}: ${cfg.effect}'),
        Slider(
          min: 0,
          max: 10,
          divisions: 10,
          value: cfg.effect.toDouble().clamp(0, 10),
          onChanged: (v) =>
              setState(() => _config = cfg.copyWith(effect: v.round())),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('saveLedConfig'),
          onPressed: cfg.isValid ? _save : null,
          icon: const Icon(Icons.save),
          label: Text(l10n.save),
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
