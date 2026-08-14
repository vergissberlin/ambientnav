import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/core/persistence/local_store.dart';
import 'package:ambientnav/core/theme/theme_controller.dart';
import 'package:ambientnav/features/controllers/data/mock/mock_controller_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Provider scope for use cases.
///
/// Deliberately mirrors `app/test/widget/pump_app.dart` so a use case and a
/// widget test exercise the same provider graph. `localStoreProvider` throws
/// `UnimplementedError` unless overridden, so this is mandatory for anything
/// touching theme or dev settings.
///
/// No MaterialApp and no localizations here — `Widgetbook.material` supplies
/// the app via its appBuilder, and `LocalizationAddon` injects the delegates.
class UseCaseScope extends StatelessWidget {
  const UseCaseScope({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  final Widget child;
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(InMemoryLocalStore()),
        ...overrides,
      ],
      child: child,
    );
  }
}

/// Provides a [MockControllerRepository] that is already connected and,
/// optionally, paired — then builds [child] inside a [UseCaseScope] overriding
/// `controllerRepositoryProvider`.
///
/// `connect` and `pair` are async, so a prepared repository cannot be built in
/// a synchronous use-case builder; hence the FutureBuilder. Mirrors the setup
/// in `app/test/widget/led_config_form_test.dart`.
class MockRepoScope extends StatefulWidget {
  const MockRepoScope({
    super.key,
    required this.child,
    this.deviceId = MockControllerRepository.frontId,
    this.paired = true,
  });

  final Widget child;
  final String deviceId;

  /// When false the config forms surface `NotPairedException` on save — the
  /// path that otherwise needs an unpaired physical controller to reach.
  final bool paired;

  @override
  State<MockRepoScope> createState() => _MockRepoScopeState();
}

class _MockRepoScopeState extends State<MockRepoScope> {
  late final MockControllerRepository _repo;
  late final Future<void> _ready;

  /// The passkey MockControllerRepository accepts.
  static const String _passkey = '123456';

  @override
  void initState() {
    super.initState();
    _repo = MockControllerRepository();
    _ready = _prepare();
  }

  Future<void> _prepare() async {
    await _repo.connect(widget.deviceId);
    if (widget.paired) await _repo.pair(widget.deviceId, _passkey);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return UseCaseScope(
          overrides: [controllerRepositoryProvider.overrideWithValue(_repo)],
          child: widget.child,
        );
      },
    );
  }
}
