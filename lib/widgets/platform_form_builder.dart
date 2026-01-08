import "package:certimate/extension/index.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_polygon_input_border/flutter_polygon_input_border.dart";
import "package:form_builder_cupertino_fields/form_builder_cupertino_fields.dart";
import "package:form_builder_validators/form_builder_validators.dart";

class PlatformFormBuilderSectionData {
  final bool? insetGrouped;

  final AutovalidateMode? validateMode;

  PlatformFormBuilderSectionData({this.insetGrouped, this.validateMode});
}

class PlatformFormBuilderSectionInherited extends InheritedWidget {
  final PlatformFormBuilderSectionData data;

  const PlatformFormBuilderSectionInherited({
    super.key,
    required super.child,
    required this.data,
  });

  static PlatformFormBuilderSectionData? of(BuildContext context) {
    final PlatformFormBuilderSectionInherited? query = context
        .dependOnInheritedWidgetOfExactType<
          PlatformFormBuilderSectionInherited
        >();
    if (query != null) {
      return query.data;
    }
    return null;
  }

  @override
  bool updateShouldNotify(
    covariant PlatformFormBuilderSectionInherited oldWidget,
  ) {
    return oldWidget.data != data;
  }
}

class PlatformFormBuilderSection extends StatelessWidget {
  final List<Widget> children;

  final EdgeInsetsGeometry margin;

  final AutovalidateMode? validateMode;

  // only cupertino
  final bool insetGrouped;

  const PlatformFormBuilderSection({
    super.key,
    this.children = const [],
    this.margin = EdgeInsets.zero,
    this.insetGrouped = true,
    this.validateMode = AutovalidateMode.onUnfocus,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, _) => _buildMaterial(),
      cupertino: (context, _) => PlatformFormBuilderSectionInherited(
        data: PlatformFormBuilderSectionData(
          insetGrouped: insetGrouped,
          validateMode: validateMode,
        ),
        child: CupertinoUserInterfaceLevel(
          // 调整颜色等级，不使用 elevated 颜色
          data: CupertinoUserInterfaceLevelData.base,
          child: !insetGrouped
              ? _buildMaterial()
              : CupertinoFormSection.insetGrouped(
                  margin: margin,
                  children: children,
                ),
        ),
      ),
    );
  }

  Widget _buildMaterial() {
    return Padding(
      padding: margin,
      child: Column(children: children),
    );
  }
}

class PlatformFormBuilderRow extends StatelessWidget {
  final Widget? title;
  final Widget? child;

  const PlatformFormBuilderRow({super.key, this.title, this.child});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, _) => _buildMaterial(null),
      cupertino: (_, _) => _buildMaterial(
        PlatformFormBuilderSectionInherited.of(context)?.insetGrouped,
      ),
    );
  }

  Widget _buildMaterial(bool? insetGrouped) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (insetGrouped != true && title != null) const SizedBox(height: 12),
        if (insetGrouped != true && title != null) title!,
        if (child != null && insetGrouped != true && title != null)
          const SizedBox(height: 12),
        if (child != null) child!,
      ],
    );
  }
}

class PlatformFormBuilderTextField<T> extends StatelessWidget {
  final Widget title;
  final String name;
  final TextEditingController? controller;
  final String? initialValue;
  final String? placeholder;
  final bool obscureText;
  final bool clear;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final Widget? prefix;
  final BoxConstraints? prefixIconConstraints;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueTransformer<String?>? valueTransformer;
  final FocusNode? focusNode;

