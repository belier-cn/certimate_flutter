import "package:certimate/theme/theme.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";

extension NoneIconExt on IconData {
  IconData none(bool none) =>
      none ? const IconData(0x0020, fontFamily: "MaterialIcons") : this;
}

extension ThemeExt on ThemeData {
  AppThemeData get appTheme => extension<AppThemeData>()!;
}

extension AppIconsExt on BuildContext {
  AppIcons get appIcons => AppIcons(this);

  IconData platformIcon({
    required IconData material,
    required IconData cupertino,
  }) => isMaterial(this) ? material : cupertino;
}

extension PlatformAppBarExt on PlatformAppBar {
  PreferredSizeWidget getAppBar(BuildContext context) {
    return isCupertino(context)
        ? createCupertinoWidget(context)
        : createMaterialWidget(context);
  }
}

class AppIcons {
  AppIcons(this.context);

  final BuildContext context;

  IconData get ellipsis =>
      isMaterial(context) ? Icons.more_horiz : CupertinoIcons.ellipsis;

  IconData get add => isMaterial(context) ? Icons.add : CupertinoIcons.add;

  IconData get delete =>
      isMaterial(context) ? TablerIcons.trash : CupertinoIcons.trash;

  IconData get edit =>
      isMaterial(context) ? TablerIcons.edit : CupertinoIcons.create;

  IconData get info => isMaterial(context)
      ? TablerIcons.info_circle
      : CupertinoIcons.info_circle;

  IconData get copy =>
      isMaterial(context) ? TablerIcons.copy : CupertinoIcons.square_on_square;

  IconData get user =>
      isMaterial(context) ? TablerIcons.user_shield : CupertinoIcons.person;

  IconData get password =>
      isMaterial(context) ? TablerIcons.lock : CupertinoIcons.lock;

  IconData get log =>
      isMaterial(context) ? TablerIcons.clock_hour_3 : CupertinoIcons.clock;

  IconData get run =>
      isMaterial(context) ? TablerIcons.player_play : CupertinoIcons.play_arrow;

  IconData get pause => isMaterial(context)
      ? TablerIcons.player_pause
      : CupertinoIcons.pause_circle;

  IconData get workflow =>
      isMaterial(context) ? TablerIcons.hierarchy_3 : CupertinoIcons.cube_box;

  IconData get certificate => isMaterial(context)
      ? TablerIcons.certificate
      : CupertinoIcons.lock_shield;

  IconData get settings =>
      isMaterial(context) ? TablerIcons.settings : CupertinoIcons.settings;

  IconData get template => isMaterial(context)
      ? TablerIcons.code_dots
      : CupertinoIcons.chevron_left_slash_chevron_right;

  IconData get credential => isMaterial(context)
      ? TablerIcons.fingerprint
      : CupertinoIcons.checkmark_shield;

  IconData get filter => isMaterial(context)
      ? TablerIcons.filter_2
      : CupertinoIcons.line_horizontal_3_decrease;

  IconData get persistence => isMaterial(context)
      ? TablerIcons.database_cog
      : CupertinoIcons.layers_alt;

  IconData get diagnostic => isMaterial(context)
      ? TablerIcons.brackets_angle
      : CupertinoIcons.chevron_up_chevron_down;

  IconData get bell =>
      isMaterial(context) ? TablerIcons.bell : CupertinoIcons.bell;

  IconData get world =>
      isMaterial(context) ? TablerIcons.world : CupertinoIcons.globe;

  IconData get revoke => isMaterial(context)
      ? TablerIcons.shield_cancel
      : CupertinoIcons.xmark_shield;

  IconData get workflowFailed =>
      isMaterial(context) ? Icons.cancel : CupertinoIcons.clear_thick_circled;

  IconData get workflowSucceeded => isMaterial(context)
      ? Icons.check_circle
      : CupertinoIcons.check_mark_circled_solid;

  IconData get workflowCancel => isMaterial(context)
      ? Icons.info_outline
      : CupertinoIcons.exclamationmark_circle;

  IconData get workflowProcessing => isMaterial(context)
      ? Icons.play_circle_outline
      : CupertinoIcons.play_circle;

  IconData get workflowPending => isMaterial(context)
      ? Icons.pause_circle_outline
      : CupertinoIcons.pause_circle;

  IconData get sortAsc =>
      isMaterial(context) ? TablerIcons.chevron_up : CupertinoIcons.chevron_up;

  IconData get sortDesc => isMaterial(context)
      ? TablerIcons.chevron_down
      : CupertinoIcons.chevron_down;

  IconData get arrowRight =>
      isMaterial(context) ? Icons.chevron_right : CupertinoIcons.right_chevron;

  IconData get back =>
      isMaterial(context) ? Icons.arrow_back : CupertinoIcons.back;

  IconData get close =>
      isMaterial(context) ? Icons.close : CupertinoIcons.clear;

  IconData get share =>
      isMaterial(context) ? TablerIcons.share_2 : CupertinoIcons.share;
}
