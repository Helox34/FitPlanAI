import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress_entry.dart';

class ProgressProvider with ChangeNotifier {
  List<ProgressEntry> _weightEntries = [];
  List<ProgressEntry> _strengthEntries = [];

  List<ProgressEntry> get weightEntries => _weightEntries;
  List<ProgressEntry> get strengthEntries => _strengthEntries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  DateTime? _lastFetchTime;

  Future<void> loadProgress({double? fallbackWeight, bool force = false}) async {
    if (_isLoading) return; // Prevent multiple calls
    
    // CACHE CHECK: If not forced, data exists, and fetched recently (< 5 mins), skip.
    if (!force && _weightEntries.isNotEmpty && _lastFetchTime != null) {
      final diff = DateTime.now().difference(_lastFetchTime!);
      if (diff.inMinutes < 5) {
        debugPrint('Using cached progress data (fetched ${diff.inSeconds}s ago)');
        return;
      }
    }

    _isLoading = true;
    notifyListeners(); // Notify UI that loading started

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Load from Firestore if logged in
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weight_history')
            .orderBy('date', descending: false)
            .get();

        _weightEntries = snapshot.docs
            .map((doc) => ProgressEntry.fromJson(doc.data(), id: doc.id))
            .toList();
            
        // If Firestore is empty but we have a profile weight, backfill it
        if (_weightEntries.isEmpty && fallbackWeight != null && fallbackWeight > 0) {
            debugPrint('Backfilling weight history from profile: $fallbackWeight');
            await addWeightEntry(fallbackWeight); // This adds to Firestore too
        }

        _lastFetchTime = DateTime.now(); // Update cache time
      } else {
        // Load from SharedPreferences if guest
        await _loadLocalProgress();
      }
    } catch (e) {
      debugPrint('Error loading progress from Firestore: $e');
      // Fallback to local storage if fail
      await _loadLocalProgress(); 
    } finally {
      // Ensure loading flag is cleared even on error
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalProgress() async {
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
  }

  Future<void> addWeightEntry(double weight) async {
    final user = FirebaseAuth.instance.currentUser;
    final date = DateTime.now();
    
    if (user != null) {
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('weight_history')
            .add({
          'date': date.toIso8601String(),
          'value': weight,
          'notes': null,
        });

        final entry = ProgressEntry(id: docRef.id, date: date, value: weight);
        _weightEntries.add(entry);
      } catch (e) {
        debugPrint('Error adding weight to Firestore: $e');
        // Fallback local
        final entry = ProgressEntry(date: date, value: weight);
        _weightEntries.add(entry);
        await _saveWeightLocal();
      }
    } else {
      final entry = ProgressEntry(date: date, value: weight);
      _weightEntries.add(entry);
      await _saveWeightLocal();
    }
    
    _weightEntries.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  Future<void> addStrengthEntry(double strength) async {
    // Basic implementation for strength (similar logic needed if we want Firestore)
    final entry = ProgressEntry(date: DateTime.now(), value: strength);
    _strengthEntries.add(entry);
    _strengthEntries.sort((a, b) => a.date.compareTo(b.date));
    await _saveStrengthLocal();
    notifyListeners();
  }

  Future<void> deleteWeightEntry(int index) async {
    if (index >= 0 && index < _weightEntries.length) {
      final entry = _weightEntries[index];
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && entry.id != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('weight_history')
              .doc(entry.id)
              .delete();
        } catch (e) {
          debugPrint('Error deleting from Firestore: $e');
        }
      }

      _weightEntries.removeAt(index);
      await _saveWeightLocal(); // Also update local
      notifyListeners();
    }
  }

  Future<void> _saveWeightLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _weightEntries.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('progress_weight', list);
  }

  Future<void> _saveStrengthLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _strengthEntries.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList('progress_strength', list);
  }
}
