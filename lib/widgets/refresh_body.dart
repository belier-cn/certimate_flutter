import "package:adaptive_dialog/adaptive_dialog.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/hooks/index.dart";
import "package:certimate/theme/theme.dart";
import "package:certimate/widgets/index.dart";
import "package:collection/collection.dart";
import "package:dio/dio.dart";
import "package:easy_refresh/easy_refresh.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_riverpod/experimental/mutation.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:go_router/go_router.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_design/material_design.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

class SubmitRefreshData<T> extends RefreshData<T> {
  @override
  final List<T> list;

  T get value => list.first;

  const SubmitRefreshData(this.list);
}

class OnlySubmitRefreshData extends RefreshData<int> {
  @override
  final List<int> list;

  const OnlySubmitRefreshData({this.list = const [0]});
}

abstract class RefreshData<ItemT> {
  List<ItemT> get list;

  int get topItemCount => 0;

  const RefreshData();
}

mixin LoadMoreMixin {
  int page = 1;
  int total = 0;
  bool hasMore = false;

  Future<IndicatorResult> loadMore();
}

mixin SubmitMixin {
  Mutation get submitMutation;

  GlobalKey<FormBuilderState>? get formKey;

  Future submit(BuildContext context, Map<String, dynamic> data);
}

abstract class FilterEnum {
  String get filter;
}

class SortField {
  final String name;
  final String field;

  final Sort firstSort;

  const SortField({
    required this.name,
    required this.field,
    required this.firstSort,
  });
}

enum Sort { asc, desc }

mixin FilterMixin<FilterT extends Enum> {
  List<FilterT> get filterItems;

  List<SortField> get sortItems;

  FilterT? filter;

  String sortField = "";

  Sort sort = Sort.asc;

  String getFilter() {
    if (filter != null && filter is FilterEnum) {
      return (filter as FilterEnum).filter;
    }
    return "";
  }

  String getSort() {
    if (sortField == "") {
      return "";
    }
    return "${sort == Sort.asc ? "" : "-"}$sortField";
  }
}

mixin SearchMixin {
  String searchKey = "";
}

typedef RefreshBodyItemBuilder<T> =
    Widget? Function(BuildContext context, T data, int index);

typedef RefreshBodyDataLoad<T> = Function(BuildContext context, T data);

class RefreshBody<ValueT extends RefreshData> extends StatelessWidget {
  final $AsyncNotifierProvider<$AsyncNotifier<ValueT>, ValueT> provider;

  final RefreshBodyItemBuilder<ValueT> itemBuilder;

  final Widget? title;

  final bool? automaticallyImplyLeading;

  final Widget? trailing;

  final TextEditingController? searchController;

  final String? searchPlaceholder;

  final ValueChanged<String>? onSubmitted;

  final EasyRefreshController? refreshController;

  final ScrollController? scrollController;

  final ValueNotifier? topVisible;

  final double itemSpacing;

  final RefreshBodyDataLoad? firstLoadSuccess;

