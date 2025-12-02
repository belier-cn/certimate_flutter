import "package:certimate/widgets/index.dart";
import "package:copy_with_extension/copy_with_extension.dart";
import "package:flex_color_scheme/flex_color_scheme.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "provider.g.dart";

@CopyWith()
class ThemePageData extends RefreshData<FlexScheme> {
  @override
  final List<FlexScheme> list;

  const ThemePageData(this.list);
}

@riverpod
class ThemePageNotifier extends _$ThemePageNotifier {
  @override
  FutureOr<ThemePageData> build() {
    return ThemePageData([
      FlexScheme.gold,
      ...FlexScheme.values.where(
        (item) => item != FlexScheme.gold && item != FlexScheme.custom,
      ),
    ]);
  }
}
