// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/font_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/business_profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProfileProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
      ],
      child: const KasirApp(),
    ),
  );
}

class KasirApp extends StatefulWidget {
  const KasirApp({super.key});

  @override
  State<KasirApp> createState() => _KasirAppState();
}

class _KasirAppState extends State<KasirApp> {
  bool _providersConnected = false;

  @override
  void initState() {
    super.initState();
    // Setup providers connection setelah user login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectProviders();
    });
  }

  void _connectProviders() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated && !_providersConnected) {
      final businessProfileProvider = context.read<BusinessProfileProvider>();
      final themeProvider = context.read<ThemeProvider>();
      final fontProvider = context.read<FontProvider>();

      themeProvider.setProfileProvider(businessProfileProvider);
      fontProvider.setProfileProvider(businessProfileProvider);
      setState(() => _providersConnected = true);
    } else if (!authProvider.isAuthenticated) {
      setState(() => _providersConnected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconnect jika auth state berubah
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isAuthenticated != _providersConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connectProviders();
      });
    }

    final themeMode = context.watch<ThemeProvider>().currentTheme;
    final isLargeFont = context.watch<FontProvider>().isLargeFont;

    return MaterialApp(
      title: 'KasirQ',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scrollBehavior: const _AppScrollBehavior(),
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(isLargeFont ? 1.3 : 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthWrapper(),
    );
  }
}

/// Widget wrapper untuk mengecek status autentikasi
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isAuthenticated) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}

/// Scroll glow dihilangkan
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Widget buildOverscrollIndicator(context, child, details) => child;
}

ThemeData _buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1565C0),
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
  );
}

ThemeData _buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1565C0), // biru utama
    brightness: Brightness.dark,
  ).copyWith(
    surface: const Color(0xFF121212), // background utama
    surfaceContainerHigh: const Color.fromARGB(255, 40, 40, 40), // card
    onSurface: Colors.white, // teks utama
    onSurfaceVariant: Colors.grey, // teks sekunder
    primary: const Color(0xFF2196F3), // aksen biru cerah
    tertiary: const Color(0xFF64B5F6), // biru terang untuk harga
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: const CardThemeData(
      color: Color.fromARGB(255, 40, 40, 40), // konsisten card di dark mode
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.grey),
    ),
  );
}
