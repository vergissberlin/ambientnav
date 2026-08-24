import 'dart:io';

import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Dart mirror in `lib/tokens/` against the CSS it is derived from.
///
/// The web design system is the source of truth; this fails the build when the
/// two drift rather than letting them quietly diverge, which is how the app
/// ended up on an amber palette the brand never had.
void main() {
  // flutter test runs with the package root as cwd.
  final tokensDir = Directory('../../design-system/tokens');

  late Map<String, String> colors;
  late Map<String, String> spacing;
  late Map<String, String> frame;

  setUpAll(() {
    expect(
      tokensDir.existsSync(),
      isTrue,
      reason: 'expected the design system at ${tokensDir.path}',
    );
    colors = _parse(File('${tokensDir.path}/colors.css'));
    spacing = _parse(File('${tokensDir.path}/spacing.css'));
    frame = _parse(File('${tokensDir.path}/frame.css'));
  });

  group('colors.css', () {
    void expectHex(String token, Color actual) {
      final css = colors[token];
      expect(css, isNotNull, reason: '--$token missing from colors.css');
      expect(
        _hex(actual),
        equalsIgnoringCase(css!.replaceAll('#', '')),
        reason: '--$token drifted',
      );
    }

    test('signal accents match', () {
      expectHex('amb-cyan', AnColors.cyan);
      expectHex('amb-cyan-soft', AnColors.cyanSoft);
      expectHex('amb-cyan-deep', AnColors.cyanDeep);
      expectHex('amb-violet', AnColors.violet);
      expectHex('amb-violet-soft', AnColors.violetSoft);
      expectHex('amb-magenta', AnColors.magenta);
      expectHex('amb-magenta-soft', AnColors.magentaSoft);
      expectHex('amb-magenta-deep', AnColors.magentaDeep);
    });

    test('surfaces and text levels match', () {
      expectHex('amb-cockpit', AnColors.cockpit);
      expectHex('amb-surface', AnColors.surface);
      expectHex('amb-surface-2', AnColors.surface2);
      expectHex('amb-surface-3', AnColors.surface3);
      expectHex('amb-text', AnColors.text);
      expectHex('amb-text-2', AnColors.text2);
      expectHex('amb-text-3', AnColors.text3);
      expectHex('amb-text-4', AnColors.text4);
      expectHex('amb-daylight', AnColors.daylight);
      expectHex('amb-ash', AnColors.ash);
      expectHex('amb-ink', AnColors.ink);
    });

    test('hairline alphas match', () {
      expect(_alpha(AnColors.line), closeTo(0.08, 0.005));
      expect(_alpha(AnColors.lineStrong), closeTo(0.14, 0.005));
      expect(colors['amb-line'], contains('.08'));
      expect(colors['amb-line-strong'], contains('.14'));
    });

    test('scanline alpha matches', () {
      expect(_alpha(AnColors.scanline), closeTo(0.035, 0.002));
      expect(colors['amb-scanline-color'], contains('.035'));
    });

    test('frame glow blur and alpha match', () {
      void expectGlow(String token, List<BoxShadow> shadow) {
        final css = colors[token];
        expect(css, isNotNull, reason: '--$token missing from colors.css');
        final blurMatch = RegExp(r'(\d+(?:\.\d+)?)px').firstMatch(css!);
        expect(blurMatch, isNotNull, reason: '--$token missing a blur radius');
        expect(
          double.parse(blurMatch!.group(1)!),
          shadow.single.blurRadius,
          reason: '--$token blur drifted',
        );
        final alphaMatch = RegExp(r',\s*([\d.]+)\s*\)').firstMatch(css);
        expect(alphaMatch, isNotNull, reason: '--$token missing an alpha');
        expect(
          _alpha(shadow.single.color),
          closeTo(double.parse(alphaMatch!.group(1)!), 0.005),
          reason: '--$token alpha drifted',
        );
      }

      expectGlow('amb-glow-frame-cyan', AnShadows.glowFrameCyan);
      expectGlow('amb-glow-frame-magenta', AnShadows.glowFrameMagenta);
    });

    test('the MapLibre hex strings match the Color tokens', () {
      expect(
        AnColors.cyanHex.substring(1),
        equalsIgnoringCase(_hex(AnColors.cyan)),
      );
      expect(
        AnColors.violetHex.substring(1),
        equalsIgnoringCase(_hex(AnColors.violet)),
      );
      expect(
        AnColors.magentaHex.substring(1),
        equalsIgnoringCase(_hex(AnColors.magenta)),
      );
    });

    test('the brand gradient runs cyan -> violet -> magenta', () {
      expect(AnColors.gradient.colors, [
        AnColors.cyan,
        AnColors.violet,
        AnColors.magenta,
      ]);
      expect(AnColors.gradientH.colors, AnColors.gradient.colors);
    });
  });

  group('spacing.css', () {
    test('the 4px grid matches', () {
      for (var i = 0; i < AnSpace.scale.length; i++) {
        expect(
          spacing['space-${i + 1}'],
          '${AnSpace.scale[i].toInt()}px',
          reason: '--space-${i + 1} drifted',
        );
      }
    });

    test('the radius scale matches', () {
      const expected = {
        'radius-xs': AnRadius.xs,
        'radius-sm': AnRadius.sm,
        'radius-md': AnRadius.md,
        'radius-lg': AnRadius.lg,
        'radius-xl': AnRadius.xl,
        'radius-strip': AnRadius.strip,
        'radius-frame': AnFrame.radius,
      };
      expected.forEach((token, value) {
        expect(
          spacing[token],
          '${value.toInt()}px',
          reason: '--$token drifted',
        );
      });
    });

    test('the motion durations match', () {
      expect(spacing['dur-fast'], '${AnMotion.fast.inMilliseconds}ms');
      expect(spacing['dur-base'], '${AnMotion.base.inMilliseconds}ms');
      expect(spacing['dur-slow'], '${AnMotion.slow.inMilliseconds}ms');
    });

    test('the easing curve matches', () {
      final css = spacing['ease-glow'];
      expect(css, isNotNull);
      final nums = RegExp(
        r'-?[\d.]+',
      ).allMatches(css!).map((m) => double.parse(m.group(0)!)).toList();
      expect(nums, hasLength(4));
      final curve = AnMotion.easeGlow as Cubic;
      expect(nums[0], closeTo(curve.a, 0.001));
      expect(nums[1], closeTo(curve.b, 0.001));
      expect(nums[2], closeTo(curve.c, 0.001));
      expect(nums[3], closeTo(curve.d, 0.001));
    });
  });

  group('frame.css', () {
    test('geometry constants match', () {
      expect(frame['amb-frame-thickness'], '${AnFrame.thickness.toInt()}px');
      expect(frame['amb-glitch-offset'], '${AnFrame.glitchOffset.toInt()}px');
    });

    test('opacity constants match', () {
      expect(
        double.parse(frame['amb-frame-opacity-rest']!),
        closeTo(AnFrame.opacityRest, 0.001),
      );
      expect(
        double.parse(frame['amb-frame-opacity-active']!),
        closeTo(AnFrame.opacityActive, 0.001),
      );
    });
  });
}

/// Extract `--name: value;` pairs, ignoring `var(...)` aliases and comments.
Map<String, String> _parse(File file) {
  expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
  final source = file.readAsStringSync().replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  final out = <String, String>{};
  for (final m in RegExp(r'--([\w-]+)\s*:\s*([^;]+);').allMatches(source)) {
    final value = m.group(2)!.trim();
    if (value.startsWith('var(')) continue;
    out[m.group(1)!] = value;
  }
  return out;
}

String _hex(Color c) {
  int ch(double v) => (v * 255).round();
  return '${ch(c.r).toRadixString(16).padLeft(2, '0')}'
          '${ch(c.g).toRadixString(16).padLeft(2, '0')}'
          '${ch(c.b).toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

double _alpha(Color c) => c.a;
