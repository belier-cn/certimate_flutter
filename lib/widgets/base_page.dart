import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

typedef BasePageBuilder =
    Widget Function(BuildContext context, BoxConstraints constraints);

class BasePage<T> extends StatelessWidget {
  final Widget? child;

  final BasePageBuilder? builder;

  // AnnotatedRegion
  final SystemUiOverlayStyle? systemOverlayStyle;

  // ExitInterceptor
  final bool exitInterceptor;

  // PopScope
  final bool canPop;
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;

  const BasePage({
    super.key,
    this.child,
    this.systemOverlayStyle,
    this.exitInterceptor = false,
    this.canPop = true,
    this.onPopInvokedWithResult,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    Widget widget = LayoutBuilder(
      builder: (context, c) {
        return builder != null
            ? builder!(context, c)
            : (child ?? const SizedBox());
      },
    );
    if (exitInterceptor) {
      widget = ExitInterceptor(child: widget);
    } else if (onPopInvokedWithResult != null) {
      widget = PopScope(
        canPop: canPop,
        onPopInvokedWithResult: onPopInvokedWithResult,
        child: widget,
      );
    }
    if (systemOverlayStyle != null) {
      widget = AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemOverlayStyle!,
        child: widget,
      );
    }

    return widget;
  }
}
