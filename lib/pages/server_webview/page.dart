import "package:certimate/pages/server/provider.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";

class ServerWebViewPage extends HookConsumerWidget {
  final String url;
  final int serverId;

  const ServerWebViewPage({
    super.key,
    required this.serverId,
    required this.url,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(serverProvider(serverId));
    final theme = Theme.of(context);
    final language = Intl.message("en", name: "_locale").split("-")[0];
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final settingsCss = url.contains("/#/settings/")
        ? """
      main > :first-child {
        padding-top:0 !important;
      }
      main .container h1 {
        display: none !important;
      }
      main .container .ant-menu {
        display: none !important;
      }
    """
        : "";
    return WebviewWidget(
      serverId: serverId,
      url: url.startsWith("http") ? url : "${server.value?.host}$url",
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: "onFetchRequest",
          callback: (args) {
            final String url = args[0]["url"];
            final method = args[0]["method"];
            final status = args[0]["status"];
            if (method == "POST" &&
                status == 200 &&
                url.startsWith(
                  "${server.value?.host}/api/collections/access/records",
                )) {
              Navigator.of(context).maybePop(1);
            }
          },
        );
      },
      initialUserScripts: [
        UserScript(
          source:
            """
            localStorage.setItem("certimate-ui-lang", "$language");
            localStorage.setItem("certimate-ui-theme", "${theme.brightness.name}");
            localStorage.setItem("pocketbase_auth", JSON.stringify({ "token": "${server.value?.token ?? ""}" }));
            document.addEventListener("DOMContentLoaded", function() {
              var style = document.createElement("style");
              style.type = "text/css";
              style.innerHTML = `
                header,.ant-layout-sider { 
                  display: none !important;
                }
                main {
                  padding-bottom: ${safeBottom}px;
                }
                $settingsCss
              `;
              document.head.appendChild(style);
            });
          """,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
        UserScript(
          source: """
            (function() {
              if (window._hasHookedFetch) return;
              window._hasHookedFetch = true;
            
              const originalFetch = window.fetch;
              window.fetch = function() {
                const url = arguments[0];
                const options = arguments[1] || {};
                return originalFetch.apply(this, arguments).then(function(response) {
                  if(window.flutter_inappwebview){
                    window.flutter_inappwebview.callHandler('onFetchRequest', {
                      url: typeof url === 'string' ? url : (url.url || ''),
                      method: options.method || 'GET',
                      status: response.status,
                    });
                  }
                  return response;
                });
              };
            })();
          """,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
        ),
      ],
    );
  }
}
