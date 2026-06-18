import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/security/pairing_exception.dart';
import '../domain/entities/ota_update.dart';

/// Firmware OTA update: pick a `.bin` file and stream it to the controller,
/// showing transfer progress. Only available on a paired (bonded) link.
class OtaScreen extends ConsumerStatefulWidget {
  const OtaScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<OtaScreen> createState() => _OtaScreenState();
}

class _OtaScreenState extends ConsumerState<OtaScreen> {
  OtaProgress _progress = const OtaProgress.idle();
  String? _fileName;
  List<int>? _firmware;
  StreamSubscription<OtaProgress>? _sub;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['bin'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    setState(() {
      _fileName = file.name;
      _firmware = file.bytes;
    });
  }

  Future<void> _install() async {
    final firmware = _firmware;
    if (firmware == null) return;
    final repo = ref.read(controllerRepositoryProvider);
    await _sub?.cancel();
    _sub = repo.startOta(widget.deviceId, firmware).listen(
          (p) => setState(() => _progress = p),
          onError: (Object e) => setState(() {
            _progress = OtaProgress(
              state: OtaState.failed,
              bytesSent: _progress.bytesSent,
              totalBytes: _progress.totalBytes,
              error: e is NotPairedException ? 'not paired' : e.toString(),
            );
          }),
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _statusLabel(AppLocalizations l10n) => switch (_progress.state) {
        OtaState.idle => '',
        OtaState.transferring ||
        OtaState.verifying ||
        OtaState.applying =>
          l10n.updating,
        OtaState.done => l10n.updateDone,
        OtaState.failed => l10n.updateFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = _progress.state == OtaState.transferring ||
        _progress.state == OtaState.verifying ||
        _progress.state == OtaState.applying;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          key: const Key('pickFirmware'),
          onPressed: active ? null : _pick,
          icon: const Icon(Icons.folder_open),
          label: Text(_fileName ?? l10n.selectFirmware),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('installFirmware'),
          onPressed: (_firmware != null && !active) ? _install : null,
          icon: const Icon(Icons.system_update),
          label: Text(l10n.installUpdate),
        ),
        const SizedBox(height: 24),
        if (_progress.state != OtaState.idle) ...[
          LinearProgressIndicator(value: _progress.fraction),
          const SizedBox(height: 8),
          Text('${_statusLabel(l10n)} '
              '(${(_progress.fraction * 100).toStringAsFixed(0)}%)'),
          if (_progress.error != null)
            Text(_progress.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }
}
