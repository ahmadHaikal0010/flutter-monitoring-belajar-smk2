import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'logic/providers/auth_provider.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/pending_approval_screen.dart';
import 'presentation/home/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitoring Belajar SMK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          }
          if (auth.isPendingApproval) {
            return const PendingApprovalScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
