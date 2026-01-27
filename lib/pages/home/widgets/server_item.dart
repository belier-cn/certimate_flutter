import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/widgets/card.dart";
import "package:flutter/material.dart";

class ServerItemWidget extends StatelessWidget {
  final ServerModel data;

  final bool selected;

  const ServerItemWidget({
    super.key,
    required this.data,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModelCard(
      child: ListTile(
        selected: selected,
        title: Text(data.displayName),
        subtitle: Text(data.host.fullHost),
        trailing: Icon(
          context.appIcons.arrowRight,
          size: context.isMaterialStyle ? 24 : 16,
        ),
      ),
    );
  }
}
