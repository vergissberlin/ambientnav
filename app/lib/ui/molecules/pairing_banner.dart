import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Banner shown above a controller's tabs until the link is bonded.
///
/// A plain [StatelessWidget] rather than a `ConsumerWidget`: the only use of
/// `ref` was inside the button callback, which the caller now owns. The banner
/// also does not know about the pairing dialog — that stays a screen concern.
class PairingBanner extends StatelessWidget {
  const PairingBanner({super.key, required this.onPair});

  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      leading: const Icon(Icons.lock),
      content: Text(l10n.notPaired),
      actions: [TextButton(onPressed: onPair, child: Text(l10n.pair))],
    );
  }
}
