import "package:certimate/extension/index.dart";
import "package:extra_hittest_area/extra_hittest_area.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";

class AppSliverAppBar extends StatelessWidget {
  final Widget title;

  final Widget? leading;

  final double? leadingWidth;

  final Widget? trailing;

  final TextEditingController? searchController;

  final String? searchPlaceholder;

  final ValueChanged<String>? onSubmitted;

  final bool largeTitle;

  final bool? automaticallyImplyLeading;

  const AppSliverAppBar({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
    this.searchController,
    this.searchPlaceholder,
    this.onSubmitted,
    this.largeTitle = true,
    this.leadingWidth,
    this.automaticallyImplyLeading,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (context, _) => _buildMaterialSliverAppBar(context),
      cupertino: (context, _) {
        if (!largeTitle && searchController == null) {
          final height =
              kMinInteractiveDimensionCupertino +
              MediaQuery.of(context).padding.top;
          return SliverPersistentHeader(
            pinned: true,
            delegate: PersistentHeaderBuilder(
              min: height,
              max: height,
              builder: (ctx, offset) {
                return CupertinoNavigationBar(
                  leading: leading,
                  middle: title,
                  trailing: trailing,
                  border: const Border(),
                  padding: EdgeInsetsDirectional.zero,
                );
              },
            ),
          );
        }
        return searchController != null
            ? CupertinoSliverNavigationBar.search(
                searchField: CupertinoSearchTextField(
                  controller: searchController,
                  placeholder: searchPlaceholder,
                  onSubmitted: onSubmitted,
                  onChanged: (value) {
                    if (value.isEmpty) {
                      // clear
                      onSubmitted?.call(value);
                    }
                  },
                ),
                leading: leading,
                largeTitle: title,
                trailing: trailing,
                border: const Border(),
                padding: EdgeInsetsDirectional.zero,
              )
            : CupertinoSliverNavigationBar(
                leading: leading,
                largeTitle: title,
                trailing: trailing,
                border: const Border(),
                padding: EdgeInsetsDirectional.zero,
              );
      },
    );
  }

  Widget _buildMaterialSliverAppBar(
    BuildContext context, {
    bool cupertino = false,
  }) {
    final theme = context.theme;
    final toolbarHeight = theme.appBarTheme.toolbarHeight ?? kToolbarHeight;
    return SliverAppBar(
      leading: leading,
      leadingWidth: leadingWidth,
      title: title,
      pinned: true,
      floating: true,
      toolbarHeight: toolbarHeight,
      expandedHeight:
          toolbarHeight +
          (searchController != null ? SearchFlexibleSpaceBar.height : 0),
      actions: trailing != null ? [trailing!] : null,
      titleTextStyle: cupertino
          ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
          : null,
      flexibleSpace: searchController != null
          ? SearchFlexibleSpaceBar(
              searchController: searchController!,
              searchPlaceholder: searchPlaceholder,
              onSubmitted: onSubmitted,
            )
          : null,
    );
  }
}

class SearchFlexibleSpaceBar extends StatelessWidget {
  static final double height = 56 + 8;

  final TextEditingController searchController;
  final String? searchPlaceholder;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  const SearchFlexibleSpaceBar({
    super.key,
    required this.searchController,
    this.searchPlaceholder,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlexibleSpaceBar(
      background: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: SearchBar(
                controller: searchController,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16),
                ),
                leading: const Icon(Icons.search),
                elevation: WidgetStateProperty.all(0),
                onSubmitted: onSubmitted,
                onChanged: onChanged,
                hintText: searchPlaceholder ?? context.s.search.capitalCase,
                trailing: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    child: GestureDetectorHitTestWithoutSizeLimit(
                      extraHitTestArea: const EdgeInsets.all(8),
                      onTap: () {
                        searchController.clear();
                        onSubmitted?.call("");
                      },
                      child: const Icon(Icons.close),
                    ),
                    builder: (_, value, child) {
                      return value.text.isEmpty
                          ? const SizedBox.shrink()
                          : child!;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersistentHeaderBuilder extends SliverPersistentHeaderDelegate {
  final double max;
  final double min;
  final Widget Function(BuildContext context, double offset) builder;

  PersistentHeaderBuilder({
    required this.max,
    required this.min,
    required this.builder,
  }) : assert(max >= min);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return builder(context, shrinkOffset);
  }

  @override
  double get maxExtent => max;

  @override
  double get minExtent => min;

  @override
  bool shouldRebuild(covariant PersistentHeaderBuilder oldDelegate) =>
      max != oldDelegate.max ||
      min != oldDelegate.min ||
      builder != oldDelegate.builder;
}
