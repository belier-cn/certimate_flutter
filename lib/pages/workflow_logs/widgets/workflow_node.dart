import "package:certimate/api/workflow_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/theme/theme.dart";
import "package:certimate/widgets/index.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:graphview/GraphView.dart";
import "package:safemap/safemap.dart";

class WorkflowNodeWidget extends StatefulWidget {
  final List<WorkflowNode> nodes;

  final bool fullscreen;

  const WorkflowNodeWidget({
    super.key,
    required this.nodes,
    this.fullscreen = false,
  });

  @override
  State<WorkflowNodeWidget> createState() => _WorkflowNodeWidgetState();
}

const Map<String, Color> _colorMap = {
  "start": Color(0xFFED6D0B),
  "end": Color(0xFF336DF4),
  "delay": Color(0xFFFED421),
  "bizApply": Color(0xFF5B65F5),
  "condition": Color(0xFF373D43),
  "bizDeploy": Color(0xFF5B65F5),
  "bizNotify": Color(0xFF0993D4),
  "bizMonitor": Color(0xFF5B65F5),
  "bizUpload": Color(0xFF5B65F5),
  "tryCatch": Color(0xFF373D43),
  "branchBlock": Color(0xFF373D43),
  "tryBlock": Color(0xFF373D43),
};

const Map<String, IconData> _iconMap = {
  "start": TablerIcons.rocket,
  "end": TablerIcons.logout,
  "delay": TablerIcons.hourglass_high,
  "bizApply": TablerIcons.contract,
  "condition": TablerIcons.sitemap,
  "bizDeploy": TablerIcons.package,
  "bizNotify": TablerIcons.send,
  "bizMonitor": TablerIcons.device_desktop_search,
  "bizUpload": TablerIcons.cloud_upload,
  "tryCatch": TablerIcons.arrows_split,
  "branchBlock": TablerIcons.filter,
  "tryBlock": TablerIcons.filter,
};

class _WorkflowNodeWidgetState extends State<WorkflowNodeWidget>
    with AutomaticKeepAliveClientMixin {
  late GraphViewController _controller;

  late Graph _graph;

  final GlobalKey _graphViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = GraphViewController();
    _graph = Graph();
    if (widget.nodes.isNotEmpty) {
      _addEdge(widget.nodes, null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final graphView = GraphView.builder(
      key: _graphViewKey,
      graph: _graph,
      algorithm: TidierTreeLayoutAlgorithm(
        BuchheimWalkerConfiguration(
          orientation: BuchheimWalkerConfiguration.ORIENTATION_RIGHT_LEFT,
        ),
        ArrowEdgeRenderer(),
      ),
      controller: _controller,
      animated: true,
      autoZoomToFit: true,
      centerGraph: true,
      paint: Paint()..color = theme.textTheme.bodyMedium!.color!,
      builder: (Node node) {
        return _buildNode(context, node);
      },
    );
    final toolbarHeight = theme.appBarTheme.toolbarHeight ?? 44;
    return widget.fullscreen
        ? RotatedBox(
            quarterTurns: isPhoneDevice ? 1 : 0,
            child: Stack(
              children: [
                Container(
                  color: theme.scaffoldBackgroundColor,
                  child: graphView,
                ),
                Positioned(
                  right: MediaQuery.of(context).padding.bottom,
                  child: CupertinoWell(
                    onPressed: () {
                      SmartDialog.dismiss();
                    },
                    child: SizedBox(
                      width: toolbarHeight,
                      height: toolbarHeight,
                      child: const Icon(TablerIcons.x, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox(height: 200, child: graphView);
  }

  Widget _buildNode(BuildContext context, Node node) {
    final nodeInfo = (node.key?.value as WorkflowNode?);
    final icon = _buildIcon(nodeInfo?.type);
    final nodeDesc = _getNodeDesc(nodeInfo);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        spacing: 12,
        children: [
          if (icon != null) icon,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nodeInfo?.data?.name ?? "-",
                  style: getLightTheme().textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (nodeDesc != null)
                  Flexible(
                    child: Text(
                      nodeDesc,
                      overflow: TextOverflow.ellipsis,
                      style: getLightTheme().textTheme.bodyMedium?.copyWith(
                        color: getLightTheme().hintColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildIcon(String? type) {
    final icon = _iconMap[type];
    if (icon == null) {
      return null;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _colorMap[type] ?? const Color(0xFF5B65F5),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  String? _getNodeDesc(WorkflowNode? node) {
    if (node == null || node.data == null) {
      return null;
    }
    final config = SafeMap(node.data?.config);
    if (node.type == "bizApply") {
      return config["domains"].string;
    }
    if (node.type == "bizDeploy") {
      return config["provider"].string;
    }
    if (node.type == "bizNotify") {
      return config["provider"].string;
    }
    if (node.type == "bizMonitor") {
      return config["host"].string ?? config["domain"].string;
    }
    if (node.type == "bizUpload") {
      return config["domains"].string;
    }
    return null;
  }

  void _addEdge(
    List<WorkflowNode> nodes,
    WorkflowNode? parent,
    WorkflowNode? next,
  ) {
    nodes.forEachIndexed((index, node) {
      if (node.type != "end") {
        final graphNode = Node.Id(node);
        final blocks = node.blocks ?? [];
        if (blocks.isNotEmpty) {
          _addEdge(blocks, node, parent == null ? nodes[index + 1] : next);
          for (final block in blocks) {
            _graph.addEdge(graphNode, Node.Id(block));
          }
        } else if (next != null) {
          _graph.addEdge(graphNode, Node.Id(next));
        } else if (index + 1 < nodes.length) {
          _graph.addEdge(graphNode, Node.Id(nodes[index + 1]));
        }
      }
    });
  }

  @override
  bool get wantKeepAlive => true;
}
