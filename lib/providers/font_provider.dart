import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'business_profile_provider.dart';

class FontProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  BusinessProfileProvider? _profileProvider;
  
  bool _isLargeFont = false;

  bool get isLargeFont => _isLargeFont;

  double get fontSize => _isLargeFont ? 18.0 : 14.0;

  FontProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null && _profileProvider != null) {
        _loadFontFromProfile();
      } else {
        _isLargeFont = false;
        notifyListeners();
      }
    });
  }

  void setProfileProvider(BusinessProfileProvider provider) {
    _profileProvider = provider;
    _loadFontFromProfile();
    // Listen to profile changes
    provider.addListener(_loadFontFromProfile);
  }

  Future<void> _loadFontFromProfile() async {
    if (_profileProvider == null) {
      _isLargeFont = false;
      notifyListeners();
      return;
    }

    _isLargeFont = _profileProvider!.isLargeFont;
    notifyListeners();
  }

  void toggleFont(bool value) async {
    _isLargeFont = value;
    notifyListeners();
    
    // Save to Firestore via BusinessProfileProvider
    if (_profileProvider != null && _auth.currentUser != null) {
      try {
        await _profileProvider!.updateFont(value);
      } catch (e) {
        debugPrint('Error saving font: $e');
        // Revert on error
        _isLargeFont = !value;
        notifyListeners();
      }
    }
  }
}
