import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/ned.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Text("Image not found!"));
            },
          ),
          Container(color: Colors.black38),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  'Welcome to NED Eats',
                  style: GoogleFonts.pacifico(
                    fontSize: 38,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) =>  LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
