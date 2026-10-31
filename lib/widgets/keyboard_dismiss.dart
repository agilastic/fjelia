import 'package:flutter/widgets.dart';

/// Closes the keyboard when the user taps or starts scrolling outside a text
/// field, in every screen and sheet below it.
///
/// Flutter keeps the focus on phones by default and drops it only on desktop.
/// Taps on another text field, or on a widget wrapped in [TextFieldTapRegion]
/// (a send button), keep the keyboard open.
class DismissKeyboardOnTapOutside extends StatelessWidget {
  const DismissKeyboardOnTapOutside({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      EditableTextTapOutsideIntent:
          CallbackAction<EditableTextTapOutsideIntent>(
            onInvoke: (intent) {
              intent.focusNode.unfocus();
              return null;
            },
          ),
    },
    child: child,
  );
}
