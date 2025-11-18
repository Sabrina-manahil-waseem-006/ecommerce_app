import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashSliderScreen extends StatefulWidget {
  const SplashSliderScreen({super.key});

  @override
  State<SplashSliderScreen> createState() => _SplashSliderScreenState();
}

class _SplashSliderScreenState extends State<SplashSliderScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<String> sliderTexts = [
    "Welcome to NEDEats",
    "Skip the line. Savor the time.",
    "Fast • Smart • Modern Canteen Service",
  ];

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() => currentIndex = (currentIndex + 1) % sliderTexts.length);
    });

    Timer(const Duration(seconds: 8), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // ← slower
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -200, end: 200).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Stack(
        children: [

          // 🍔 LEFT SIDE EMOJIS (ADDED)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                left: 8,
                top: -150 + _animation.value,
                child: Column(
                  children: const [
                    Text("🍔", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍕", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍟", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🌭", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍗", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🥪", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍜", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍱", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍝", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍛", style: TextStyle(fontSize: 32)),
                  ],
                ),
              );
            },
          ),

          // 🍩 RIGHT SIDE EMOJIS (ADDED)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                right: 8,
                bottom: -150 + _animation.value,
                child: Column(
                  children: const [
                    Text("🍩", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🧁", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍰", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍦", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍨", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🧋", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🥤", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍹", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🍿", style: TextStyle(fontSize: 32)),
                    SizedBox(height: 14),
                    Text("🥞", style: TextStyle(fontSize: 32)),
                  ],
                ),
              );
            },
          ),

          // 🌈 Pastel Red Circle
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _animation.value,
                left: -40,
                child: child!,
              );
            },
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade100, Colors.red.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 🌈 Pastel Blue Circle
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                bottom: _animation.value,
                right: -50,
                child: child!,
              );
            },
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade300],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),

          // 🔹 HEADER LINE 1
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: 40,
                left: 50 + _animation.value,
                child: Container(
                  width: 300,
                  height: 4,
                  color: Colors.grey.shade700,
                ),
              );
            },
          ),

          // 🔹 HEADER LINE 2
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: 60,
                right: 50 + _animation.value,
                child: Container(
                  width: 300,
                  height: 4,
                  color: Colors.grey.shade500,
                ),
              );
            },
          ),

          // 🔹 FOOTER LINE 1
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                bottom: 60,
                left: 50 + _animation.value,
                child: Container(
                  width: 300,
                  height: 4,
                  color: Colors.grey.shade700,
                ),
              );
            },
          ),

          // 🔹 FOOTER LINE 2
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                bottom: 40,
                right: 50 + _animation.value,
                child: Container(
                  width: 300,
                  height: 4,
                  color: Colors.grey.shade500,
                ),
              );
            },
          ),

          // ⭐ MAIN CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fastfood_rounded, size: 85, color: Colors.black87),
                const SizedBox(height: 20),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    sliderTexts[currentIndex],
                    key: ValueKey(currentIndex),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    sliderTexts.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: currentIndex == index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? Colors.blueAccent
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