  const PlatformFormBuilderTextField({
    super.key,
    required this.name,
    required this.title,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.obscureText = false,
    this.clear = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.valueTransformer,
    this.maxLines = 1,
    this.prefix,
    this.prefixIconConstraints,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sectionData = PlatformFormBuilderSectionInherited.of(context);
    final insetGrouped = sectionData?.insetGrouped;
    final titleWidget = insetGrouped == true
        ? title
        : DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!,
            child: title,
          );
    final hintText = placeholder ?? s.pleaseEnter("");
    final textField = PlatformWidget(
      material: (_, _) => _buildMaterial(context, sectionData, hintText),
      cupertino: (_, _) => insetGrouped == true
          ? FormBuilderCupertinoTextField(
              name: name,
              controller: controller,
              initialValue: initialValue,
              prefix: titleWidget,
              validator: validator,
              autovalidateMode: sectionData?.validateMode,
              textAlign: TextAlign.right,
              placeholder: placeholder,
              obscureText: obscureText,
              placeholderStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                color: CupertinoColors.placeholderText,
              ),
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              valueTransformer: valueTransformer,
              readOnly: readOnly,
              enabled: enabled,
              maxLines: maxLines,
              focusNode: focusNode,
            )
          : _buildMaterial(context, sectionData, hintText, cupertino: true),
    );
    return PlatformFormBuilderRow(title: titleWidget, child: textField);
  }

  Widget _buildMaterial(
    BuildContext context,
    PlatformFormBuilderSectionData? sectionData,
    String hintText, {
    bool cupertino = false,
  }) {
    InputBorder? focusedBorder;
    if (!cupertino && readOnly) {
      final theme = Theme.of(context);
      final themeBorder = theme.inputDecorationTheme.border;
      if (themeBorder != null) {
        focusedBorder = PolygonInputBorder(
          borderSide: themeBorder.borderSide.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        );
      }
    }
    return FormBuilderTextField(
      name: name,
      controller: controller,
      initialValue: initialValue,
      cursorHeight: cupertino ? 20 : null,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: sectionData?.validateMode,
      valueTransformer: valueTransformer,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        contentPadding: sectionData?.insetGrouped != true
            ? const EdgeInsets.all(6)
            : null,
        prefixIcon: prefix,
        prefixIconConstraints: prefixIconConstraints,
        hintText: hintText,
        focusedBorder: focusedBorder,
      ),
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      obscureText: obscureText,
      focusNode: focusNode,
    );
  }
}

class PlatformFormBuilderSwitch extends StatelessWidget {
  final String name;
  final Widget title;

  final bool? initialValue;
  final FormFieldValidator<bool>? validator;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;

  const PlatformFormBuilderSwitch({
    super.key,
    required this.name,
    required this.title,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final sectionData = PlatformFormBuilderSectionInherited.of(context);
    final insetGrouped = sectionData?.insetGrouped;
    final titleWidget = insetGrouped == true
        ? title
        : DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!,
            child: title,
          );
    return PlatformWidget(
      material: (_, _) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Stack(
          children: [
            FormBuilderSwitch(
              name: name,
              initialValue: initialValue,
              validator: validator,
              autovalidateMode: sectionData?.validateMode,
              onChanged: onChanged,
              enabled: enabled,
              title: const SizedBox(),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [titleWidget],
              ),
            ),
          ],
        ),
      ),
      cupertino: (_, _) => FormBuilderCupertinoSwitch(
        name: name,
        prefix: titleWidget,
        initialValue: initialValue,
        validator: validator,
        autovalidateMode: sectionData?.validateMode,
        onChanged: onChanged,
        enabled: enabled,
        contentPadding: insetGrouped != true
            ? const EdgeInsets.only(top: 12)
            : null,
      ),
    );
  }
}

class IntegerInputFormatter extends TextInputFormatter {
  final bool positive;

  const IntegerInputFormatter({this.positive = true});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = !positive && newValue.text == "-"
        ? "-"
        : "${int.tryParse(newValue.text) ?? ''}";
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

int? integerValueTransformer(String? value) =>
    value == null ? null : int.tryParse(value);

// https://zod.dev/api?id=emails
final zodEmailValidator = FormBuilderValidators.email(
  regex: RegExp(
    r"^(?!\.)(?!.*\.\.)([a-z0-9_'+\-.]*)[a-z0-9_+-]@([a-z0-9][a-z0-9\-]*\.)+[a-z]{2,}$",
    caseSensitive: false,
  ),
);
