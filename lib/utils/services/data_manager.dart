class SequenceData {
  final String id; // e.g., "sequence_42"
  final List<dynamic> features; 
  final int label;

  SequenceData({
    required this.id,
    required this.features,
    required this.label,
  });

  // Factory constructor to easily build this object from JSON
  factory SequenceData.fromJson(String id, Map<String, dynamic> json) {
    return SequenceData(
      id: id,
      // features will be a List<dynamic>. If it's a 2D array (e.g., for LSTMs), 
      // it handles nested lists automatically.
      features: json['features'] as List<dynamic>,
      label: json['label'] as int,
    );
  }
}

class EvaluationMetrics {
  final double accuracy;
  final double precision;
  final double recall;
  final double f1Score;
  final double prAuc;

  EvaluationMetrics({
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.prAuc,
  });

  factory EvaluationMetrics.fromJson(Map<String, dynamic> json) {
    return EvaluationMetrics(
      accuracy: (json['Accuracy'] ?? 0).toDouble(),
      precision: (json['Precision'] ?? 0).toDouble(),
      recall: (json['Recall'] ?? 0).toDouble(),
      f1Score: (json['F1 Score'] ?? 0).toDouble(),
      prAuc: (json['PR_AUC'] ?? 0).toDouble(),
    );
  }

  // Add this to convert class data to the Map format for the charts
  Map<String, double> toMap() {
    return {
      "Accuracy": accuracy,
      "Precision": precision,
      "Recall": recall,
      "F1 Score": f1Score,
      // You can add prAuc here if you update your titles list in the chart
    };
  }
}