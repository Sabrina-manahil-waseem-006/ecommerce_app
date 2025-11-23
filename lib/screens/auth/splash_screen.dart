import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashSliderScreen extends StatefulWidget {
  const SplashSliderScreen({super.key});

  @override
  State<SplashSliderScreen> createState() => _SplashSliderScreenState();
}

class _SplashSliderScreenState extends State<SplashSliderScreen> {
  int currentIndex = 0;
  late final Timer _timer;

  final int totalImages =
      5; // Number of sequential images (food1.jpg → food5.jpg)

  final List<String> sliderTexts = [
    "Welcome to NEDEats",
    "Skip the line. Savor the time.",
    "Fast • Smart • Modern Canteen Service",
  ];

  @override
  void initState() {
    super.initState();

    // Timer to change image and text every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        currentIndex = (currentIndex + 1) % totalImages;
      });
    });

    // Navigate to login after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Column(
        children: [
          // Top Image - half screen, bottom rounded corners
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(60),
                bottomRight: Radius.circular(60),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: Image.asset(
                  'assets/food${currentIndex + 1}.jpg', // dynamically use sequential images
                  key: ValueKey(currentIndex),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Text below the image
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Gradient + shadow text
                ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(
                        colors: [Colors.deepOrange, Colors.orangeAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                  child: Text(
                    sliderTexts[currentIndex % sliderTexts.length],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // will be replaced by gradient
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalImages,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: currentIndex == index ? 20 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? Colors.deepOrange
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
