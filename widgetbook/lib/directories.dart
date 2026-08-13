import 'package:widgetbook/widgetbook.dart';

import 'foundations/foundations.dart';
import 'use_cases/app_use_cases.dart';
import 'use_cases/atom_use_cases.dart';
import 'use_cases/molecule_use_cases.dart';
import 'use_cases/screen_use_cases.dart';

/// The catalogue tree.
///
/// Grouped by **atomic tier, not by package**: the brand primitives from
/// `ambientnav_ui` and the app's own domain widgets sit side by side under
/// Atoms, because that is how someone looking for a component thinks about it.
/// There is no Templates or Pages tier — the one candidate for Templates
/// (`HomeShell`) is a fixed three-tab IndexedStack with no content slots, and
/// Pages in the original model are exactly what `features/**/presentation/`
/// already is.
///
/// Hand-written rather than generated. widgetbook_generator derives the
/// navigation path from the file location of the annotated type, and the
/// annotations would have to live in `app/lib` — making widgetbook_annotation a
/// non-dev dependency of the shipped app and re-coupling the catalogue to the
/// package this one is deliberately kept separate from.
///
/// Revisit if this grows past roughly 60 use cases. Adopting codegen later
/// costs one CI step and an analyzer exclude — the choice is cheap to reverse.
///
/// Manual registration can drift; `test/use_cases_build_test.dart` is what
/// keeps that honest.
final List<WidgetbookNode> kDirectories = [
  ...foundationsFolder(),
  WidgetbookFolder(name: 'Atoms', children: [...brandAtoms(), ...appAtoms()]),
  WidgetbookFolder(
    name: 'Molecules',
    children: [...extractedMolecules(), ...appMolecules()],
  ),
  WidgetbookFolder(
    name: 'Organisms',
    children: [...extractedOrganisms(), ...providerBoundOrganisms()],
  ),
  WidgetbookFolder(name: 'Screens', children: screens()),
];
