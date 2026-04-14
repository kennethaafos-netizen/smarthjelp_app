import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ NY

import 'providers/app_state.dart';
import 'widgets/app_shell.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 FIREBASE INIT (BEHOLDES)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // 🔔 Push permission
  await FirebaseMessaging.instance.requestPermission();

  // 🚀 SUPABASE INIT (NYTT)
  await Supabase.initialize(
    // 🔥 LIM INN HER:
    url: 'https://yuzjubqzngsjzwfrucxg.supabase.co',
    
    // 🔥 LIM INN HER:
    anonKey: 'sb_publishable_PzzcCP5I-vD1bm-XaoNYlA_1veFC31d',
  );

  runApp(const SmartHjelpApp());
}

class SmartHjelpApp extends StatelessWidget {
  const SmartHjelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartHjelp',

        // 🔥 GLOBAL THEME
        theme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A8BFF),
            primary: const Color(0xFF4A8BFF),
            secondary: const Color(0xFF2ED3C6),
          ),

          scaffoldBackgroundColor: const Color(0xFFF6F8FC),

          textTheme: GoogleFonts.interTextTheme(),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFF4A8BFF),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFF4A8BFF),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(color: Color(0xFF4A8BFF)),
              foregroundColor: const Color(0xFF4A8BFF),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),

          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black,
            centerTitle: false,
          ),
        ),

        home: const AppShell(),
      ),
    );
  }
}