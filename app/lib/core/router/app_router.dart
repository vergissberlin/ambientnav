import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';

import '../../features/controllers/presentation/controllers_list_screen.dart';
import '../../features/navigation/presentation/map_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AnGlassBar(
        border: Border(top: BorderSide(color: AnBrandTheme.of(context).line)),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
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
