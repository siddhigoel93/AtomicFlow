// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'heatmap_painter.dart';

class HeatmapWidget extends StatelessWidget {
  /// Map from midnight-normalized DateTime → completed (true) or missed (false).
  /// Dates absent from the map are treated as no data (empty cell).
  final Map<DateTime, bool> data;

  /// Habit accent color — drives both the active cell and the legend.
  final Color color;

  /// How many weeks to show (columns). Default 18 ≈ 4 months.
  final int weeks;

  const HeatmapWidget({
    super.key,
    required this.data,
    required this.color,
    this.weeks = 18,
  });

  static const double _cellSize = 13.0;
  static const double _cellGap = 3.0;
  static const double _stride = _cellSize + _cellGap;
  static const double _labelHeight = 20.0;
  static const double _labelWidth = 24.0;

  static const _dayLabels = ['M', '', 'W', '', 'F', '', 'S'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = color;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final emptyColor = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.black.withOpacity(0.03);

    final gridWidth = weeks * _stride - _cellGap;
    final gridHeight = 7 * _stride - _cellGap;
    final totalWidth = _labelWidth + gridWidth;
    final totalHeight = _labelHeight + gridHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable heatmap + day labels
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // newest week always visible on the right
          child: SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              children: [
                // Month labels along top
                Positioned(
                  left: _labelWidth,
                  top: 0,
                  width: gridWidth,
                  height: _labelHeight,
                  child: _MonthLabels(
                    weeks: weeks,
                    stride: _stride,
                    textStyle: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .color!
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                // Day-of-week labels on the left
                Positioned(
                  left: 0,
                  top: _labelHeight,
                  width: _labelWidth,
                  height: gridHeight,
                  child: _DayLabels(
                    labels: _dayLabels,
                    stride: _stride,
                    cellSize: _cellSize,
                    textStyle: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .color!
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                // The heatmap grid
                Positioned(
                  left: _labelWidth,
                  top: _labelHeight,
                  width: gridWidth,
                  height: gridHeight,
                  child: CustomPaint(
                    size: Size(gridWidth, gridHeight),
                    painter: HeatmapPainter(
                      completionData: data,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      emptyColor: emptyColor,
                      cellSize: _cellSize,
                      cellGap: _cellGap,
                      weeks: weeks,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend row
        _Legend(
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          emptyColor: emptyColor,
          cellSize: _cellSize,
          cellRadius: _cellSize * 0.22,
        ),
      ],
    );
  }
}

// ── Month labels ──────────────────────────────────────────────────────────────

class _MonthLabels extends StatelessWidget {
  final int weeks;
  final double stride;
  final TextStyle textStyle;

  const _MonthLabels({
    required this.weeks,
    required this.stride,
    required this.textStyle,
  });

  static DateTime _normalize(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  Widget build(BuildContext context) {
    final today = _normalize(DateTime.now());
    final daysBack = (weeks - 1) * 7 + (today.weekday - 1);
    final start = today.subtract(Duration(days: daysBack));

    final labels = <Widget>[];
    int? lastMonth;

    for (int col = 0; col < weeks; col++) {
      final date = start.add(Duration(days: col * 7));
      if (date.month != lastMonth) {
        lastMonth = date.month;
        labels.add(Positioned(
          left: col * stride,
          top: 0,
          child: Text(_monthAbbr(date.month), style: textStyle),
        ));
      }
    }

    return Stack(children: labels);
  }

  String _monthAbbr(int month) {
    const abbrs = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return abbrs[month];
  }
}

// ── Day-of-week labels ────────────────────────────────────────────────────────

class _DayLabels extends StatelessWidget {
  final List<String> labels;
  final double stride;
  final double cellSize;
  final TextStyle textStyle;

  const _DayLabels({
    required this.labels,
    required this.stride,
    required this.cellSize,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) => SizedBox(
        height: stride,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(labels[i], style: textStyle),
          ),
        ),
      )),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final Color activeColor;
  final Color inactiveColor;
  final Color emptyColor;
  final double cellSize;
  final double cellRadius;

  const _Legend({
    required this.activeColor,
    required this.inactiveColor,
    required this.emptyColor,
    required this.cellSize,
    required this.cellRadius,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 11,
      color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.5),
    );

    return Row(
      children: [
        _cell(emptyColor, cellRadius),
        const SizedBox(width: 4),
        Text('No data', style: labelStyle),
        const SizedBox(width: 12),
        _cell(inactiveColor, cellRadius),
        const SizedBox(width: 4),
        Text('Missed', style: labelStyle),
        const SizedBox(width: 12),
        _cell(activeColor, cellRadius),
        const SizedBox(width: 4),
        Text('Done', style: labelStyle),
      ],
    );
  }

  Widget _cell(Color color, double radius) => Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
