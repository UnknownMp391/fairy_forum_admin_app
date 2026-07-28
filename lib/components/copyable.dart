import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableWidget extends StatelessWidget {
  final String value;
  final Widget child;
  final bool copyOnTap;
  final bool copyOnDoubleTap;
  final bool copyOnLongPress;
  final bool withInk;
  final void Function()? onCopied;

  const CopyableWidget({
    super.key,
    required this.value,
    required this.child,
    this.copyOnTap = false,
    this.copyOnDoubleTap = false,
    this.copyOnLongPress = false,
    this.withInk = false,
    this.onCopied,
  });

  void _onTap() {
    if (copyOnTap) {
      _copy();
    }
  }

  void _onDoubleTap() {
    if (copyOnDoubleTap) {
      _copy();
    }
  }

  void _onLongPress() {
    if (copyOnLongPress) {
      _copy();
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: value));
    if (onCopied != null) {
      onCopied!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return withInk
        ? InkWell(
            onTap: copyOnTap ? _onTap : null,
            onDoubleTap: copyOnDoubleTap ? _onDoubleTap : null,
            onLongPress: copyOnLongPress ? _onLongPress : null,
            child: child,
          )
        : GestureDetector(
            onTap: copyOnTap ? _onTap : null,
            onDoubleTap: copyOnDoubleTap ? _onDoubleTap : null,
            onLongPress: copyOnLongPress ? _onLongPress : null,
            child: child,
          );
  }
}
