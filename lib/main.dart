// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:vocab_store/app_provider.dart';
import 'package:vocab_store/app_theme.dart';
import 'package:vocab_store/auth_screen.dart';
import 'package:vocab_store/firebase_options.dart';
import 'package:vocab_store/home_screen.dart';
import 'package:vocab_store/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create:  (_) => TtsService()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const WordVaultApp(),
    ),
  );
}

class WordVaultApp extends StatelessWidget {
  const WordVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        // Initialize provider once user is known
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AppProvider>().init(user.uid);
        });

        return const HomeScreen();
      },
    );
  }
}
