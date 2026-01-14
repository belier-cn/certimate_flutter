import "package:certimate/extension/index.dart";
import "package:certimate/router/route.dart";
import "package:certimate/router/router.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:go_router/go_router.dart";
import "package:material_design/material_design.dart";

class AppBarIconButton extends StatelessWidget {
  final IconData icon;

  const AppBarIconButton(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    final isCupertinoStyle = context.isCupertinoStyle;
    return Icon(
      icon,
      color: context.theme.primaryColor,
      size: isCupertinoStyle ? 26 : null,
    );
  }
}

class AppBarLeading extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBarLeading({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !context.canPop()) {
      return const SizedBox.shrink();
    }

    defaultOnPressed() {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else {
        const HomeRoute().replace(context);
      }
    }

    if (context.isCupertinoStyle) {
      return CupertinoNavigationBarBackButton(
        onPressed: onPressed ?? defaultOnPressed,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: BackButton(onPressed: onPressed ?? defaultOnPressed),
      );
    }
  }
}

class ActionButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool well;

  const ActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.well = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: M3Margins.compactScreen),
      child: SizedBox(
        height: kToolbarHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [child],
        ),
      ),
    );
    return well
        ? (context.isCupertinoStyle
              ? CupertinoWell(
                  onPressed: onPressed,
                  onLongPress: onLongPress,
                  child: body,
                )
              : IconButton(onPressed: onPressed, icon: child))
        : body;
  }
}

class DebugDraggableButton extends StatefulWidget {
  final GestureTapCallback? onTap;
  final double btnSize;
  final Color? btnColor;

  const DebugDraggableButton({
    super.key,
    this.onTap,
    this.btnSize = 66,
    this.btnColor,
  });

  @override
  DebugDraggableButtonState createState() => DebugDraggableButtonState();

  static final String debugButtonTag = "debugButton";

  static Future<void> show() {
    if (!SmartDialog.checkExist(tag: debugButtonTag)) {
      return SmartDialog.show(
        tag: debugButtonTag,
        clickMaskDismiss: false,
        usePenetrate: true,
        debounce: true,
        animationType: SmartAnimationType.fade,
        maskColor: Colors.transparent,
        bindPage: false,
        backType: SmartBackType.ignore,
        builder: (_) => Consumer(
          builder: (context, ref, _) {
            return DebugDraggableButton(
              onTap: () {
                ref.read(routerProvider).push(const DebugRoute().location);
              },
              btnSize: 50,
            );
          },
        ),
      );
    }
    return Future.value(null);
  }

  static Future<void> dismiss() => SmartDialog.dismiss(tag: debugButtonTag);
}

class DebugDraggableButtonState extends State<DebugDraggableButton> {
  double left = -1;
  double top = -1;
  late double screenWidth;
  late double screenHeight;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    if (top < 0) {
      top = (screenHeight - widget.btnSize) / 2;
    }
    if (left < 0) {
      if (RunPlatform.isDesktop) {
        left = 15;
      } else {
        left = screenWidth - widget.btnSize - 20;
      }
    }
    Widget w;
    Color primaryColor = widget.btnColor ?? Theme.of(context).primaryColor;
    primaryColor = primaryColor.withValues(alpha: 0.6);
    w = GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: _dragUpdate,
      child: Container(
        width: widget.btnSize,
        height: widget.btnSize,
        color: primaryColor,
        child: Center(
          child: Icon(
            Icons.bug_report,
            color: Colors.white,
            size: widget.btnSize / 2,
          ),
        ),
      ),
    );

    //圆形
    w = ClipRRect(
      borderRadius: BorderRadius.circular(widget.btnSize / 2),
      child: w,
    );

    //计算偏移量限制
    if (left < 1) {
      left = 1;
    }
    if (left > screenWidth - widget.btnSize) {
      left = screenWidth - widget.btnSize;
    }

    if (top < 1) {
      top = 1;
    }
    if (top > screenHeight - widget.btnSize) {
      top = screenHeight - widget.btnSize;
    }
    w = Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(left: left, top: top),
      child: w,
    );
    return w;
  }

  void _dragUpdate(DragUpdateDetails detail) {
    final Offset offset = detail.delta;
    setState(() {
      left = left + offset.dx;
      top = top + offset.dy;
    });
  }
}
