import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // your firebaseOptions
//import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    //  Firebase Initialization
    await Firebase.initializeApp(options: firebaseOptions);
    print(' Firebase initialized');

    //  Supabase Initialization
    //await Supabase.initialize(
    //  url: 'https://hiujojdqefjthfrlmosn.supabase.co', // Supabase project URL
    //  anonKey:
    //      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpdWpvamRxZWZqdGhmcmxtb3NuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjI3MjMsImV4cCI6MjA3ODQ5ODcyM30.0h35RpTj0xjF_LFKWxo5GFAGeQx-_KZjIbNpcYanIUA', // replace with your Supabase anon key
    //);
    //print('Supabase initialized');

    //  Stripe Initialization
    //  For Flutter Web, make sure <script src="https://js.stripe.com/v3/"></script>
    // is included in web/index.html
  } catch (e, stack) {
    print('❌ Initialization error: $e');
    print(stack);
  }

  //   Run App
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
