import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TicketStatusChart extends StatelessWidget {
  final int openCount;
  final int closedCount;

  const TicketStatusChart({
    super.key,
    required this.openCount,
    required this.closedCount,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = [openCount, closedCount].reduce((a, b) => a > b ? a : b);
    final maxY = (maxCount + 2).toDouble();

    return SizedBox(
      height: 240, // was 200 — extra room for bottom labels
      child: BarChart(
        BarChartData(
          maxY: maxY,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36, // was 28 — enough width to avoid wrapping
                interval: 1, // force whole-number steps: 0, 1, 2, 3...
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Text(value.toInt().toString());
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32, // explicit space reserved for the labels
                getTitlesWidget: (value, meta) {
                  final label = value == 0
                      ? 'Open'
                      : (value == 1 ? 'Closed' : '');
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [BarChartRodData(toY: openCount.toDouble(), width: 40)],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(toY: closedCount.toDouble(), width: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
