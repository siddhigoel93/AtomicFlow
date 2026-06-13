// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class HeatmapPainter extends CustomPainter {
  final Map<DateTime, bool> completionData;
  final Color activeColor;
  final Color inactiveColor;
  final Color emptyColor;
  final double cellSize;
  final double cellGap;
  final int weeks; // how many columns to draw

  HeatmapPainter({
    required this.completionData,
    required this.activeColor,
    required this.inactiveColor,
    required this.emptyColor,
    required this.cellSize,
    required this.cellGap,
    required this.weeks,
  });

  // ── Geometry helpers ───────────────────────────────────────────────────────

  double get _stride => cellSize + cellGap;

  /// Top-left origin of cell at (col, row)
  Offset _cellOrigin(int col, int row) => Offset(
        col * _stride,
        row * _stride,
      );

  RRect _cellRRect(int col, int row) {
    final origin = _cellOrigin(col, row);
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, cellSize, cellSize),
      Radius.circular(cellSize * 0.22),
    );
  }

  // ── Date helpers ───────────────────────────────────────────────────────────

  /// Normalize to midnight so map lookups are consistent
  static DateTime _normalize(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Compute the first cell date: go back `weeks` columns from today,
  /// then rewind to the Monday of that week.
  DateTime _startDate(DateTime today) {
    final daysBack = (weeks - 1) * 7 + (today.weekday - 1);
    final raw = today.subtract(Duration(days: daysBack));
    return _normalize(raw);
  }

  // ── Paint ──────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final today = _normalize(DateTime.now());
    final start = _startDate(today);

    final emptyPaint = Paint()..color = emptyColor;
    final donePaint = Paint()..color = activeColor;
    final missedPaint = Paint()..color = inactiveColor;

    for (int col = 0; col < weeks; col++) {
      for (int row = 0; row < 7; row++) {
        final date = start.add(Duration(days: col * 7 + row));
        final rrect = _cellRRect(col, row);

        // Future cells: draw empty placeholder
        if (date.isAfter(today)) {
          canvas.drawRRect(rrect, emptyPaint);
          continue;
        }

        final completed = completionData[date] ?? false;

        // Today's cell: draw with subtle ring if not done
        if (date == today) {
          canvas.drawRRect(rrect, completed ? donePaint : emptyPaint);
          if (!completed) {
            canvas.drawRRect(
              rrect,
              Paint()
                ..color = activeColor.withOpacity(0.4)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5,
            );
          }
          continue;
        }

        // Past cells
        canvas.drawRRect(rrect, completed ? donePaint : missedPaint);
      }
    }
  }

  // ── shouldRepaint ──────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(HeatmapPainter old) =>
      old.completionData != completionData ||
      old.activeColor != activeColor ||
      old.weeks != weeks;
}
