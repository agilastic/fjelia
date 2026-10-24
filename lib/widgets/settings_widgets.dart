import 'package:flutter/material.dart';

import 'app_widgets.dart';

/// Shared presentation for settings sheets, separate from dashboard cards.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.largeTitle = false,
  });
  final String title;
  final Widget child;
  final bool showBack, largeTitle;

  @override
  Widget build(BuildContext context) => SheetPage(
    title: title,
    showHeader: false,
    backgroundColor: const Color(0xFF111111),
    child: Column(
      children: [
        SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBack)
                  _NavigationButton(icon: Icons.chevron_left, label: 'Back')
                else
                  const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    largeTitle ? '' : title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const _NavigationButton(icon: Icons.close, label: 'Close'),
              ],
            ),
          ),
        ),
        if (largeTitle)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    ),
  );
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: () => Navigator.pop(context),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFF252527),
      foregroundColor: Colors.white,
      fixedSize: const Size(40, 40),
    ),
    icon: Icon(icon, size: 22),
  );
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.title,
    this.footer,
    this.dividerIndent = 16,
  });
  final List<Widget> children;
  final String? title, footer;
  final double dividerIndent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title!,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
        Material(
          color: const Color(0xFF242426),
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: ListTileTheme(
            data: ListTileThemeData(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 3,
              ),
              minTileHeight: 54,
              minLeadingWidth: 30,
              horizontalTitleGap: 12,
              titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: const Color(0xFFF2F2F7),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
              subtitleTextStyle: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(
                    color: muted,
                    fontSize: 13,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
              iconColor: muted,
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: .5,
                      indent: dividerIndent,
                      color: const Color(0xFF424245),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              footer!,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    ),
  );
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, this.color, {super.key});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: .26), const Color(0xFF161618)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .13), width: .7),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}
