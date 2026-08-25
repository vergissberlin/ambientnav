import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';

import '../../features/controllers/presentation/controllers_list_screen.dart';
import '../../features/navigation/presentation/map_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// Bottom tab bar that collapses in landscape and expands again in portrait.
class ResponsiveHomeFooterBar extends StatefulWidget {
  const ResponsiveHomeFooterBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<ResponsiveHomeFooterBar> createState() =>
      _ResponsiveHomeFooterBarState();
}

class _ResponsiveHomeFooterBarState extends State<ResponsiveHomeFooterBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  Orientation? _lastOrientation;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    if (!_initialized) {
      _controller.value = landscape ? 0 : 1;
      _initialized = true;
      _lastOrientation = landscape
          ? Orientation.landscape
          : Orientation.portrait;
      return;
    }
    final currentOrientation = landscape
        ? Orientation.landscape
        : Orientation.portrait;
    if (_lastOrientation == currentOrientation) return;
    _lastOrientation = currentOrientation;
    if (landscape) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderColor = AnBrandTheme.of(context).line;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final visible = _controller.value;
        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: visible,
            child: Opacity(
              opacity: visible,
              child: IgnorePointer(ignoring: visible < 0.05, child: child),
            ),
          ),
        );
      },
      child: AnGlassBar(
        border: Border(top: BorderSide(color: borderColor)),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: widget.selectedIndex,
          onDestinationSelected: widget.onDestinationSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.navigation_outlined),
              selectedIcon: const Icon(Icons.navigation),
              label: l10n.navTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.memory_outlined),
              selectedIcon: const Icon(Icons.memory),
              label: l10n.controllersTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.settingsTab,
            ),
          ],
        ),
      ),
    );
  }
}

/// Root navigation shell with bottom tabs: Navigate / Controllers / Settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [MapScreen(), ControllersListScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: ResponsiveHomeFooterBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
