import "package:certimate/router/router.dart";
import "package:flutter/material.dart";

class RouteAwareWidget extends StatefulWidget {
  final Widget child;

  final VoidCallback? didPush;
  final VoidCallback? didPushNext;

  final VoidCallback? didPop;
  final VoidCallback? didPopNext;

  const RouteAwareWidget({
    super.key,
    required this.child,
    this.didPush,
    this.didPushNext,
    this.didPop,
    this.didPopNext,
  });

  @override
  State<RouteAwareWidget> createState() => _RouteAwareWidgetState();
}

class _RouteAwareWidgetState extends State<RouteAwareWidget> with RouteAware {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didPush() {
    widget.didPush?.call();
    super.didPush();
  }

  @override
  void didPushNext() {
    widget.didPushNext?.call();
    super.didPushNext();
  }

  @override
  void didPop() {
    widget.didPop?.call();
    super.didPop();
  }

  @override
  void didPopNext() {
    widget.didPopNext?.call();
    super.didPopNext();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }
}
