import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'cv_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => CVProvider(),
      child: const EzzeCVApp(),
    ),
  );
}

class EzzeCVApp extends StatelessWidget {
  const EzzeCVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}