import 'package:flutter/material.dart';

/// The app's two looks: DarkFjelia (the default) and LightFjelia.
enum FjeliaStyle { dark, light }

/// Which look is showing. Colours across the app read it when they paint,
/// so the app switches without passing a theme to every widget; [FjeliaApp]
/// rebuilds everything when it changes.
abstract final class Fjelia {
  static FjeliaStyle style = FjeliaStyle.dark;
  static bool get light => style == FjeliaStyle.light;
}

/// One colour per look. DarkFjelia keeps the exact values the app always
/// had; LightFjelia has its own.
Color duo(int dark, int light) => Color(Fjelia.light ? light : dark);

/// Text and lines that are white on DarkFjelia and near black on
/// LightFjelia, with the same transparency.
const _ink = Color(0xFF15171A);
Color _inkA(Color white) =>
    Fjelia.light ? _ink.withAlpha((white.a * 255).round()) : white;

Color get fjInk => Fjelia.light ? _ink : Colors.white;
Color get fjInk70 => _inkA(Colors.white70);
Color get fjInk60 => _inkA(Colors.white60);
Color get fjInk54 => _inkA(Colors.white54);
Color get fjInk38 => _inkA(Colors.white38);
Color get fjInk30 => _inkA(Colors.white30);
Color get fjInk24 => _inkA(Colors.white24);
Color get fjInk12 => _inkA(Colors.white12);
Color get fjInk10 => _inkA(Colors.white10);

/// The page behind everything and the panels on it.
Color get fjBackground => duo(0xFF111111, 0xFFF2F4F7);
Color get fjPanel => duo(0xFF202020, 0xFFFFFFFF);
Color get fjMuted => duo(0xFF999999, 0xFF6B7280);

/// Sets the look from the theme above it and, when it changes, rebuilds
/// every widget below, constant ones included, so all colours follow.
class FjeliaStyleScope extends StatefulWidget {
  const FjeliaStyleScope({super.key, required this.child});
  final Widget child;

  @override
  State<FjeliaStyleScope> createState() => _FjeliaStyleScopeState();
}

class _FjeliaStyleScopeState extends State<FjeliaStyleScope> {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).brightness == Brightness.light
        ? FjeliaStyle.light
        : FjeliaStyle.dark;
    if (style != Fjelia.style) {
      Fjelia.style = style;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        void mark(Element e) {
          e.markNeedsBuild();
          e.visitChildren(mark);
        }

        context.visitChildElements(mark);
      });
    }
    return widget.child;
  }
}

/// An accent colour as text or line: as is on DarkFjelia, deepened on
/// LightFjelia so pale tones (lime, yellow, cyan) stay readable on white.
Color fjAccent(Color c) {
  if (!Fjelia.light) return c;
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness * .72).clamp(0, .42))
      .withSaturation((hsl.saturation * 1.05).clamp(0, 1))
      .toColor();
}

/// The soft light from the top left of an accented card.
BoxDecoration fjGlow(
  List<Color> accent, {
  double radius = 1.6,
  double strength = 1,
}) => BoxDecoration(
  gradient: RadialGradient(
    center: Alignment.topLeft,
    radius: radius,
    colors: [
      accent.first.withValues(alpha: (Fjelia.light ? .10 : .13) * strength),
      accent.last.withValues(alpha: .03 * strength),
      Colors.transparent,
    ],
    stops: const [0, .45, 1],
  ),
);

/// The tinted edge of an accented card.
BorderSide fjEdge(List<Color> accent) =>
    BorderSide(color: accent.first.withValues(alpha: Fjelia.light ? .35 : .28));

/// A card or section title in its accent gradient.
class GradientTitle extends StatelessWidget {
  const GradientTitle(
    this.text, {
    super.key,
    required this.colors,
    this.size = 10.5,
  });
  final String text;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: LinearGradient(
      colors: [for (final c in colors) fjAccent(c)],
    ).createShader,
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: size,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
