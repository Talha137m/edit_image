import 'dart:ui';
import 'package:flutter/material.dart';

class MyPainter extends CustomPainter {
  List<dynamic> drawingPoints;
  MyPainter({required this.drawingPoints});
  List<Offset> offsetPoints = [];
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        // Rect rect = Rect.fromPoints(
        //     drawingPoints[i].points, drawingPoints[i + 1].points);
        // canvas.drawRect(rect, drawingPoints[i].paint);
        canvas.drawLine(drawingPoints[i].points, drawingPoints[i + 1].points,
            drawingPoints[i].paint);
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        offsetPoints.clear();
        offsetPoints.add(drawingPoints[i].points);
        offsetPoints.add(Offset(drawingPoints[i].points.dx + 0.1,
            drawingPoints[i].points.dy + 0.1));
        canvas.drawPoints(
            PointMode.points, offsetPoints, drawingPoints[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(MyPainter oldDelegate) {
    return oldDelegate.drawingPoints != drawingPoints;
  }
}

class DownPainter extends CustomPainter {
  Offset offset;
  DownPainter({required this.offset});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
        offset,
        offset,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 20);
  }

  @override
  bool shouldRepaint(DownPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(DownPainter oldDelegate) => true;
}
