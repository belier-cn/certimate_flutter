import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/rendering.dart";

class CupertinoWell extends StatefulWidget {
  final Widget child;
  final double pressedOpacity;
  final bool enabled;
  final VoidCallback? onPressed;

  final VoidCallback? onLongPress;

  static double tapMoveSlop() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.android ||
      TargetPlatform.fuchsia => kCupertinoButtonTapMoveSlop,
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => 0.0,
    };
  }

  const CupertinoWell({
    super.key,
    required this.child,
    this.pressedOpacity = 0.4,
    this.enabled = true,
    this.onPressed,
    this.onLongPress,
  });

  @override
  State<CupertinoWell> createState() => _CupertinoWellState();
}

class _CupertinoWellState extends State<CupertinoWell>
    with SingleTickerProviderStateMixin {
  static const Duration kFadeOutDuration = Duration(milliseconds: 120);
  static const Duration kFadeInDuration = Duration(milliseconds: 180);
  final Tween<double> _opacityTween = Tween<double>(begin: 1.0);

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  late bool isFocused;

  @override
  void initState() {
    super.initState();
    isFocused = false;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 0.0,
      vsync: this,
    );
    _opacityAnimation = _animationController
        .drive(CurveTween(curve: Curves.decelerate))
        .drive(_opacityTween);
    _setTween();
  }

  @override
  void didUpdateWidget(CupertinoWell old) {
    super.didUpdateWidget(old);
    _setTween();
  }

  void _setTween() {
    _opacityTween.end = widget.pressedOpacity;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _buttonHeldDown = false;
  bool _tapInProgress = false;

  void _handleTapDown(TapDownDetails event) {
    setState(() {
      _tapInProgress = true;
    });
    if (!_buttonHeldDown) {
      _buttonHeldDown = true;
      _animate();
    }
  }

  void _handleTapUp(TapUpDetails event) {
    setState(() {
      _tapInProgress = false;
    });
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    final Offset localPosition = renderObject.globalToLocal(
      event.globalPosition,
    );
    if (renderObject.paintBounds
        .inflate(CupertinoWell.tapMoveSlop())
        .contains(localPosition)) {
      _handleTap();
    }
  }

  void _handleTapCancel() {
    setState(() {
      _tapInProgress = false;
    });
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _handleTapMove(TapMoveDetails event) {
    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    final Offset localPosition = renderObject.globalToLocal(
      event.globalPosition,
    );
    final bool buttonShouldHeldDown = renderObject.paintBounds
        .inflate(CupertinoWell.tapMoveSlop())
        .contains(localPosition);
    if (_tapInProgress && buttonShouldHeldDown != _buttonHeldDown) {
      _buttonHeldDown = buttonShouldHeldDown;
      _animate();
    }
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
      context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());
    }
  }

  void _animate() {
    if (_animationController.isAnimating) {
      return;
    }
    final bool wasHeldDown = _buttonHeldDown;
    final TickerFuture ticker = _buttonHeldDown
        ? _animationController.animateTo(
            1.0,
            duration: kFadeOutDuration,
            curve: Curves.easeInOutCubicEmphasized,
          )
        : _animationController.animateTo(
            0.0,
            duration: kFadeInDuration,
            curve: Curves.easeOutCubic,
          );
    ticker.then<void>((void value) {
      if (mounted && wasHeldDown != _buttonHeldDown) {
        _animate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final DeviceGestureSettings? gestureSettings =
        MediaQuery.maybeGestureSettingsOf(context);

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(postAcceptSlopTolerance: null),
              (TapGestureRecognizer instance) {
                instance.onTapDown = enabled ? _handleTapDown : null;
                instance.onTapUp = enabled ? _handleTapUp : null;
                instance.onTapCancel = enabled ? _handleTapCancel : null;
                instance.onTapMove = enabled ? _handleTapMove : null;
                instance.gestureSettings = gestureSettings;
              },
            ),
        if (widget.onLongPress != null)
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(),
                (LongPressGestureRecognizer instance) {
                  instance.onLongPress = widget.onLongPress;
                  instance.gestureSettings = gestureSettings;
                },
              ),
      },
      child: FadeTransition(opacity: _opacityAnimation, child: widget.child),
    );
  }
}
