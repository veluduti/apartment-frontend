import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/repositories/request_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/resident_dashboard.dart';
import 'screens/dashboard/worker_dashboard.dart';
import 'screens/iron/app_theme.dart';

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Background Message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (_) => RequestRepository(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Apartment Ecosystem",

      // ✅ USE ENTERPRISE DESIGN SYSTEM HERE
      theme: AppTheme.lightTheme,

      // 🔥 STARTING POINT
      home: const LoginScreen(),

      routes: {
        "/residentDashboard": (context) =>
            const ResidentDashboard(),
        "/workerDashboard": (context) =>
            const WorkerDashboard(),
      },
    );
  }
}