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

class _SupervisorRequestScreenState extends State<SupervisorRequestScreen> {
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
          const SnackBar(content: Text("Request submitted! Admin will review.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
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
          style: const TextStyle(color: Colors.white),
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.15),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/form.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text("Image not found!")),
          ),
          Container(color: Colors.black38),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Supervisor Application",
                        style: GoogleFonts.pacifico(
                          fontSize: 28,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      buildTextField(
                        controller: nameController,
                        label: "Full Name",
                        validator: (val) =>
                            val == null || val.isEmpty ? "Name is required" : null,
                      ),
                      buildTextField(
                        controller: emailController,
                        label: "Email",
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
                            color: Colors.white70,
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
                            val == null || val.isEmpty ? "Phone required" : null,
                      ),
                      buildTextField(
                        controller: cnicController,
                        label: "CNIC",
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val == null || val.isEmpty ? "CNIC required" : null,
                      ),
                      const SizedBox(height: 20),
                      buildTextField(
                        controller: jazzCashNameController,
                        label: "JazzCash Account Name",
                        validator: (val) =>
                            val == null || val.isEmpty ? "Name required" : null,
                      ),
                      buildTextField(
                        controller: jazzCashNumberController,
                        label: "JazzCash Number",
                        keyboardType: TextInputType.phone,
                        validator: (val) =>
                            val == null || val.isEmpty ? "Number required" : null,
                      ),
                      buildTextField(
                        controller: accountTypeController,
                        label: "Account Type",
                        validator: (val) =>
                            val == null || val.isEmpty ? "Type required" : null,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                        ),
                        child: Text(
                          uploadedFile != null
                              ? "Selected: ${uploadedFile!.name}"
                              : "Upload Proof / CNIC (Optional)",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: agreedToTerms,
                            onChanged: (val) =>
                                setState(() => agreedToTerms = val ?? false),
                            fillColor: MaterialStateProperty.all(Colors.white),
                          ),
                          const Expanded(
                            child: Text(
                              "I agree to the terms and conditions",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      if (termsError != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            termsError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.3),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  "Submit Request",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
