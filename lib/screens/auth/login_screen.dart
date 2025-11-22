import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerce_app/services/auth_service.dart';
import 'package:ecommerce_app/screens/user/user_home.dart';
import 'package:ecommerce_app/screens/supervisor/supervisor_dashboard.dart';
import 'package:ecommerce_app/screens/admin/admin_dashboard.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool isPasswordVisible = false;
  String? emailError;
  String? passwordError;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation for floating pastel circles + lines
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -100,
      end: 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final reg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return reg.hasMatch(email);
  }

  Future<void> loginUser() async {
    FocusScope.of(context).unfocus();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (email.isEmpty || password.isEmpty) {
      if (email.isEmpty) emailError = "Please enter your email";
      if (password.isEmpty) passwordError = "Please enter your password";
      setState(() {});
      return;
    }

    if (!isValidEmail(email)) {
      setState(() => emailError = "Please enter a valid email");
      return;
    }

    if (password.length < 6) {
      setState(() => passwordError = "Password must be at least 6 characters");
      return;
    }

    if (isLoading) return;
    setState(() => isLoading = true);

    final result = await _authService.login(email, password);

    setState(() => isLoading = false);

    if (result.containsKey('error')) {
      setState(() => emailError = result['error']);
    } else {
      final role = result['role'];
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
      } else if (role == 'supervisor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SupervisorDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserHome()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // same as splash theme
      body: Stack(
        children: [
          // Floating Pastel Red Circle
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _animation.value - 80,
                left: -40,
                child: child!,
              );
            },
            child: Container(
              width: 230,
              height: 230,
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

          // Floating Pastel Blue Circle
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                bottom: _animation.value - 60,
                right: -55,
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

          // MAIN CONTENT
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Column(
                children: [
                  // App Branding
                  Column(
                    children: [
                      Icon(
                        Icons.fastfood_rounded,
                        size: 75,
                        color: Colors.black87,
                      ),
                      const SizedBox(height: 10),

                      Text(
                        "NEDEats",
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Skip the line. Savor the time.",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // LOGIN CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back!",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "Login to your NEDEats account",
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Email Field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Colors.black54,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        if (emailError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              emailError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Colors.black54,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                setState(
                                  () => isPasswordVisible = !isPasswordVisible,
                                );
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        if (passwordError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              passwordError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 25),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loginUser,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Don't have an account? Sign Up",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "© 2025 NEDEats | Powered by NED University",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
