import "package:flutter/material.dart";
import "package:flutter_polygon_input_border/flutter_polygon_input_border.dart";

InputBorder getPolygonInputBorder(WidgetStateInputBorder stateInputBorder) {
  return WidgetStateInputBorder.resolveWith((Set<WidgetState> states) {
    final inputBorder = stateInputBorder.resolve(states);
    return PolygonInputBorder(
      borderSide: inputBorder.borderSide.copyWith(width: 1),
      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
    );
  });
}
