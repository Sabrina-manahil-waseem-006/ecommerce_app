import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supervisor_service.dart';
import '../canteen/canteen_registration_screen.dart';
import '../canteen/canteen_management_screen.dart';


class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final _supervisorService = SupervisorService();
  bool isLoading = true;
  bool hasCanteen = false;
  Map<String, dynamic>? supData;
  Map<String, dynamic>? canteenData;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    final data = await _supervisorService.getSupervisorData();
    if (data == null) return;

    bool exists = data['canteenId'] != null;
    Map<String, dynamic>? canteen;
    if (exists) {
      canteen = await _supervisorService.getCanteenData(data['canteenId']);
    }

    setState(() {
      supData = data;
      hasCanteen = exists;
      canteenData = canteen;
      isLoading = false;
    });
  }

  Future<void> deleteCanteen() async {
    if (!hasCanteen || canteenData == null) return;

    try {
      await _supervisorService.deleteCanteen(supData!['canteenId']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Canteen deleted successfully")),
      );
      loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting canteen: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B1C1C), Color(0xFFB71C1C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 50,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Supervisor Dashboard",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasCanteen
                          ? "Manage your registered canteen"
                          : "You don’t have a canteen yet",
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
                child: hasCanteen && canteenData != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (canteenData!['imageUrl'] != null &&
                              canteenData!['imageUrl'] != "")
                            Image.network(
                              canteenData!['imageUrl'],
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          const SizedBox(height: 15),
                          Text(
                            canteenData!['name'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            canteenData!['description'] ?? '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CanteenDashboardScreen(
                                      canteenId: supData!['canteenId'],
                                    ),
                                  ),
                                ).then((_) => loadData());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Manage Your Canteen",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: deleteCanteen,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Delete Canteen",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            "Register Your Canteen",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const CanteenRegistrationScreen(),
                                  ),
                                ).then((_) => loadData());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9B1C1C),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Register Canteen",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                            ),
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
