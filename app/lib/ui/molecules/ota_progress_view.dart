import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../features/controllers/domain/entities/ota_update.dart';

/// Progress bar and status line for a firmware transfer. Renders nothing while
/// idle.
///
/// A pure function of [OtaProgress], which is the point: all six [OtaState]s
/// and the error case become reachable without touching `FilePicker`. Before
/// this was extracted they could only be seen by unplugging a real controller
/// mid-update.
class OtaProgressView extends StatelessWidget {
  const OtaProgressView({super.key, required this.progress});

  final OtaProgress progress;

  String _statusLabel(AppLocalizations l10n) => switch (progress.state) {
    OtaState.idle => '',
    OtaState.transferring ||
    OtaState.verifying ||
    OtaState.applying => l10n.updating,
    OtaState.done => l10n.updateDone,
    OtaState.failed => l10n.updateFailed,
  };

  @override
  Widget build(BuildContext context) {
    if (progress.state == OtaState.idle) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      // Reproduces the full-width children the enclosing ListView gave these
      // widgets before they were extracted.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: 8),
        Text(
          '${_statusLabel(l10n)} '
          '(${(progress.fraction * 100).toStringAsFixed(0)}%)',
        ),
        if (progress.error != null)
          Text(
            progress.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
