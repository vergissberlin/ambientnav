import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/security/pairing_service.dart';

/// Modal passkey-entry dialog. Returns true when pairing succeeds.
class PairingDialog extends ConsumerStatefulWidget {
  const PairingDialog({super.key, required this.deviceId});

  final String deviceId;

  static Future<bool> show(BuildContext context, String deviceId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => PairingDialog(deviceId: deviceId),
    );
    return result ?? false;
  }

  @override
  ConsumerState<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends ConsumerState<PairingDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final service = ref.read(pairingServiceProvider);
    final result = await service.pair(widget.deviceId, _controller.text);
    if (!mounted) return;
    switch (result) {
      case PairingResult.success:
        Navigator.of(context).pop(true);
      case PairingResult.wrongPasskey:
        setState(() {
          _busy = false;
          _error = l10n.wrongPasskey;
        });
      case PairingResult.invalidFormat:
      case PairingResult.error:
        setState(() {
          _busy = false;
          _error = l10n.enterPasskey;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.pairing),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.enterPasskey),
          const SizedBox(height: 12),
          TextField(
            key: const Key('passkeyField'),
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.passkey,
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('pairButton'),
          onPressed: _busy ? null : _submit,
          child: Text(l10n.pair),
        ),
      ],
    );
  }
}
