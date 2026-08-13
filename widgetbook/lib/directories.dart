import 'package:widgetbook/widgetbook.dart';

import 'foundations/foundations.dart';
import 'use_cases/app_use_cases.dart';
import 'use_cases/atom_use_cases.dart';

/// The catalogue tree.
///
/// Hand-written rather than generated. widgetbook_generator derives the
/// navigation path from the file location of the annotated type, which would
/// scatter the app's screens under `features/…/presentation` and require a
/// `path:` override each; more importantly the annotations would have to live
/// in `app/lib`, making widgetbook_annotation a non-dev dependency of the
/// shipped app and re-coupling the catalogue to the package this one is
/// deliberately kept separate from.
///
/// Revisit if this grows past roughly 60 use cases, or if everything
/// catalogued ends up living under a `ui/` directory. Adopting codegen later
/// costs one CI step and an analyzer exclude — the choice is cheap to reverse.
///
/// Manual registration can drift; `test/use_cases_build_test.dart` is what
/// keeps that honest.
final List<WidgetbookNode> kDirectories = [
  ...foundationsFolder(),
  ...atomsFolder(),
  ...appFolder(),
];
