import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tripspending/providers/trip_provider.dart';
import 'package:tripspending/providers/receipt_provider.dart';
import 'package:tripspending/providers/settings_provider.dart';
import 'package:tripspending/screens/home_screen.dart';
import 'package:tripspending/services/database_service.dart';
import 'package:tripspending/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database
  await DatabaseService.instance.database;
  
  runApp(const TripSpendingApp());
}

class TripSpendingApp extends StatelessWidget {
  const TripSpendingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'TripSpending',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
