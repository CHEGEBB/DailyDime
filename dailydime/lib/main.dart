// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dailydime/screens/splash_screen.dart';
import 'package:dailydime/services/theme_service.dart';
import 'package:dailydime/services/app_notification_service.dart';
import 'package:dailydime/services/tools_service.dart'; // ADD THIS IMPORT
import 'package:dailydime/providers/transaction_provider.dart';
import 'package:dailydime/providers/budget_provider.dart'; 
import 'package:dailydime/providers/savings_provider.dart';
import 'package:dailydime/providers/insight_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme service - should be first so other providers can use it
        ChangeNotifierProvider(
          create: (context) => ThemeService(),
        ),
        // Notification service
        ChangeNotifierProvider(
          create: (context) => AppNotificationService(),
        ),
        // ADD THIS PROVIDER FOR TOOLS SERVICE
        ChangeNotifierProvider(
          create: (context) => ToolsService(),
        ),
        // Transaction provider
        ChangeNotifierProvider(
          create: (context) => TransactionProvider(),
        ),
        // Budget provider
        ChangeNotifierProvider(
          create: (context) => BudgetProvider(),
        ),
        // Savings provider
        ChangeNotifierProvider(
          create: (context) => SavingsProvider(),
        ),
        // Insight provider
        ChangeNotifierProvider(
          create: (context) => InsightProvider(),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'DailyDime',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme.copyWith(
              textTheme: themeService.lightTheme.textTheme.apply(fontFamily: 'DMsans'),
            ),
            darkTheme: themeService.darkTheme.copyWith(
              textTheme: themeService.darkTheme.textTheme.apply(fontFamily: 'DMsans'),
            ),
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            // Add these routes if you need them
            routes: {
              '/login': (context) => const SplashScreen(), // Replace with your login screen
              // Add other routes here
            },
          );
        },
      ),
    );
  }
}