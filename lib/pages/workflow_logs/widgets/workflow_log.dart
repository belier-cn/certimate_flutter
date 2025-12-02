import "package:certimate/api/workflow_api.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/pages/workflow_runs/widgets/workflow_run.dart";
import "package:certimate/theme/theme.dart";
import "package:certimate/widgets/index.dart";
import "package:flutter/material.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:material_design/material_design.dart";

class WorkflowLogWidget extends StatelessWidget {
  final WorkflowLogResult data;
  final bool start;
  final bool end;
  final bool node;
  final String? status;
  final VoidCallback? onDownload;

  const WorkflowLogWidget({
    super.key,
    required this.data,
    this.start = false,
    this.end = false,
    this.node = true,
    this.status,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final darkTheme = getDarkTheme();
    final logs = Padding(
      padding: EdgeInsets.only(
        top: M3Spacings.space12,
        left: M3Spacings.space12,
        right: M3Spacings.space12,
        bottom: end ? M3Spacings.space12 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: M3Spacings.space8,
        children: [
          if (node)
            Text(
              "# ${data.nodeId}",
              style: TextStyle(color: darkTheme.hintColor),
            ),
          if (node)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: data.created.toDateTimeString(),
                    style: TextStyle(color: darkTheme.hintColor),
                  ),
                  TextSpan(text: " ${data.nodeName}"),
                ],
              ),
            ),
          ExpansionText(
            title: "${data.message}",
            content: data.data?.isNotEmpty == true
                ? data.data.toJsonString()
                : "",
          ),
        ],
      ),
    );
    return DefaultTextStyle(
      style: darkTheme.textTheme.bodyMedium!,
      child: Container(
        decoration: BoxDecoration(
          color: darkTheme.cardColor,
          borderRadius: start || end
              ? BorderRadius.vertical(
                  top: start
                      ? const Radius.circular(M3Corners.medium)
                      : Radius.zero,
                  bottom: end
                      ? const Radius.circular(M3Corners.medium)
                      : Radius.zero,
                )
              : null,
        ),
        child: start && status.isNotEmptyOrNull
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(M3Spacings.space12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        WorkflowRunStatusWidget(status: status),
                        CupertinoWell(
                          onPressed: onDownload,
                          child: Icon(
                            TablerIcons.download,
                            color: darkTheme.iconTheme.color,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: darkTheme.hintColor,
                  ),
                  logs,
                ],
              )
            : logs,
      ),
    );
  }
}

class ExpansionText extends StatefulWidget {
  final String title;
  final String content;

  const ExpansionText({super.key, required this.title, required this.content});

  @override
  State<ExpansionText> createState() => _ExpansionTextState();
}

class _ExpansionTextState extends State<ExpansionText>
    with SingleTickerProviderStateMixin {
  bool expanded = false;
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      expanded = !expanded;
      if (expanded) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.content.isNotEmpty
                  ? RotationTransition(
                      turns: Tween<double>(
                        begin: 0,
                        end: 0.25,
                      ).animate(animation),
                      child: SizedBox(
                        width: 16,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Icon(
                            TablerIcons.caret_right_filled,
                            color: getDarkTheme().iconTheme.color,
                            size: 12,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: 16),
              Expanded(child: Text(widget.title)),
            ],
          ),
        ),
        if (widget.content.isNotEmpty)
          SizeTransition(
            sizeFactor: animation,
            axisAlignment: 1.0,
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Text(widget.content),
              ),
            ),
          ),
      ],
    );
  }
}
