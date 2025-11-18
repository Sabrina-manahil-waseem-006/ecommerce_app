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

class _SupervisorDashboardState extends State<SupervisorDashboard> 
    with SingleTickerProviderStateMixin {
  final _supervisorService = SupervisorService();
  bool isLoading = true;
  bool hasCanteen = false;
  Map<String, dynamic>? supData;
  Map<String, dynamic>? canteenData;

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

    loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Canteen"),
        content: const Text("Are you sure you want to delete this canteen? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supervisorService.deleteCanteen(supData!['canteenId']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Canteen deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
        loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting canteen: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }

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
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: size.height * 0.05,
              ),
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
                        "Supervisor Dashboard",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // DASHBOARD CARD
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
                    child: hasCanteen && canteenData != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Canteen",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                "Manage and monitor your canteen operations",
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Canteen Image
                              if (canteenData!['imageUrl'] != null &&
                                  canteenData!['imageUrl'] != "")
                                Container(
                                  width: double.infinity,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    image: DecorationImage(
                                      image: NetworkImage(canteenData!['imageUrl']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // Canteen Details
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      canteenData!['name'] ?? 'Unnamed Canteen',
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 10),
                                    
                                    Text(
                                      canteenData!['description'] ?? 'No description provided',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Manage Canteen Button
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
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    "Manage Canteen",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Delete Canteen Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: deleteCanteen,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(color: Colors.redAccent.shade400),
                                    ),
                                  ),
                                  child: Text(
                                    "Delete Canteen",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome, Supervisor!",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                "Register your canteen to get started",
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Illustration/Icon
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.restaurant_outlined,
                                    size: 60,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                "You haven't registered any canteen yet. Start by registering your canteen to manage menu, orders, and operations.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Register Canteen Button
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
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    "Register Canteen",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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