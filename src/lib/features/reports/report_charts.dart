import 'dart:math';

import 'package:flutter/material.dart';

import 'reports_provider.dart';

const donutPalette = [
  Color(0xFFD32F2F),
  Color(0xFFF57C00),
  Color(0xFFFBC02D),
  Color(0xFF7B1FA2),
  Color(0xFF3949AB),
  Color(0xFF00838F),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
];

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.size = 120,
    this.strokeWidth = 16,
  });

  final List<CategoryBreakdown> segments;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DonutPainter(segments, strokeWidth)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, this.strokeWidth);

  final List<CategoryBreakdown> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    var start = -pi / 2;
    for (var i = 0; i < segments.length; i++) {
      final sweep = segments[i].fraction * 2 * pi;
      final paint = Paint()
        ..color = donutPalette[i % donutPalette.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.months,
    required this.incomeColor,
    required this.expenseColor,
    required this.labelColor,
    this.height = 130,
  });

  final List<TrendMonth> months;
  final Color incomeColor;
  final Color expenseColor;
  final Color labelColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _TrendPainter(months, incomeColor, expenseColor, labelColor),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.months, this.incomeColor, this.expenseColor, this.labelColor);

  final List<TrendMonth> months;
  final Color incomeColor;
  final Color expenseColor;
  final Color labelColor;

  static const _barW = 14.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;
    final maxVal = months
        .expand((m) => [m.income, m.expense])
        .fold<double>(1, (p, v) => v > p ? v : p);
    final n = months.length;
    final groupW = size.width / n;
    final maxH = size.height - 24;
    final baseY = size.height - 20;

    final incomePaint = Paint()..color = incomeColor;
    final expensePaint = Paint()..color = expenseColor;

    for (var i = 0; i < n; i++) {
      final m = months[i];
      final hIncome = maxVal > 0 ? (m.income / maxVal) * maxH : 0.0;
      final hExpense = maxVal > 0 ? (m.expense / maxVal) * maxH : 0.0;
      final xIncome = i * groupW + (groupW - (2 * _barW + _gap)) / 2;
      final xExpense = xIncome + _barW + _gap;

      _drawBar(canvas, incomePaint, xIncome, baseY - hIncome, hIncome);
      _drawBar(canvas, expensePaint, xExpense, baseY - hExpense, hExpense);

      final tp = TextPainter(
        text: TextSpan(
          text: m.label,
          style: TextStyle(fontSize: 9, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(i * groupW + groupW / 2 - tp.width / 2, size.height - 14),
      );
    }
  }

  void _drawBar(Canvas canvas, Paint paint, double x, double y, double h) {
    if (h <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, _barW, h),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
