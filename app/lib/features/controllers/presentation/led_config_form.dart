import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
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
    return AnPanel(
      accent: AnPanelAccent.staticAccent,
      // The ListView below already carries its own EdgeInsets.all(16), and
      // AnPanel's 28px default would stack on top of that — see the same
      // padding-doubling note in controller_detail_screen.dart. Zeroing it
      // here keeps the visible inset unchanged.
      padding: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.ledCount, style: Theme.of(context).textTheme.labelLarge),
          TextFormField(
            key: const Key('ledCountField'),
            initialValue: cfg.ledCount.toString(),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(
              () => _config = cfg.copyWith(
                ledCount: int.tryParse(v) ?? cfg.ledCount,
              ),
            ),
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
          const SizedBox(height: 12),
          // Live brightness preview only. `effect` is deliberately NOT mapped
          // onto AnLightStripMode: there is no source-of-truth mapping between
          // the firmware's numeric effect byte (led_effects.cpp) and this
          // Dart-only brand specimen, and AnLightStrip's own doc comment warns
          // that it "is not driven by real effect state" so it doesn't become
          // a third artifact bound by the firmware<->docs parity invariant in
          // CLAUDE.md. The raw id is surfaced as a plain badge instead.
          Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: (cfg.brightness / 255).clamp(0.0, 1.0),
                  child: const AnLightStrip(mode: AnLightStripMode.ambient),
                ),
              ),
              const SizedBox(width: 12),
              AnBadge(label: 'EFFECT ${cfg.effect}', tone: AnBadgeTone.neutral),
            ],
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
      ),
    );
  }
}
