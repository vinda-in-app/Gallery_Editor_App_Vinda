import 'package:flutter/material.dart';

class TextElement {
  final String id;
  String text;
  Offset position;
  TextStyle style;

  TextElement({
    required this.id,
    required this.text,
    required this.position,
    required this.style,
  });

  void updateFontSize(double size) {
    style = style.copyWith(fontSize: size);
  }

  void updateColor(Color color) {
    style = style.copyWith(color: color);
  }
}
