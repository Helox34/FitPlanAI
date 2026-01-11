import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_entry.dart';

class ProgressProvider with ChangeNotifier {
  List<ProgressEntry> _weightEntries = [];
  List<ProgressEntry> _strengthEntries = [];

  List<ProgressEntry> get weightEntries => _weightEntries;
  List<ProgressEntry> get strengthEntries => _strengthEntries;

  // Check if we need to prompt the user (if > 7 days since last entry)
  bool get shouldPromptWeight {
    if (_weightEntries.isEmpty) return true;
    final lastDate = _weightEntries.last.date;
    return DateTime.now().difference(lastDate).inDays >= 7;
  }

  bool get shouldPromptStrength {
    if (_strengthEntries.isEmpty) return true;
    final lastDate = _strengthEntries.last.date;
    return DateTime.now().difference(lastDate).inDays >= 7;
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    final weightJson = prefs.getStringList('progress_weight') ?? [];
    _weightEntries = weightJson
        .map((e) => ProgressEntry.fromJson(json.decode(e)))
        .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

    final strengthJson = prefs.getStringList('progress_strength') ?? [];
    _strengthEntries = strengthJson
        .map((e) => ProgressEntry.fromJson(json.decode(e)))
        .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

    notifyListeners();
  }

  Future<void> addWeightEntry(double weight) async {
    final entry = ProgressEntry(date: DateTime.now(), value: weight);
    _weightEntries.add(entry);
    _weightEntries.sort((a, b) => a.date.compareTo(b.date));
    await _saveWeight();
    notifyListeners();
  }

  Future<void> addStrengthEntry(double strength) async {
    final entry = ProgressEntry(date: DateTime.now(), value: strength);
    _strengthEntries.add(entry);
    _strengthEntries.sort((a, b) => a.date.compareTo(b.date));
    await _saveStrength();
    notifyListeners();
  }

  Future<void> _saveWeight() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _weightEntries.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('progress_weight', list);
  }

  Future<void> _saveStrength() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _strengthEntries.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('progress_strength', list);
  }
}
