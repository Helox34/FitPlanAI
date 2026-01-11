class ProgressEntry {
  final String? id; // Firestore Document ID
  final DateTime date;
  final double value;
  final String? notes;

  ProgressEntry({
    this.id,
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

  factory ProgressEntry.fromJson(Map<String, dynamic> json, {String? id}) {
    return ProgressEntry(
      id: id,
      date: DateTime.parse(json['date']),
      value: json['value'],
      notes: json['notes'],
    );
  }
}
