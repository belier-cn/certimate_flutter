import "package:flutter/material.dart";

class RemoveFocus extends StatefulWidget {
  final Widget child;

  const RemoveFocus({super.key, required this.child});

  @override
  State<RemoveFocus> createState() => _RemoveFocusState();
}

class _RemoveFocusState extends State<RemoveFocus> {
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_focusNode != null) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }
}
