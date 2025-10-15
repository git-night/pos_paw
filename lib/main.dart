import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'pages/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://laiyxgomleznuuvpkcvd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxhaXl4Z29tbGV6bnV1dnBrY3ZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyODU5NTcsImV4cCI6MjA3MTg2MTk1N30.G_nAni7OvaKO0v7ylg-ly2M-ID7jtif_8oWU6ZCo9pU',
  );

  runApp(const POSApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawssionate POS',
      theme: AppTheme.buildTheme(context),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
