import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/home_screen.dart';

bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await initializeDateFormatting('ru_RU', null);
  runApp(const DecoratorApp());
}

// ─── Luxury palette ───────────────────────────────────────────────────────────
const kBackground = Color(0xFFF7F4EF);  // Тёплое молоко
const kSurface    = Color(0xFFEDE8E0);  // Бежевый песок
const kGold       = Color(0xFFC8B08A);  // Шампань золото
const kBronze     = Color(0xFF9A7B5F);  // Акцентный бронзовый
const kGraphite   = Color(0xFF2D2D2D);  // Графитовый
const kGoldLight  = Color(0xFFF0E6D3);  // Светлое золото (чипсы, фоны)
const kBrand      = kBronze;            // Основной бренд-цвет
const kNavDark    = Color(0xFF2D2D2D);  // Боковая панель на десктопе

class DecoratorApp extends StatelessWidget {
  const DecoratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: kBronze,
      onPrimary: Colors.white,
      primaryContainer: kGoldLight,
      onPrimaryContainer: kGraphite,
      secondary: kGold,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF5EDE0),
      onSecondaryContainer: kGraphite,
      tertiary: const Color(0xFF7C9B8A),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFDDF0E7),
      onTertiaryContainer: kGraphite,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: kBackground,
      onSurface: kGraphite,
      surfaceContainerHighest: kSurface,
      outline: const Color(0xFFD4C8B8),
      outlineVariant: const Color(0xFFE8E0D5),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: kGraphite,
      onInverseSurface: kBackground,
      inversePrimary: kGoldLight,
    );

    return MaterialApp(
      title: 'Декоратор',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU')],
      locale: const Locale('ru', 'RU'),
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackground,
          foregroundColor: kGraphite,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: kGraphite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: kGraphite),
          actionsIconTheme: IconThemeData(color: kGraphite),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kGoldLight,
          elevation: 0,
          shadowColor: Colors.black12,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? kBronze : const Color(0xFF9E9585),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? kBronze : const Color(0xFFAFA395),
              size: 22,
            );
          }),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEEE8DF), width: 1),
          ),
          margin: EdgeInsets.zero,
          shadowColor: const Color(0x14000000),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDD6CC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDD6CC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kBronze, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          isDense: true,
          hintStyle: const TextStyle(color: Color(0xFFB8AFA5)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBronze,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kBronze,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kBronze,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: kGoldLight,
          selectedColor: kBronze,
          labelStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEEE8DF),
          thickness: 1,
          space: 1,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: kBronze,
          unselectedLabelColor: const Color(0xFF9E9585),
          indicatorColor: kBronze,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          dividerColor: const Color(0xFFEEE8DF),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
