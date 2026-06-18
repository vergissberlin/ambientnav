import 'dart:async';

import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/geocoding_service.dart';

/// Destination search sheet. Returns the chosen [GeoResult] via the navigator.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static Future<GeoResult?> show(BuildContext context) {
    return showModalBottomSheet<GeoResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SearchScreen(),
    );
  }

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<GeoResult> _results = const [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await ref.read(geocodingServiceProvider).search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'search-failed');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('searchField'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l10n.searchDestination,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
            ),
            onChanged: _onChanged,
            onSubmitted: _search,
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final r = _results[i];
                return ListTile(
                  key: ValueKey('result_$i'),
                  leading: const Icon(Icons.place_outlined),
                  title: Text(r.label,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.of(context).pop(r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
