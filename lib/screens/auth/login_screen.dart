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

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool isPasswordVisible = false;
  String? emailError;
  String? passwordError;

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
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
      setState(() => emailError = "Please enter a valid email address");
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
          MaterialPageRoute(builder: (_) =>  AdminDashboard()),
        );
      } else if (role == 'supervisor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  SupervisorDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) =>  UserHome()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 🔹 Full UI (unchanged)
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.05,
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B1C1C), Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.fastfood_rounded,
                        size: 50, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 5),
                    Text("NEDEats",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 5),
                    Text("Skip the line. Savor the time.",
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Login Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome Back!",
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: const Color(0xFF002855),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text("Login to your NEDEats account",
                        style: GoogleFonts.poppins(
                            color: Colors.grey[700], fontSize: 14)),
                    const SizedBox(height: 25),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(emailError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 20),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => isPasswordVisible = !isPasswordVisible),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(passwordError!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12)),
                      ),
                    const SizedBox(height: 25),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B1C1C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : const Text("Login",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>  SignupScreen()),
                        ),
                        child: Text("Don't have an account? Sign Up",
                            style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text("© 2025 NEDEats | Powered by NED University",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
