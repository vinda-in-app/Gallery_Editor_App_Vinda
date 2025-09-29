import 'package:flutter/material.dart';
import 'drawing_mode.dart';

class DrawnLine {
  List<Offset> path;
  Color color;
  double width;
  DrawingMode mode;

  DrawnLine({
    required this.path,
    required this.color,
    required this.width,
    required this.mode,
  });
}
