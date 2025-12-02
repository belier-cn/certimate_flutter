import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";

class PlatformCircularIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const PlatformCircularIndicator({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, _) => size != null
          ? SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : CircularProgressIndicator(strokeWidth: 2, color: color),
      cupertino: (_, _) => CupertinoActivityIndicator(
        radius: size != null ? size! / 2 : 10,
        color: color,
      ),
    );
  }
}
