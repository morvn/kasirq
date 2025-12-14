class BusinessProfile {
  final String? id;
  final String userId; // ID dari Firebase Auth
  final String namaUsaha;
  final String alamatUsaha;
  final String kontakUsaha;
  // logoPath: null = gunakan foto Google, string = path lokal
  final String? logoPath; // Path lokal jika user mengubah logo
  final String? qrisPath; // Path lokal untuk QRIS
  final double diskonPersen;
  final double ppnPersen;
  final bool isDarkTheme; // Preferensi tema gelap
  final bool isLargeFont; // Preferensi ukuran font besar
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessProfile({
    this.id,
    required this.userId,
    required this.namaUsaha,
    required this.alamatUsaha,
    required this.kontakUsaha,
    this.logoPath,
    this.qrisPath,
    this.diskonPersen = 0.0,
    this.ppnPersen = 0.0,
    this.isDarkTheme = false,
    this.isLargeFont = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  // Note: logoPath dan qrisPath tidak disimpan di Firestore, hanya di SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'namaUsaha': namaUsaha,
      'alamatUsaha': alamatUsaha,
      'kontakUsaha': kontakUsaha,
      'diskonPersen': diskonPersen,
      'ppnPersen': ppnPersen,
      'isDarkTheme': isDarkTheme,
      'isLargeFont': isLargeFont,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory BusinessProfile.fromMap(String id, Map<String, dynamic> map) {
    return BusinessProfile(
      id: id,
      userId: map['userId'] ?? '',
      namaUsaha: map['namaUsaha'] ?? '',
      alamatUsaha: map['alamatUsaha'] ?? '',
      kontakUsaha: map['kontakUsaha'] ?? '',
      // logoPath dan qrisPath tidak disimpan di Firestore
      logoPath: null,
      qrisPath: null,
      diskonPersen: (map['diskonPersen'] ?? 0.0).toDouble(),
      ppnPersen: (map['ppnPersen'] ?? 0.0).toDouble(),
      isDarkTheme: map['isDarkTheme'] ?? false,
      isLargeFont: map['isLargeFont'] ?? false,
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Create a copy with updated fields
  BusinessProfile copyWith({
    String? id,
    String? userId,
    String? namaUsaha,
    String? alamatUsaha,
    String? kontakUsaha,
    String? logoPath,
    String? qrisPath,
    double? diskonPersen,
    double? ppnPersen,
    bool? isDarkTheme,
    bool? isLargeFont,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      namaUsaha: namaUsaha ?? this.namaUsaha,
      alamatUsaha: alamatUsaha ?? this.alamatUsaha,
      kontakUsaha: kontakUsaha ?? this.kontakUsaha,
      logoPath: logoPath ?? this.logoPath,
      qrisPath: qrisPath ?? this.qrisPath,
      diskonPersen: diskonPersen ?? this.diskonPersen,
      ppnPersen: ppnPersen ?? this.ppnPersen,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isLargeFont: isLargeFont ?? this.isLargeFont,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
