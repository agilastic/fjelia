import 'package:flutter/material.dart';

/// Text-field decoration shared by the connect screens.
InputDecoration onboardingInputDecoration(
  String hint, {
  Color accent = const Color(0xFF00D4A0),
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF888888)),
    filled: true,
    fillColor: const Color(0xFF1E1E1E),
    contentPadding: const EdgeInsets.all(16),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: border(const Color(0xFF333333), 1),
    focusedBorder: border(accent, 1.5),
    errorBorder: border(const Color(0xFFFF4444), 1),
    focusedErrorBorder: border(const Color(0xFFFF4444), 1.5),
  );
}

class OnboardingInfoBox extends StatelessWidget {
  const OnboardingInfoBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF888888)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingErrorBanner extends StatelessWidget {
  const OnboardingErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4444).withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4444).withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFFF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFF4444), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingInputLabel extends StatelessWidget {
  const OnboardingInputLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// Icon tile, title and subtitle at the top of each connect screen.
class OnboardingDeviceHeader extends StatelessWidget {
  const OnboardingDeviceHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 20),
        Text(title, style: theme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.bodyMedium),
      ],
    );
  }
}

/// Row of pills; the current step is wide and green.
class OnboardingStepIndicator extends StatelessWidget {
  const OnboardingStepIndicator({
    super.key,
    required this.current,
    this.total = 3,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF00D4A0) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
