import "package:flutter/material.dart";

class GridRow extends StatelessWidget {
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final List<Widget> children;
  final bool expanded;

  const GridRow({
    super.key,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.expanded = true,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final groupList = chunkArray(children, crossAxisCount);
    final List<Widget> widgets = [];

    for (int j = 0; j < groupList.length; j++) {
      var item = groupList[j];
      if (expanded && crossAxisCount > item.length) {
        // 补全该行的数据
        item = padList(item, crossAxisCount, const SizedBox());
      }
      final length = item.length;
      final List<Widget> children = [];
      for (int i = 0; i < item.length; i++) {
        children.add(expanded ? Expanded(child: item[i]) : item[i]);
        if (length > 1 && i < length - 1 && mainAxisSpacing > 0) {
          // 添加间距
          children.add(SizedBox(width: mainAxisSpacing));
        }
      }
      widgets.add(
        Row(mainAxisAlignment: MainAxisAlignment.center, children: children),
      );
      if (groupList.length > 1 && j < groupList.length - 1) {
        // 添加间距
        widgets.add(SizedBox(height: crossAxisSpacing));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: widgets);
  }

  List<List<T>> chunkArray<T>(List<T> list, int n) {
    return List.generate(
      (list.length / n).ceil(),
      (index) => list.sublist(
        index * n,
        (index * n + n) > list.length ? list.length : (index * n + n),
      ),
    );
  }

  List<T> padList<T>(List<T> list, int n, T fillValue) {
    if (list.length >= n) return list;
    return list + List.filled(n - list.length, fillValue);
  }
}