  const RefreshBody({
    super.key,
    this.title,
    this.trailing,
    required this.provider,
    required this.itemBuilder,
    this.refreshController,
    this.scrollController,
    this.searchController,
    this.searchPlaceholder,
    this.onSubmitted,
    this.topVisible,
    this.itemSpacing = M3Spacings.space12,
    this.automaticallyImplyLeading,
    this.firstLoadSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeData>()!;
    final mediaQuery = MediaQuery.of(context);
    final Widget body = HookConsumer(
      builder: (_, ref, _) {
        final data = ref.watch(provider);
        final notifier = ref.read(provider.notifier);

        useCallOnceWhen(data.hasValue, () {
          final value = data.value;
          if (value == null) {
            return;
          }
          firstLoadSuccess?.call(context, value);
        });

        final firstLoading = !data.hasValue && data.isLoading;
        final isSubmit = notifier is SubmitMixin;
        final leadingWidth =
            isSubmit && ModalRoute.of(context) is CupertinoSheetRoute
            ? 120.0
            : null;
        final leadingWidget = leadingWidth != null && leadingWidth > 0
            ? Container(
                width: leadingWidth,
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: appTheme.cupertinoButtonPadding,
                  onPressed: context.pop,
                  child: Text(s.cancel.capitalCase),
                ),
              )
            : null;
        final trailingWidget =
            trailing ??
            (isSubmit
                ? CupertinoButton(
                    onPressed: () {
                      final formKey = (notifier as SubmitMixin).formKey;
                      if (formKey == null ||
                          formKey.currentState?.saveAndValidate() == true) {
                        (notifier as SubmitMixin).submitMutation.run(ref, (
                          tsx,
                        ) async {
                          final eq = const DeepCollectionEquality();
                          final initialValues = formKey?.currentState?.fields
                              .map((key, field) {
                                return MapEntry(key, field.initialValue);
                              });
                          final values = formKey?.currentState?.fields.map((
                            key,
                            field,
                          ) {
                            return MapEntry(key, field.value);
                          });
                          if (eq.equals(initialValues, values)) {
                            showOkAlertDialog(
                              context: context,
                              title: s.tip.capitalCase,
                              message: s.pleaseUpdateAndSubmit,
                            );
                            return;
                          }
                          try {
                            await (notifier as SubmitMixin).submit(
                              context,
                              formKey?.currentState?.value ?? {},
                            );
                          } catch (err) {
                            SmartDialog.showToast("$err");
                          }
                        });
                      }
                    },
                    padding: appTheme.cupertinoButtonPadding,
                    child: Consumer(
                      builder: (_, ref, _) {
                        final submitLoading = ref.watch(
                          (notifier as SubmitMixin).submitMutation,
                        );
                        if (submitLoading is MutationPending) {
                          return const PlatformCircularIndicator(size: 20);
                        }
                        return Text(s.save.capitalCase);
                      },
                    ),
                  )
                : null);
        final scrollView = CustomScrollView(
          controller: scrollController,
          physics: const RangeMaintainingScrollPhysics(),
          slivers: [
            if (title != null)
              AppSliverAppBar(
                title: title!,
                leading: leadingWidget,
                leadingWidth: leadingWidth,
                trailing: trailingWidget,
                largeTitle: refreshController != null,
                automaticallyImplyLeading: automaticallyImplyLeading,
                onSubmitted:
                    onSubmitted ??
                    (value) {
                      if (notifier is SearchMixin) {
                        (notifier as SearchMixin).searchKey = value;
                        Future.delayed(const Duration(milliseconds: 200)).then(
                          (_) => refreshController?.callRefresh(
                            scrollController: scrollController,
                          ),
                        );
                      }
                    },
                searchController: searchController,
                searchPlaceholder: searchPlaceholder,
              ),
            if (refreshController != null) const HeaderLocator.sliver(),
            ...data.maybeWhen(
              error: (err, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: appTheme.bodyPadding,
                      child: EmptyWidget(
                        msg: err is DioException ? err.message : "$err",
                        onReload: () => ref.refresh(provider.future),
                      ),
                    ),
                  ),
                ),
              ],
              orElse: () {
                if (firstLoading) {
                  return [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: PlatformCircularIndicator()),
                    ),
                  ];
                }
                final list = data.requireValue.list;
                final isFilterMixin = notifier is FilterMixin;
                FilterWidget<Enum> filterWidget(int index) => FilterWidget(
                  index: index,
                  filterItems: (notifier as FilterMixin).filterItems,
                  filter: (notifier as FilterMixin).filter,
                  sortItems: (notifier as FilterMixin).sortItems,
                  sortFiled: (notifier as FilterMixin).sortField,
                  sort: (notifier as FilterMixin).sort,
                  onFilterChange: (filter) {
                    if ((notifier as FilterMixin).filter != filter) {
                      (notifier as FilterMixin).filter = filter;
                      refreshController?.callRefresh(
                        scrollController: scrollController,
                      );
                    }
                  },
                  onSortChange: (sortFiled, sort) {
                    if ((notifier as FilterMixin).sortField != sortFiled ||
                        (notifier as FilterMixin).sort != sort) {
                      (notifier as FilterMixin).sortField = sortFiled;
                      (notifier as FilterMixin).sort = sort;
                      refreshController?.callRefresh(
                        scrollController: scrollController,
                      );
                    }
                  },
                  label: s.totalItems(
                    notifier is LoadMoreMixin
                        ? (notifier as LoadMoreMixin).total
                        : list.length,
                  ),
                );
                final totalLength =
                    list.length +
                    data.requireValue.topItemCount +
                    (list.isEmpty ? 1 : 0) +
                    (isFilterMixin ? 1 : 0);
                if (data.requireValue.topItemCount <= 0 && list.isEmpty) {
                  return [
                    if (isFilterMixin)
                      SliverPadding(
                        padding: appTheme.bodyPadding,
                        sliver: SliverToBoxAdapter(child: filterWidget(0)),
                      ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: appTheme.bodyPadding,
                        child: const EmptyWidget(),
                      ),
                    ),
                  ];
                }

                Widget listItemBuilder(context, index) {
                  if (isFilterMixin &&
                      index == data.requireValue.topItemCount) {
                    return filterWidget(index);
                  }
                  if (list.isEmpty && index == totalLength - 1) {
                    return Padding(
                      padding: EdgeInsets.all(appTheme.bodyPadding.left),
                      child: const EmptyWidget(),
                    );
                  }
                  final itemWidget = itemBuilder.call(
                    context,
                    data.requireValue,
                    index - (isFilterMixin ? 1 : 0),
                  );
                  if (itemWidget != null && itemSpacing > 0 && index > 0) {
                    return Padding(
                      padding: EdgeInsets.only(top: itemSpacing),
                      child: itemWidget,
                    );
                  }
                  return itemWidget ?? const SizedBox.shrink();
                }

                return [
                  SliverPadding(
                    padding: appTheme.bodyPadding.copyWith(
                      top: searchController != null
                          ? appTheme.bodyPadding.left / 2
                          : appTheme.bodyPadding.left,
                      bottom: mediaQuery.padding.bottom > 0
                          ? mediaQuery.padding.bottom
                          : appTheme.bodyPadding.left,
                    ),
                    sliver: isSubmit
                        ? SliverList.list(
                            children: List.generate(
                              totalLength,
                              (index) => listItemBuilder(context, index),
                            ),
                          )
                        : SliverList.builder(
                            itemCount: totalLength,
                            itemBuilder: listItemBuilder,
                          ),
                  ),
                ];
              },
            ),
          ],
        );
        if (refreshController == null) {
          return scrollView;
        }
        return EasyRefresh(
          scrollController: scrollController,
          controller: refreshController,
          onRefresh: data.hasValue ? () => ref.refresh(provider.future) : null,
          onLoad:
              notifier is LoadMoreMixin && (notifier as LoadMoreMixin).hasMore
              ? (notifier as LoadMoreMixin).loadMore
              : null,
          header: const CupertinoHeader(
            position: IndicatorPosition.locator,
            safeArea: false,
          ),
          child: scrollView,
        );
      },
    );
    if (scrollController != null && topVisible != null) {
      return NotificationListener(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            topVisible!.value = false;
          } else if (notification is ScrollEndNotification) {
            if (notification.metrics.pixels >= 200) {
              topVisible!.value = true;
            }
          }
          return true;
        },
        child: Stack(
          children: [
            body,
            Positioned(
              right: 20,
              bottom: 20 + mediaQuery.padding.bottom,
              child: ValueListenableBuilder(
                valueListenable: topVisible!,
                builder: (context, visible, _) {
                  return AnimatedSlide(
                    offset: visible ? Offset.zero : const Offset(2, 0),
                    duration: const Duration(milliseconds: 300),
                    child: FloatingActionButton.small(
                      heroTag: null,
                      onPressed: () {
                        scrollController?.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear,
                        );
                      },
                      shape: const CircleBorder(),
                      child: const Icon(
                        TablerIcons.arrow_up,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    return body;
  }
}

typedef FilterChange<FilterT> = Function(FilterT item);
typedef SortChange = Function(String field, Sort sort);

class FilterWidget<FilterT extends Enum> extends StatelessWidget {
  final String label;

  final List<FilterT> filterItems;
  final List<SortField> sortItems;
  final FilterT? filter;
  final Sort? sort;
  final String sortFiled;

  final FilterChange<FilterT?>? onFilterChange;
  final SortChange? onSortChange;

  final int? index;

  const FilterWidget({
    super.key,
    this.label = "",
    this.filterItems = const [],
    this.sortItems = const [],
    this.filter,
    this.sort,
    this.sortFiled = "",
    this.onFilterChange,
    this.onSortChange,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Padding(
      padding: index == 0
          ? const EdgeInsets.only(
              left: M3Spacings.space12,
              right: M3Spacings.space12,
              bottom: M3Spacings.space8,
            )
          : const EdgeInsets.symmetric(
              horizontal: M3Spacings.space12,
              vertical: M3Spacings.space8,
            ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          label.isNotEmpty ? Text(label) : const SizedBox(),
          PlatformPullDownButton(
            options: [
              if (filterItems.isNotEmpty)
                PullDownOption(
                  selected: filter == null,
                  label: s.all.capitalCase,
                  onTap: (_) {
                    onFilterChange?.call(null);
                  },
                ),
              ...filterItems.mapIndexed((index, item) {
                final name = item.toString().split(".").last;
                return PullDownOption(
                  selected: filter == item,
                  label: Intl.message(name, name: name).capitalCase,
                  onTap: (_) {
                    onFilterChange?.call(item);
                  },
                  withDivider:
                      index == filterItems.length - 1 && sortItems.isNotEmpty,
                );
              }),
              ...sortItems.map((item) {
                return PullDownOption(
                  selected: sortFiled == item.field,
                  label: Intl.message(item.name, name: item.name).capitalCase,
                  iconWidget: item.field == sortFiled
                      ? Icon(
                          sort == Sort.asc
                              ? context.appIcons.sortAsc
                              : context.appIcons.sortDesc,
                        )
                      : null,
                  onTap: (_) {
                    onSortChange?.call(
                      item.field,
                      item.field == sortFiled
                          ? (sort == Sort.asc ? Sort.desc : Sort.asc)
                          : item.firstSort,
                    );
                  },
                );
              }),
            ],
            icon: Icon(
              context.appIcons.filter,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
