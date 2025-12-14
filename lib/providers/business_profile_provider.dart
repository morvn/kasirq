import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/business_profile.dart';
import '../../core/services/business_profile_service.dart';

class BusinessProfileProvider extends ChangeNotifier {
  final BusinessProfileService _service = BusinessProfileService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BusinessProfile? _profile;
  bool _isLoading = false;
  String? _error;

  BusinessProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  // Get logo URL - prioritas: path lokal > foto Google
  String? get logoUrl {
    final user = _auth.currentUser;
    if (_profile?.logoPath != null && _profile!.logoPath!.isNotEmpty) {
      // Gunakan logo lokal jika ada
      return null; // Return null untuk path lokal, akan dihandle di UI
    }
    // Gunakan foto Google sebagai default
    return user?.photoURL;
  }

  // Get logo path lokal
  String? get logoPath => _profile?.logoPath;

  // Get QRIS path lokal
  String? get qrisPath => _profile?.qrisPath;

  BusinessProfileProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadProfile();
      } else {
        clearProfile();
      }
    });
    
    // Load initial profile if user is already logged in
    if (_auth.currentUser != null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _profile = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load dari Firestore
      _profile = await _service.getProfileByUserId(user.uid);
      
      // Load logoPath dan qrisPath dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final logoPath = prefs.getString('logo_path_${user.uid}');
      final qrisPath = prefs.getString('qris_path_${user.uid}');

      if (_profile == null) {
        // Migrate dari SharedPreferences jika ada (untuk backward compatibility)
        final prefs = await SharedPreferences.getInstance();
        final oldIsDarkTheme = prefs.getBool('is_dark_theme') ?? false;
        final oldIsLargeFont = prefs.getBool('font_besar') ?? false;
        
        // Create default profile if doesn't exist
        _profile = BusinessProfile(
          userId: user.uid,
          namaUsaha: 'Usaha Saya',
          alamatUsaha: '',
          kontakUsaha: '',
          logoPath: logoPath,
          qrisPath: qrisPath,
          isDarkTheme: oldIsDarkTheme,
          isLargeFont: oldIsLargeFont,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _profile = await _service.saveProfile(_profile!);
        
        // Hapus old SharedPreferences setelah migrasi
        await prefs.remove('is_dark_theme');
        await prefs.remove('font_besar');
      } else {
        // Update dengan path lokal
        _profile = _profile!.copyWith(
          logoPath: logoPath,
          qrisPath: qrisPath,
        );
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  // Getters untuk settings
  bool get isDarkTheme => _profile?.isDarkTheme ?? false;
  bool get isLargeFont => _profile?.isLargeFont ?? false;

  Future<void> updateProfile({
    String? namaUsaha,
    String? alamatUsaha,
    String? kontakUsaha,
    double? diskonPersen,
    double? ppnPersen,
    bool? isDarkTheme,
    bool? isLargeFont,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    if (_profile == null) {
      await _loadProfile();
    }

    if (_profile == null) throw Exception('Profil tidak ditemukan');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = _profile!.copyWith(
        namaUsaha: namaUsaha ?? _profile!.namaUsaha,
        alamatUsaha: alamatUsaha ?? _profile!.alamatUsaha,
        kontakUsaha: kontakUsaha ?? _profile!.kontakUsaha,
        diskonPersen: diskonPersen ?? _profile!.diskonPersen,
        ppnPersen: ppnPersen ?? _profile!.ppnPersen,
        isDarkTheme: isDarkTheme ?? _profile!.isDarkTheme,
        isLargeFont: isLargeFont ?? _profile!.isLargeFont,
      );

      _profile = await _service.saveProfile(_profile!);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadLogo(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    if (_profile == null) {
      await _loadProfile();
    }

    if (_profile == null) throw Exception('Profil tidak ditemukan');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simpan path lokal ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logo_path_${user.uid}', imageFile.path);

      // Update profile dengan path lokal
      _profile = _profile!.copyWith(logoPath: imageFile.path);
      // Tidak perlu save ke Firestore karena logoPath disimpan lokal
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving logo: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeLogo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_profile == null) {
      await _loadProfile();
    }

    if (_profile == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Hapus dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logo_path_${user.uid}');

      // Update profile
      _profile = _profile!.copyWith(logoPath: null);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error removing logo: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadQRIS(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    if (_profile == null) {
      await _loadProfile();
    }

    if (_profile == null) throw Exception('Profil tidak ditemukan');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simpan path lokal ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('qris_path_${user.uid}', imageFile.path);

      // Update profile dengan path lokal
      _profile = _profile!.copyWith(qrisPath: imageFile.path);
      // Tidak perlu save ke Firestore karena qrisPath disimpan lokal
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving QRIS: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteQRIS() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_profile == null) {
      await _loadProfile();
    }

    if (_profile == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Hapus dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('qris_path_${user.uid}');

      // Update profile
      _profile = _profile!.copyWith(qrisPath: null);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting QRIS: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTheme(bool isDark) async {
    await updateProfile(isDarkTheme: isDark);
  }

  Future<void> updateFont(bool isLarge) async {
    await updateProfile(isLargeFont: isLarge);
  }

  void clearProfile() {
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
