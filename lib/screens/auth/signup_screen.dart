import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerce_app/services/auth_service.dart';
import 'login_screen.dart';
import 'package:ecommerce_app/screens/supervisor/supervisor_request_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool isPasswordVisible = false;
  String? nameError, emailError, passwordError;

  Future<void> signupUser() async {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
    });

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      if (name.isEmpty) nameError = "Name required";
      if (email.isEmpty) emailError = "Email required";
      if (password.isEmpty) passwordError = "Password required";
      setState(() {});
      return;
    }

    setState(() => isLoading = true);
    final error = await _authService.signup(name, email, password);
    setState(() => isLoading = false);

    if (error != null) {
      if (error.contains("email")) {
        emailError = error;
      } else if (error.contains("password")) {
        passwordError = error;
      } else {
        emailError = error;
      }
      setState(() {});
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // same UI — unchanged
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              // header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B1C1C), Color(0xFFB71C1C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.fastfood_rounded,
                        size: 50, color: Colors.white.withOpacity(0.9)),
                    Text("NEDEats",
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600)),
                    Text("Skip the line. Savor the time.",
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // signup form
              Container(
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
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    if (nameError != null)
                      Text(nameError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 15),

                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (emailError != null)
                      Text(emailError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 15),

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
                          onPressed: () =>
                              setState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                      ),
                    ),
                    if (passwordError != null)
                      Text(passwordError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: signupUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B1C1C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : const Text("Sign Up",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LoginScreen()),
                      ),
                      child: Text("Already have an account? Login",
                          style: TextStyle(color: Colors.blue.shade800)),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SupervisorRequestScreen()),
                        );
                      },
                      child: const Text("Apply as Supervisor",
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
