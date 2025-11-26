import 'package:autovibe/screens/home_screen.dart';
import 'package:autovibe/services/scheduler_service.dart';
import 'package:autovibe/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final scheduler = SchedulerService();
  await scheduler.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoVibe',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
