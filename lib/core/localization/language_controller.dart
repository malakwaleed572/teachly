import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LanguageController extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get languageName {
    return _locale.languageCode == 'ar'
        ? 'Arabic'
        : 'English';
  }

  Future<void> loadLanguage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('app_settings')
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();

        final savedLanguage =
            data?['language'] as String?;

        if (savedLanguage == 'Arabic') {
          _locale = const Locale('ar');
        } else {
          _locale = const Locale('en');
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        'Error loading language: $e',
      );
    }
  }

  Future<void> changeLanguage(
    String language,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (language == 'Arabic') {
      _locale = const Locale('ar');
    } else {
      _locale = const Locale('en');
    }

    notifyListeners();

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('app_settings')
          .set(
        {
          'language': language,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Error saving language: $e',
      );
    }
  }
}