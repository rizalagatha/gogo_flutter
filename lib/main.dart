// lib/main.dart

import 'package:flutter/material.dart';
import 'package:gogo_flutter/core/providers/theme_provider.dart';
import 'package:gogo_flutter/core/services/notification_service.dart';
import 'package:gogo_flutter/core/theme/app_themes.dart';
import 'package:gogo_flutter/features/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await notificationService.init();
  
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final initialThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(initialThemeMode),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'GoGo App',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme, // Tema terang
          darkTheme: AppThemes.darkTheme, // Tema gelap
          themeMode: themeProvider.themeMode, // Mode tema dari provider
          home: const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
