import "package:certimate/extension/index.dart";
import "package:certimate/pages/theme/provider.dart";
import "package:certimate/pages/theme/widgets/theme_item.dart";
import "package:certimate/provider/theme.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";

class ThemePage extends HookConsumerWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final mediaQuery = MediaQuery.of(context);
    final scrollController = useScrollController();
    final topVisible = useValueNotifier(false);
    final themeScheme = ref.watch(themeSchemeProvider);
    final themePageData = ref.read(themePageProvider);
    final theme = context.theme;
    final isCupertino = context.isCupertinoStyle;
    final selected = useValueNotifier(themeScheme);

    useEffect(() {
      void selectedListener() {
        ref.read(themeSchemeProvider.notifier).update(selected.value);
      }

      selected.addListener(selectedListener);
      if (themePageData.hasValue) {
        // go selected theme
        final list = themePageData.requireValue.list;
        final index = list.indexOf(themeScheme);
        final itemHeight = (isCupertino ? 52 : 72) + 12;
        final appBarHeight =
            mediaQuery.padding.top +
            (theme.appBarTheme.toolbarHeight ?? kToolbarHeight);
        final bottomPadding = mediaQuery.padding.bottom > 0
            ? mediaQuery.padding.bottom
            : theme.appTheme.bodyPadding.left;
        final pageSize = ((mediaQuery.size.height - appBarHeight) / itemHeight)
            .ceil();
        final lastPage = index >= list.length - pageSize;
        final offset =
            (lastPage ? list.length - pageSize : index - 1) * itemHeight +
            theme.appTheme.bodyPadding.left / 2 +
            (lastPage ? bottomPadding : 0);
        if (offset > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollController.animateTo(
              offset,
              duration: const Duration(milliseconds: 300),
              curve: Curves.linear,
            );
          });
        }
      }
      return () {
        selected.removeListener(selectedListener);
      };
    }, []);
    return BasePage(
      child: Scaffold(
        body: RefreshBody<ThemePageData>(
          topVisible: topVisible,
          title: Text(s.theme.titleCase),
          provider: themePageProvider,
          scrollController: scrollController,
          itemBuilder: (context, data, index) {
            final item = data.list[index - data.topItemCount];
            return ThemeItemWidget(
              key: ValueKey(item.name),
              flexScheme: item,
              selected: selected,
            );
          },
        ),
      ),
    );
  }
}
