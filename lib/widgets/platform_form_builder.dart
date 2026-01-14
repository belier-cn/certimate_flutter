import "package:certimate/extension/index.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_form_builder/flutter_form_builder.dart";
import "package:flutter_platform_widgets/flutter_platform_widgets.dart";
import "package:flutter_polygon_input_border/flutter_polygon_input_border.dart";
import "package:form_builder_cupertino_fields/form_builder_cupertino_fields.dart";
import "package:form_builder_validators/form_builder_validators.dart";
import "package:re_editor/re_editor.dart";

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
  final String? helper;
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
    this.helper,
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
              helper: helper?.isNotEmpty == true
                  ? Text(
                      helper!,
                      style: context.textTheme.bodySmall!.copyWith(
                        color: context.theme.hintColor,
                      ),
                    )
                  : null,
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
        helperText: helper?.isNotEmpty == true ? helper : null,
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

class PlatformFormBuilderCodeField extends StatefulWidget {
  final Widget title;
  final String name;

  final CodeLineEditingController? controller;

  final String? initialValue;
  final String? placeholder;

  final bool readOnly;
  final bool enabled;

  final int maxLines;
  final double? height;
  final bool wordWrap;
  final CodeEditorStyle? style;
  final CodeIndicatorBuilder? indicatorBuilder;
  final EdgeInsetsGeometry? padding;

  final FormFieldValidator<String>? validator;
  final ValueTransformer<String?>? valueTransformer;
  final FocusNode? focusNode;
  final ValueChanged<String?>? onChanged;

  const PlatformFormBuilderCodeField({
    super.key,
    required this.name,
    required this.title,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 8,
    this.height,
    this.wordWrap = false,
    this.style,
    this.indicatorBuilder,
    this.padding,
    this.validator,
    this.valueTransformer,
    this.focusNode,
    this.onChanged,
  });

  @override
  State<PlatformFormBuilderCodeField> createState() =>
      _PlatformFormBuilderCodeFieldState();
}

class _PlatformFormBuilderCodeFieldState
    extends State<PlatformFormBuilderCodeField> {
  late CodeLineEditingController _controller;
  late bool _ownsController;
  bool _syncingFromField = false;
  String? _pendingText;

  FormBuilderFieldState<FormBuilderField<String>, String>? _fieldState;

  CodeLineEditingController get _effectiveController =>
      widget.controller ?? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant PlatformFormBuilderCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      final oldController = oldWidget.controller ?? _controller;
      oldController.removeListener(_handleControllerChanged);

      if (_ownsController && oldWidget.controller == null) {
        _controller.dispose();
      }

      _initController();
      _effectiveController.addListener(_handleControllerChanged);
    }
  }

  void _initController() {
    if (widget.controller != null) {
      _ownsController = false;
      _controller = widget.controller!;
      return;
    }

    _ownsController = true;
    _controller = CodeLineEditingController.fromText(widget.initialValue);
  }

  void _handleControllerChanged() {
    if (_syncingFromField) {
      return;
    }
    final fieldState = _fieldState;
    if (fieldState == null) {
      return;
    }
    final nextValue = _effectiveController.text;
    if (fieldState.value != nextValue) {
      fieldState.didChange(nextValue);
    }
  }

  void _syncControllerText(String? value) {
    final nextText = value ?? "";
    final controller = _effectiveController;
    if (controller.text == nextText) {
      return;
    }
    if (_pendingText == nextText) {
      return;
    }
    _pendingText = nextText;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final pendingText = _pendingText;
      _pendingText = null;
      if (pendingText == null) {
        return;
      }
      final controller = _effectiveController;
      if (controller.text == pendingText) {
        return;
      }
      _syncingFromField = true;
      controller.text = pendingText;
      _syncingFromField = false;
    });
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sectionData = PlatformFormBuilderSectionInherited.of(context);
    final insetGrouped = sectionData?.insetGrouped;
    final titleWidget = insetGrouped == true
        ? widget.title
        : DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!,
            child: widget.title,
          );
    final hintText = widget.placeholder ?? s.pleaseEnter("");
    final lineHeight =
        (widget.style?.fontSize ?? 13.0) * (widget.style?.fontHeight ?? 1.4);
    final editorHeight = widget.height ?? (widget.maxLines * lineHeight + 10);

    final field = FormBuilderField<String>(
      name: widget.name,
      focusNode: widget.focusNode,
      initialValue: widget.initialValue,
      validator: widget.validator,
      autovalidateMode: sectionData?.validateMode,
      valueTransformer: widget.valueTransformer,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      builder: (formField) {
        final fieldState =
            formField
                as FormBuilderFieldState<FormBuilderField<String>, String>;
        _fieldState = fieldState;

        _syncControllerText(fieldState.value);

        final editor = SizedBox(
          height: editorHeight,
          child: CodeEditor(
            autofocus: false,
            controller: _effectiveController,
            focusNode: fieldState.effectiveFocusNode,
            hint: hintText,
            padding: widget.padding,
            style: widget.style,
            indicatorBuilder: widget.indicatorBuilder,
            readOnly: widget.readOnly || !fieldState.enabled,
            showCursorWhenReadOnly: fieldState.enabled,
            wordWrap: widget.wordWrap,
          ),
        );

        if (insetGrouped == true && context.isCupertinoStyle) {
          return CupertinoFormRow(
            prefix: titleWidget,
            error: fieldState.errorText != null
                ? Text(fieldState.errorText!)
                : null,
            child: editor,
          );
        }
        return InputDecorator(
          isFocused: fieldState.effectiveFocusNode.hasFocus,
          isEmpty: (fieldState.value ?? "").isEmpty,
          decoration: InputDecoration(
            contentPadding: insetGrouped != true
                ? const EdgeInsets.all(6)
                : EdgeInsets.zero,
            errorText: fieldState.errorText,
          ),
          child: editor,
        );
      },
    );

    return PlatformFormBuilderRow(title: titleWidget, child: field);
  }
}

class PlatformFormBuilderSwitch extends StatelessWidget {
  final String name;
  final Widget title;
  final String? helper;

  final bool? initialValue;
  final FormFieldValidator<bool>? validator;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;

  const PlatformFormBuilderSwitch({
    super.key,
    required this.name,
    required this.title,
    this.helper,
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
              decoration: InputDecoration(
                border: InputBorder.none,
                helperText: helper,
                fillColor: Colors.transparent,
              ),
            ),
            Positioned(
              top: 0,
              bottom: helper?.isNotEmpty == true ? 20 : 0,
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
        helper: helper?.isNotEmpty == true
            ? Text(
                helper!,
                style: context.textTheme.bodySmall!.copyWith(
                  color: context.theme.hintColor,
                ),
              )
            : null,
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
