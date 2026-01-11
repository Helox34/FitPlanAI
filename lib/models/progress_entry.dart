class ProgressEntry {
  final DateTime date;
  final double value;
  final String? notes;

  ProgressEntry({
    required this.date,
    required this.value,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'notes': notes,
    };
  }

  factory ProgressEntry.fromJson(Map<String, dynamic> json) {
    return ProgressEntry(
      date: DateTime.parse(json['date']),
      value: json['value'],
      notes: json['notes'],
    );
  }
}
