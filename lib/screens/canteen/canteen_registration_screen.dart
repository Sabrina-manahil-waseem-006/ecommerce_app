import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CanteenRegistrationScreen extends StatefulWidget {
  const CanteenRegistrationScreen({super.key});

  @override
  State<CanteenRegistrationScreen> createState() =>
      _CanteenRegistrationScreenState();
}

class _CanteenRegistrationScreenState
    extends State<CanteenRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  bool isLoading = false;

  Future<void> submitCanteen() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => isLoading = true);

    try {
      // Add canteen document
      final canteenRef = await FirebaseFirestore.instance
          .collection('canteens')
          .add({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'supervisorId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update supervisor doc
      final supervisorRef = FirebaseFirestore.instance
          .collection('supervisors')
          .doc(currentUser.uid);

      final supervisorDoc = await supervisorRef.get();
      if (!supervisorDoc.exists) {
        await supervisorRef.set({'role': 'supervisor'});
      }

      await supervisorRef.set({
        'canteenId': canteenRef.id,
        'canteenName': nameController.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Canteen registered successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Submit error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (val) =>
          val == null || val.isEmpty ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06,
            vertical: size.height * 0.04,
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B1C1C), Color(0xFFB71C1C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fastfood_rounded,
                      size: 50,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Register Canteen",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Add your canteen to the NEDEats system",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Form
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
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildTextField(
                        controller: nameController,
                        label: "Canteen Name",
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        controller: descriptionController,
                        label: "Description",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : submitCanteen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9B1C1C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Submit Canteen",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
