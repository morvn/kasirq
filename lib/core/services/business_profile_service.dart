import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/business_profile.dart';

class BusinessProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection name
  static const String _collectionName = 'business_profiles';

  // Get business profile by user ID
  Future<BusinessProfile?> getProfileByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return BusinessProfile.fromMap(doc.id, doc.data());
    } catch (e) {
      throw Exception('Gagal mengambil profil usaha: $e');
    }
  }

  // Create or update business profile
  Future<BusinessProfile> saveProfile(BusinessProfile profile) async {
    try {
      final now = DateTime.now();
      final profileToSave = profile.copyWith(
        updatedAt: now,
        createdAt: profile.id == null ? now : profile.createdAt,
      );

      // Hanya simpan data ke Firestore, logoPath dan qrisPath disimpan lokal
      final dataToSave = profileToSave.toMap();
      // logoPath dan qrisPath sudah tidak ada di toMap, jadi tidak perlu dihapus

      if (profile.id == null) {
        // Create new profile
        final docRef = await _firestore
            .collection(_collectionName)
            .add(dataToSave);
        return profileToSave.copyWith(id: docRef.id);
      } else {
        // Update existing profile
        await _firestore
            .collection(_collectionName)
            .doc(profile.id)
            .update(dataToSave);
        return profileToSave;
      }
    } catch (e) {
      throw Exception('Gagal menyimpan profil usaha: $e');
    }
  }

  // Delete business profile
  Future<void> deleteProfile(String profileId) async {
    try {
      await _firestore.collection(_collectionName).doc(profileId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus profil usaha: $e');
    }
  }
}
