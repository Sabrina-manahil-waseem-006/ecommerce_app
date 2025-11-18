import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // your firebaseOptions
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ===== 1️⃣ Firebase Initialization =====
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
    print('✅ Firebase initialized');

    // ===== 2️⃣ Supabase Initialization =====
    await Supabase.initialize(
      url: 'https://hiujojdqefjthfrlmosn.supabase.co', // your Supabase project URL
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpdWpvamRxZWZqdGhmcmxtb3NuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjI3MjMsImV4cCI6MjA3ODQ5ODcyM30.0h35RpTj0xjF_LFKWxo5GFAGeQx-_KZjIbNpcYanIUA', // replace with your Supabase anon key
    );
    print('✅ Supabase initialized');

    // ===== 3️⃣ Stripe Initialization =====
    // ⚠️ For Flutter Web, make sure <script src="https://js.stripe.com/v3/"></script>
    // is included in web/index.html
    Stripe.publishableKey =
        'pk_test_51SRHtNGPqgCvAjFkioImAA63nPD5F5rsuyeRgMB9li5GmTfcDa7p2beXGVje0d4af63Vybnk9nS3JttSLPitWQ7X0029MMd5Jv';
    await Stripe.instance.applySettings();
    print('✅ Stripe initialized');
  } catch (e, stack) {
    print('❌ Initialization error: $e');
    print(stack);
  }

  // ===== 4️⃣ Run App =====
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ned Eats',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const SplashSliderScreen(),

    );
  }
}
