import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:certimate/extension/index.dart";
import "package:certimate/widgets/indicator.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_svg/flutter_svg.dart";

typedef EmptyOnLoad = FutureOr Function();

class EmptyWidget extends StatelessWidget {
  final String? msg;
  final EmptyOnLoad? onReload;
  final bool showLoading;

  const EmptyWidget({
    super.key,
    this.onReload,
    this.msg,
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    final message = msg ?? context.s.noData;
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.memory(
          _getEmptySvg(theme.colorScheme.primary),
          width: 166.5,
        ),
        const SizedBox(height: 16),
        if (message.isNotEmpty) Text(message),
        if (onReload != null) const SizedBox(height: 16),
        if (onReload != null)
          EmptyLoadButton(onReload: onReload, showLoading: showLoading),
      ],
    );
  }
}

class EmptyLoadButton extends StatefulWidget {
  final EmptyOnLoad? onReload;
  final bool showLoading;

  const EmptyLoadButton({super.key, this.onReload, this.showLoading = true});

  @override
  State<EmptyLoadButton> createState() => _EmptyLoadButtonState();
}

class _EmptyLoadButtonState extends State<EmptyLoadButton> {
  bool loading = false;
  int loadingTime = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return PlatformElevatedButton(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
      onPressed: () {
        if (loading) {
          return;
        }
        final result = widget.onReload?.call();
        if (result is Future) {
          setState(() {
            loading = true;
          });
          loadingTime = loadingTime = DateTime.now().millisecondsSinceEpoch;
          result.whenComplete(() {
            final milliseconds =
                DateTime.now().millisecondsSinceEpoch - loadingTime;
            if (milliseconds >= 1200) {
              setState(() {
                loading = false;
              });
            } else {
              // 加载状态至少持续 1.2s
              final duration = Duration(milliseconds: 1200 - milliseconds);
              Future.delayed(duration).then((_) {
                setState(() {
                  loading = false;
                });
              });
            }
          });
        }
      },
      child: loading && widget.showLoading
          ? const PlatformCircularIndicator(color: Colors.white, size: 20)
          : Text(s.reload),
    );
  }
}

const _emptySvg = """
<svg width="666" height="640" viewBox="0 0 666 640" xmlns="http://www.w3.org/2000/svg">
  <rect x="1.27796" y="144.482" width="426" height="490" rx="19" transform="rotate(-19.643 1.27796 144.482)" fill="#FFFFFF" stroke="#000000" stroke-width="2"/>
  <circle cx="186.427" cy="42.7219" r="20" transform="rotate(-19.2094 186.427 42.7219)" fill="#B86915"/>
  <circle cx="186.427" cy="42.7219" r="12" transform="rotate(-19.2094 186.427 42.7219)" fill="#FFFFFF"/>
  <rect x="43.373" y="152.867" width="356" height="444" rx="12" transform="rotate(-19.2094 43.373 152.867)" fill="#F2F2F2"/>
  <rect x="95.9857" y="91.1179" width="202" height="60" rx="10" transform="rotate(-19.2094 95.9857 91.1179)" fill="#B86915"/>
  <rect x="235.008" y="148.232" width="426" height="490" rx="19" transform="rotate(-0.433638 235.008 148.232)" fill="#FFFFFF" stroke="#000000" stroke-width="2"/>
  <circle cx="443" cy="114" r="20" fill="#B86915"/>
  <circle cx="443" cy="114" r="12" fill="#FFFFFF"/>
  <rect x="272" y="170" width="356" height="444" rx="12" fill="#E6E6E6"/>
  <rect x="342" y="129" width="202" height="60" rx="10" fill="#B86915"/>
</svg>
  """;

Uint8List _getEmptySvg(Color color) {
  return Uint8List.fromList(
    utf8.encode(_emptySvg.replaceAll("#B86915", color.hex)),
  );
}
