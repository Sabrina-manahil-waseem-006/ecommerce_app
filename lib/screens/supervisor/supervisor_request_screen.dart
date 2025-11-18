import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supervisor_service.dart';
import '../auth/login_screen.dart';

class SupervisorRequestScreen extends StatefulWidget {
  const SupervisorRequestScreen({super.key});

  @override
  State<SupervisorRequestScreen> createState() =>
      _SupervisorRequestScreenState();
}

class _SupervisorRequestScreenState extends State<SupervisorRequestScreen>
    with SingleTickerProviderStateMixin {
  final _supervisorService = SupervisorService();
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final cnicController = TextEditingController();
  final jazzCashNameController = TextEditingController();
  final jazzCashNumberController = TextEditingController();
  final accountTypeController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool agreedToTerms = false;
  PlatformFile? uploadedFile;

  String? termsError;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation for floating pastel circles
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation =
        Tween<double>(begin: -100, end: 100).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    cnicController.dispose();
    jazzCashNameController.dispose();
    jazzCashNumberController.dispose();
    accountTypeController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        uploadedFile = result.files.first;
      });
    }
  }

  Future<void> submitRequest() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState!.validate();

    setState(() {
      termsError = !agreedToTerms
          ? "You must agree to the terms and conditions."
          : null;
    });

    if (!isValid || termsError != null) return;

    setState(() => isLoading = true);

    try {
      await _supervisorService.submitSupervisorRequest({
        'personalInfo': {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'phone': phoneController.text.trim(),
          'cnic': cnicController.text.trim(),
        },
        'paymentInfo': {
          'jazzCashName': jazzCashNameController.text.trim(),
          'jazzCashNumber': jazzCashNumberController.text.trim(),
          'accountType': accountTypeController.text.trim(),
          'proofFileName': uploadedFile?.name ?? 'No file uploaded',
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request submitted! Admin will review."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.black87),
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Same as login screen
      body: Stack(
        children: [
          // 🌈 Floating Pastel Red Circle
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

          // 🌈 Floating Pastel Blue Circle
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

          // 🌟 MAIN CONTENT
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
              child: Column(
                children: [
                  // App Branding
                  Column(
                    children: [
                      Icon(Icons.fastfood_rounded,
                          size: 75, color: Colors.black87),
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
                        "Become a Supervisor",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // APPLICATION CARD
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Supervisor Application",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              )),

                          const SizedBox(height: 5),

                          Text("Fill in your details to apply",
                              style: GoogleFonts.poppins(
                                  color: Colors.black54, fontSize: 15)),

                          const SizedBox(height: 25),

                          // Personal Information Section
                          Text("Personal Information",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              )),

                          const SizedBox(height: 15),

                          buildTextField(
                            controller: nameController,
                            label: "Full Name",
                            validator: (val) =>
                                val == null || val.isEmpty ? "Name is required" : null,
                          ),

                          buildTextField(
                            controller: emailController,
                            label: "Email Address",
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Email is required";
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                          ),

                          buildTextField(
                            controller: passwordController,
                            label: "Password",
                            obscureText: !isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.black54,
                              ),
                              onPressed: () => setState(
                                () => isPasswordVisible = !isPasswordVisible,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return "Password is required";
                              if (val.length < 6)
                                return "Password must be at least 6 characters";
                              return null;
                            },
                          ),

                          buildTextField(
                            controller: phoneController,
                            label: "Phone Number",
                            keyboardType: TextInputType.phone,
                            validator: (val) =>
                                val == null || val.isEmpty ? "Phone number is required" : null,
                          ),

                          buildTextField(
                            controller: cnicController,
                            label: "CNIC Number",
                            keyboardType: TextInputType.number,
                            validator: (val) =>
                                val == null || val.isEmpty ? "CNIC is required" : null,
                          ),

                          const SizedBox(height: 20),

                          // Payment Information Section
                          Text("Payment Information",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              )),

                          const SizedBox(height: 15),

                          buildTextField(
                            controller: jazzCashNameController,
                            label: "JazzCash Account Name",
                            validator: (val) =>
                                val == null || val.isEmpty ? "Account name is required" : null,
                          ),

                          buildTextField(
                            controller: jazzCashNumberController,
                            label: "JazzCash Number",
                            keyboardType: TextInputType.phone,
                            validator: (val) =>
                                val == null || val.isEmpty ? "JazzCash number is required" : null,
                          ),

                          buildTextField(
                            controller: accountTypeController,
                            label: "Account Type",
                            validator: (val) =>
                                val == null || val.isEmpty ? "Account type is required" : null,
                          ),

                          const SizedBox(height: 20),

                          // File Upload Section
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: pickFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(color: Colors.blueAccent.shade100),
                                ),
                              ),
                              child: Text(
                                uploadedFile != null
                                    ? "Selected: ${uploadedFile!.name}"
                                    : "Upload Proof / CNIC (Optional)",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Terms and Conditions
                          Row(
                            children: [
                              Checkbox(
                                value: agreedToTerms,
                                onChanged: (val) =>
                                    setState(() => agreedToTerms = val ?? false),
                                fillColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.blueAccent;
                                  }
                                  return Colors.grey.shade300;
                                }),
                              ),
                              const Expanded(
                                child: Text(
                                  "I agree to the terms and conditions",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (termsError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                termsError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          const SizedBox(height: 25),

                          // Submit Button
                          isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                    strokeWidth: 2,
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: submitRequest,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      "Submit Application",
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
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                "Back to Login",
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
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "© 2025 NEDEats | Powered by NED University",
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
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