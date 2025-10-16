import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class SupervisorRequestScreen extends StatefulWidget {
  const SupervisorRequestScreen({super.key});

  @override
  State<SupervisorRequestScreen> createState() =>
      _SupervisorRequestScreenState();
}

class _SupervisorRequestScreenState extends State<SupervisorRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final cnicController = TextEditingController();

  // Canteen Info
  final canteenNameController = TextEditingController();
  final descriptionController = TextEditingController();

  // Payment Info
  final jazzCashNameController = TextEditingController();
  final jazzCashNumberController = TextEditingController();
  final accountTypeController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool agreedToTerms = false;
  PlatformFile? uploadedFile;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        uploadedFile = result.files.first;
      });
    }
  }

  Future<void> submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must agree to the terms.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('supervisor_requests').add({
        'personalInfo': {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'phone': phoneController.text.trim(),
          'cnic': cnicController.text.trim(),
        },
        'canteenInfo': {
          'name': canteenNameController.text.trim(),
          'description': descriptionController.text.trim(),
        },
        'paymentInfo': {
          'jazzCashName': jazzCashNameController.text.trim(),
          'jazzCashNumber': jazzCashNumberController.text.trim(),
          'accountType': accountTypeController.text.trim(),
          'proofFileName': uploadedFile?.name ?? '',
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request submitted! Admin will review.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    Widget? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
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
        prefixIcon: prefixIcon, // now optional
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
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
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Text("Image not found!"));
            },
          ),
          Container(color: Colors.black38), // dark overlay for readability
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(
                    0.5,
                  ), // less transparent, more visible
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                          shadows: const [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Personal Info
                      buildTextField(
                        controller: nameController,
                        label: "Full Name",
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          if (val.length < 3) return "Min 3 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: emailController,
                        label: "Email",
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!regex.hasMatch(val)) return "Invalid email";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      // Password field: NO left icon, only right visibility icon
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
                          if (val == null || val.isEmpty) return "Required";
                          if (val.length < 6) return "Min 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: phoneController,
                        label: "Phone Number",
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          if (val.length < 10) return "Invalid number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: cnicController,
                        label: "CNIC",
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          if (val.length < 13) return "Invalid CNIC";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Canteen Info
                      buildTextField(
                        controller: canteenNameController,
                        label: "Canteen Name",
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: descriptionController,
                        label: "Description",
                        maxLines: 3,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Payment Info
                      buildTextField(
                        controller: jazzCashNameController,
                        label: "JazzCash Account Name",
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: jazzCashNumberController,
                        label: "JazzCash Number",
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          if (val.length < 10) return "Invalid number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: accountTypeController,
                        label: "Account Type",
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return "Required";
                          return null;
                        },
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
                              : "Upload Proof / CNIC",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Terms
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
                      const SizedBox(height: 20),
                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
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
