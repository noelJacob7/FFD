import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MetricsCharts {
  // 1. Helper to create consistent line styling
  static LineChartBarData createBarData(List<FlSpot> spots, Color color, bool isAllSelected) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      barWidth: 3,
      color: color,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: !isAllSelected, // Hide glow in "All" view to prevent clutter
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  // 2. The Main Chart Builder (For Accuracy/PR-AUC)
  static Widget buildChart(String title, List<FlSpot> spots, int numRounds, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 350,
            child: LineChart(
              LineChartData(
                minX: 1, maxX: numRounds.toDouble(), minY: 0, maxY: 1.0,
                gridData: _getGridData(),
                borderData: _getBorderData(),
                titlesData: _getTitlesData(),
                lineBarsData: [createBarData(spots, color, false)],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    );
  }

  // 3. The Combined Chart Builder (For the Selector)
  static Widget buildCombinedChart(int numRounds, String selectedSegment, Map<String, List<FlSpot>> otherMetrics) {
    List<LineChartBarData> linesToShow = [];
    bool isAll = selectedSegment == 'All';

    if (isAll) {
      linesToShow = [
        createBarData(otherMetrics["Recall"]!, Colors.purple, true),
        createBarData(otherMetrics["Precision"]!, Colors.orange, true),
        createBarData(otherMetrics["F1 Score"]!, Colors.pinkAccent, true),
      ];
    } else {
      Color color = selectedSegment == "Precision" ? Colors.orange : (selectedSegment == "Recall" ? Colors.purple : Colors.pinkAccent);
      linesToShow = [createBarData(otherMetrics[selectedSegment]!, color, false)];
    }

    return Container(
      height: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minX: 1, maxX: numRounds.toDouble(), minY: 0, maxY: 1.0,
                gridData: _getGridData(),
                borderData: _getBorderData(),
                titlesData: _getTitlesData(),
                lineBarsData: linesToShow,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(getTooltipColor: (spot) => Colors.blueGrey[900]!),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(selectedSegment, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
          buildLegend(selectedSegment),
        ],
      ),
    );
  }

  // --- Private UI Components to keep code clean ---

  static FlGridData _getGridData() => FlGridData(
    show: true,
    getDrawingHorizontalLine: (val) => FlLine(color: Colors.white10, strokeWidth: 1),
    getDrawingVerticalLine: (val) => FlLine(color: Colors.white10, strokeWidth: 1),
  );

  static FlBorderData _getBorderData() => FlBorderData(show: true, border: Border.all(color: Colors.white24));

  static FlTitlesData _getTitlesData() => FlTitlesData(
    show: true,
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true, interval: 0.1, reservedSize: 25,
        getTitlesWidget: (val, meta) => SideTitleWidget(meta: meta, child: Text(val.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 10))),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true, interval: 1,
        getTitlesWidget: (val, meta) => SideTitleWidget(meta: meta, child: Text(val.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 10))),
      ),
    ),
  );

  static Widget buildLegend(String selectedSegment) {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _legendItem("Recall", Colors.purple, selectedSegment == 'All' || selectedSegment == 'Recall'),
        _legendItem("Precision", Colors.orange, selectedSegment == 'All' || selectedSegment == 'Precision'),
        _legendItem("F1 Score", Colors.pinkAccent, selectedSegment == 'All' || selectedSegment == 'F1 Score'),
      ],
    );
  }

  static Widget _legendItem(String label, Color color, bool isActive) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }
}