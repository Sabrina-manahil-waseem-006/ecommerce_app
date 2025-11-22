import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/services/admin_service.dart';
import 'package:ecommerce_app/models/supervisor_model.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0; // Navigation Index

  final List<String> menuOptions = [
    'Dashboard Overview',
    'Canteen Management',
    'Supervisor Management',
    'Payments & Transactions',
  ];

  // ---------------------- FIXED BUILD METHOD ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF6F0),

      appBar: AppBar(
        elevation: 1.5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // rounded bottom like modern apps
          ),
        ),
        backgroundColor: const Color(0xFFFEF6F0),
        centerTitle: true,

        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF2F63D8),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      drawer: _buildNedDrawer(),

      body: Stack(
        children: [
          // Background circle 1
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFFFDAD6),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Background circle 2
          Positioned(
            bottom: -50,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFD6ECFF),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main screen content
          _buildSelectedScreen(),
        ],
      ),
    );
  }

  // ---------------------- LOGOUT FUNCTION ------------------------
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  // ---------------------- DRAWER ------------------------
  Drawer _buildNedDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFFEF6F0),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFFEF6F0)),
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage("assets/admin_profile.png"),
                ),
                SizedBox(height: 10),
                Text(
                  "Admin Panel",
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          ...List.generate(menuOptions.length, (index) {
            return ListTile(
              leading: Icon(
                _getIcon(index),
                color: selectedIndex == index
                    ? const Color(0xFF4A8CFF)
                    : Colors.black54,
              ),
              title: Text(
                menuOptions[index],
                style: TextStyle(
                  color: selectedIndex == index
                      ? const Color(0xFF4A8CFF)
                      : Colors.black87,
                  fontWeight: selectedIndex == index
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              onTap: () {
                setState(() => selectedIndex = index);
                Navigator.pop(context);
              },
            );
          }),

          const Spacer(),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  // ---------------------- DRAWER ICONS ------------------------
  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.store_mall_directory;
      case 2:
        return Icons.supervisor_account;
      case 3:
        return Icons.payment;
      default:
        return Icons.help_outline;
    }
  }

  // ---------------------- SCREEN SWITCHER ------------------------
  Widget _buildSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 1:
        return _buildCanteenManagement();
      case 2:
        return _buildSupervisorManagement();
      case 3:
        return _buildPaymentsAndTransactions();
      default:
        return const Center(
          child: Text(
            'Static Content Placeholder',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        );
    }
  }

  Widget _buildPaymentsAndTransactions() {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('canteens').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No canteens found."));
        }

        final canteens = snapshot.data!.docs;

        double overallRevenue = 0;
        double overallSupervisorFees = 0;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: canteens.length,
          itemBuilder: (context, index) {
            final canteen = canteens[index];
            final canteenId = canteen.id;
            final canteenData = canteen.data() as Map<String, dynamic>;

            return FutureBuilder<QuerySnapshot>(
              future: firestore
                  .collection('canteens')
                  .doc(canteenId)
                  .collection('orders')
                  .get(),
              builder: (context, orderSnapshot) {
                if (!orderSnapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  );
                }

                int totalOrders = orderSnapshot.data!.docs.length;
                int pendingOrders = orderSnapshot.data!.docs
                    .where(
                      (o) =>
                          (o.data()
                              as Map<String, dynamic>)['status']['order'] ==
                          'pending',
                    )
                    .length;

                double canteenRevenue = orderSnapshot.data!.docs.fold(
                  0,
                  (sum, o) =>
                      sum + ((o.data() as Map<String, dynamic>)['total'] ?? 0),
                );

                // Example: Supervisor fee 10% per canteen
                double supervisorFee = canteenRevenue * 0.10;

                overallRevenue += canteenRevenue;
                overallSupervisorFees += supervisorFee;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ExpansionTile(
                    leading: const Icon(Icons.store),
                    title: Text(canteenData['name'] ?? 'Unnamed Canteen'),
                    subtitle: Text(canteenData['location'] ?? ''),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Orders: $totalOrders"),
                            Text("Pending Orders: $pendingOrders"),
                            Text(
                              "Revenue Generated: ₨${canteenRevenue.toStringAsFixed(0)}",
                            ),
                            Text(
                              "Supervisor Fees: ₨${supervisorFee.toStringAsFixed(0)}",
                            ),
                            Text(
                              "Net Revenue: ₨${(canteenRevenue - supervisorFee).toStringAsFixed(0)}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCanteenManagement() {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('canteens').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No canteens found."));
        }

        final canteens = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: canteens.length,
          itemBuilder: (context, index) {
            final canteen = canteens[index];
            final canteenId = canteen.id;
            final canteenData = canteen.data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                leading: const Icon(Icons.store, color: Colors.blue),
                title: Text(
                  canteenData['name'] ?? 'Unnamed Canteen',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  canteenData['location'] ?? '',
                  style: const TextStyle(color: Colors.black54),
                ),
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: firestore
                        .collection('canteens')
                        .doc(canteenId)
                        .collection('orders')
                        .get(),
                    builder: (context, orderSnapshot) {
                      if (!orderSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        );
                      }

                      int totalOrders = orderSnapshot.data!.docs.length;
                      int pendingOrders = orderSnapshot.data!.docs
                          .where(
                            (o) =>
                                (o.data()
                                    as Map<
                                      String,
                                      dynamic
                                    >)['status']['order'] ==
                                'pending',
                          )
                          .length;

                      double totalRevenue = orderSnapshot.data!.docs.fold(0, (
                        sum,
                        o,
                      ) {
                        final data = o.data() as Map<String, dynamic>;
                        final total = data['total'];
                        if (total is int) return sum + total.toDouble();
                        if (total is double) return sum + total;
                        if (total is String)
                          return sum + (double.tryParse(total) ?? 0);
                        return sum;
                      });

                      // Supervisor fee example (10%)
                      double supervisorFee = totalRevenue * 0.10;
                      double netRevenue = totalRevenue - supervisorFee;

                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _infoTile(
                                  Icons.receipt_long,
                                  "Total Orders",
                                  "$totalOrders",
                                ),
                                _infoTile(
                                  Icons.pending,
                                  "Pending Orders",
                                  "$pendingOrders",
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _infoTile(
                                  Icons.monetization_on,
                                  "Revenue",
                                  "₨${totalRevenue.toStringAsFixed(0)}",
                                ),
                                _infoTile(
                                  Icons.person,
                                  "Supervisor Fee",
                                  "₨${supervisorFee.toStringAsFixed(0)}",
                                ),
                                _infoTile(
                                  Icons.account_balance_wallet,
                                  "Net Revenue",
                                  "₨${netRevenue.toStringAsFixed(0)}",
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for nice info tiles
  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Count canteens
    int totalCanteens = (await db.collection('canteens').get()).docs.length;

    // Count supervisors
    int totalSupervisors =
        (await db.collection('supervisors').get()).docs.length;

    // Pending orders & revenue
    int pendingOrders = 0;
    double totalRevenue = 0;

    final canteens = await db.collection('canteens').get();
    for (var canteen in canteens.docs) {
      final orders = await db
          .collection('canteens')
          .doc(canteen.id)
          .collection('orders')
          .get();

      for (var order in orders.docs) {
        final data = order.data();
        final status = data['status']['order'] ?? '';

        if (status == 'pending') {
          pendingOrders++;
        } else if (status == 'completed') {
          totalRevenue += (data['total'] ?? 0);
        }
      }
    }

    return {
      "canteens": totalCanteens,
      "supervisors": totalSupervisors,
      "pendingOrders": pendingOrders,
      "revenue": totalRevenue,
    };
  }

  // ---------------------- DASHBOARD OVERVIEW ------------------------
  Widget _buildDashboardOverview() {
    return FutureBuilder(
      future: fetchDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dashboard Overview",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "Monitor system performance, activity, and financials at a glance.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _metricCard(
                    "Total Canteens",
                    "${data['canteens']}",
                    Icons.store,
                    Colors.blue,
                  ),
                  _metricCard(
                    "Supervisors",
                    "${data['supervisors']}",
                    Icons.people,
                    Colors.orange,
                  ),
                  _metricCard(
                    "Pending Orders",
                    "${data['pendingOrders']}",
                    Icons.receipt_long,
                    Colors.purpleAccent,
                  ),

                  _metricCard(
                    "Revenue",
                    "₨${data['revenue'].toStringAsFixed(0)}",
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Recent Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _recentActivityCard("Supervisor Ahmed approved for Canteen #5"),
              _recentActivityCard("Order #142 marked as completed."),
              _recentActivityCard("New payment received from Canteen #3."),

              const SizedBox(height: 30),

              const Text(
                "Insights & Analytics",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _insightCard(
                "System Uptime",
                "99.8%",
                "Stable this week",
                Icons.timeline,
                Colors.teal,
              ),
              const SizedBox(height: 10),
              _insightCard(
                "Order Growth",
                "+12%",
                "Increase vs last week",
                Icons.trending_up,
                Colors.indigo,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Color(0xFF777777))),
          ],
        ),
      ),
    );
  }

  Widget _recentActivityCard(String message) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Colors.redAccent),
        title: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _insightCard(
    String title,
    String value,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- SUPERVISOR MANAGEMENT ------------------------
  Widget _buildSupervisorManagement() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.red.shade900,
            child: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: "Accepted"),
                Tab(text: "Requests"),
                Tab(text: "Rejected"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _supervisorList('supervisors', 'approved'),
                _supervisorList('supervisor_requests', 'pending'),
                _supervisorList('supervisor_requests_rejected', 'rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _supervisorList(String collection, String status) {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No records found."));
        }

        final supervisors = snapshot.data!.docs
            .map((doc) => SupervisorModel.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: supervisors.length,
          itemBuilder: (context, index) {
            final s = supervisors[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('assets/form.jpeg'),
                ),
                title: Text(s.name.isNotEmpty ? s.name : 'Unnamed Supervisor'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${s.email}'),
                    if (s.canteenName != null)
                      Text('Canteen: ${s.canteenName}'),
                    if (s.phone != null) Text('Phone: ${s.phone}'),
                  ],
                ),
                trailing: _buildSupervisorActions(
                  status,
                  s,
                  snapshot.data!.docs[index],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupervisorActions(
    String status,
    SupervisorModel supervisor,
    DocumentSnapshot doc,
  ) {
    final adminService = AdminService();

    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () =>
                adminService.approveSupervisorRequest(doc, context),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent),
            onPressed: () => adminService.rejectSupervisorRequest(doc, context),
          ),
        ],
      );
    } else if (status == 'rejected') {
      return const Icon(Icons.block, color: Colors.redAccent);
    } else {
      return const Icon(Icons.verified, color: Colors.green);
    }
  }
}
