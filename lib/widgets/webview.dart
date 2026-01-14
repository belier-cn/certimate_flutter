import "dart:collection";

import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/generated/l10n.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:share_plus/share_plus.dart";
import "package:url_launcher/url_launcher.dart";

typedef WebViewCreated = Function(InAppWebViewController controller);

class WebviewWidget extends HookConsumerWidget {
  final String url;
  final int serverId;
  final WebViewCreated? onWebViewCreated;
  final List<UserScript>? initialUserScripts;

  static final darkAppBarBackgroundColorMap = {
    "docs.certimate.me": const Color(0xFF242526),
    "github.com": const Color(0xFF25292F),
  };
  static final darkBodyBackgroundColorMap = {
    "docs.certimate.me": const Color(0xFF1B1B1D),
    "github.com": const Color(0xFF0D1116),
  };

  const WebviewWidget({
    super.key,
    required this.url,
    this.onWebViewCreated,
    this.initialUserScripts,
    this.serverId = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (RunPlatform.isLinux) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("WebView"),
          leading: context.canPop() ? const AppBarLeading() : null,
        ),
        body: const EmptyWidget(msg: "WebView is not supported on Linux"),
      );
    }
    final webviewController = useRef<InAppWebViewController?>(null);
    final navigationHistory = useRef<List<String>>([]);
    final progressNotifier = useValueNotifier<int?>(0);
    final titleNotifier = useValueNotifier<String>(
      serverId > 0 ? "Certimate" : "",
    );
    final currentUrl = useRef<String>(url);
    final theme = Theme.of(context);
    final s = S.of(context);
    final host = Uri.tryParse(url)?.host ?? "";
    final backgroundColor = theme.brightness == Brightness.dark && serverId > 0
        ? const Color(0xFF18191C)
        : null;
    final bodyBackgroundColor = theme.brightness == Brightness.dark
        ? (darkBodyBackgroundColorMap[host] ?? backgroundColor)
        : Colors.white;
    final appBarBackgroundColor = theme.brightness == Brightness.dark
        ? (darkAppBarBackgroundColorMap[host] ?? backgroundColor)
        : Colors.white;
    final setThemeJsCode =
        """
        // docs.certimate.me
        localStorage.setItem("theme", "${theme.brightness.name}");
        // github.com
        document.documentElement.setAttribute('data-color-mode', "${theme.brightness.name}");
      """;
    return BasePage(
      child: Scaffold(
        backgroundColor: bodyBackgroundColor,
        appBar: PlatformAppBar(
          backgroundColor: appBarBackgroundColor,
          title: ValueListenableBuilder(
            valueListenable: titleNotifier,
            builder: (context, title, _) {
              return Text(
                title,
                style: const TextStyle(overflow: TextOverflow.ellipsis),
              );
            },
          ),
          leading: AppBarLeading(
            onPressed: () async {
              final controller = webviewController.value;
              if (controller != null && navigationHistory.value.length > 1) {
                navigationHistory.value.removeLast();
                final previousUrl = navigationHistory.value.last;
                if (previousUrl.contains("#") &&
                    currentUrl.value.split("#")[0] ==
                        previousUrl.split("#")[0]) {
                  await controller.evaluateJavascript(
                    source:
                        "window.location.hash = '${previousUrl.split("#")[1]}';",
                  );
                } else {
                  await controller.loadUrl(
                    urlRequest: URLRequest(url: WebUri(previousUrl)),
                  );
                }
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
          trailingActions: [
            PlatformPullDownButton(
              options: [
                PullDownOption(
                  label: s.copyUrl.capitalCase,
                  iconWidget: Icon(context.appIcons.copy),
                  onTap: (_) async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: currentUrl.value),
                      );
                      if (context.mounted) {
                        final _ = showOkAlertDialog(
                          context: context,
                          message: context.s.copied,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        final _ = showOkAlertDialog(
                          context: context,
                          message: "copy failed",
                        );
                      }
                    }
                  },
                ),
                if (RunPlatform.useShareDevice)
                  PullDownOption(
                    label: s.shareUrl.capitalCase,
                    iconWidget: Icon(context.appIcons.share),
                    onTap: (_) {
                      final url = Uri.tryParse(currentUrl.value);
                      if (url != null) {
                        SharePlus.instance.share(ShareParams(uri: url));
                      }
                    },
                  ),
                PullDownOption(
                  label: s.openInBrowser.capitalCase,
                  iconWidget: Icon(context.appIcons.world),
                  onTap: (_) {
                    final url = Uri.tryParse(currentUrl.value);
                    if (url != null) {
                      launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
              icon: ActionButton(
                well: false,
                child: AppBarIconButton(context.appIcons.ellipsis),
              ),
            ),
          ],
          cupertino: (context, _) {
            return CupertinoNavigationBarData(
              border: const Border(),
              padding: EdgeInsetsDirectional.zero,
            );
          },
        ).getAppBar(context),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(currentUrl.value)),
              initialSettings: InAppWebViewSettings(
                supportZoom: false,
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                overScrollMode: OverScrollMode.NEVER,
                underPageBackgroundColor: backgroundColor,
                transparentBackground: RunPlatform.isPhone,
              ),
              onLoadStart: (_, _) {
                progressNotifier.value = 0;
              },
              onProgressChanged: (_, progress) {
                if (progressNotifier.value != null) {
                  progressNotifier.value = progress;
                }
              },
              onLoadStop: (_, _) {
                progressNotifier.value = null;
              },
              onTitleChanged: (_, title) {
                if (serverId <= 0) {
                  titleNotifier.value = title ?? "";
                }
              },
              initialUserScripts: UnmodifiableListView<UserScript>([
                if (initialUserScripts != null) ...initialUserScripts!,
                UserScript(
                  source:
                      """
                  $setThemeJsCode
                  window.addEventListener("hashchange", function() {
                    window.flutter_inappwebview.callHandler("routeChangeHandler", window.location.href);
                  });
                """,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
                UserScript(
                  source: """
                  (function() {
                    if (window._hasHookedHistory) return;
                    window._hasHookedHistory = true;
                  
                    const originalPushState = history.pushState;
                    const originalReplaceState = history.replaceState;
                    history.pushState = function() {
                      originalPushState.apply(this, arguments);
                      window.flutter_inappwebview.callHandler("routeChangeHandler", window.location.href);
                    };
                    history.replaceState = function() {
                      originalReplaceState.apply(this, arguments);
                      window.flutter_inappwebview.callHandler("routeChangeHandler", window.location.href);
                    };
                  })();
                """,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
                ),
              ]),
              onWebViewCreated: (controller) {
                webviewController.value = controller;
                if (!kIsWeb) {
                  controller.addJavaScriptHandler(
                    handlerName: "routeChangeHandler",
                    callback: (args) {
                      navigationHistory.value.add(args[0] as String);
                    },
                  );
                }
                onWebViewCreated?.call(controller);
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder(
                valueListenable: progressNotifier,
                builder: (context, progress, _) {
                  return Opacity(
                    opacity: progress == null ? 0 : 1,
                    child: SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: theme.colorScheme.primary,
                        value: progress == null ? 0 : progress / 100.0,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
