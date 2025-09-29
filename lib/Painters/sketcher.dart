import 'package:flutter/material.dart';
import '../Models/drawn_line.dart';
import '../Models/text_element.dart';

class Sketcher extends CustomPainter {
  final List<DrawnLine> lines;
  final List<TextElement> texts;

  Sketcher({required this.lines, required this.texts});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Gambar semua garis
    for (var line in lines) {
      paint
        ..color = line.color
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;

      if (line.path.length > 1) {
        final path = Path()..moveTo(line.path.first.dx, line.path.first.dy);
        for (int i = 1; i < line.path.length; i++) {
          path.lineTo(line.path[i].dx, line.path[i].dy);
        }
        canvas.drawPath(path, paint);
      } else if (line.path.isNotEmpty) {
        canvas.drawCircle(line.path.first, line.width / 2, paint);
      }
    }

    // Gambar semua teks
    for (var textElement in texts) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: textElement.text,
          style: textElement.style,
        ),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, textElement.position);
    }
  }

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.lines != lines || oldDelegate.texts != texts;
  }
}
