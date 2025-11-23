import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/models/supervisor_model.dart';
import 'package:ecommerce_app/services/admin_service.dart';
import '../auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

const _kBackground = Color(0xFFF7F9FC);
const _kCardRadius = 20.0;
const _kLargePadding = 16.0;
const _kAccentBlue = Color(0xFF2F63D8);
const _kTextDark = Color(0xFF333333);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final List<String> menuOptions = [
    'Dashboard Overview',
    'Canteen Management',
    'Supervisor Management',
    'Payments & Transactions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _kBackground,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _kAccentBlue,
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: _buildSelectedScreen(),
    );
  }

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

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: _kBackground,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: _kBackground),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage("assets/admin_profile.png"),
                ),
                const SizedBox(height: 10),
                Text(
                  "Admin Panel",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(menuOptions.length, (index) {
            return ListTile(
              leading: Icon(
                _getIcon(index),
                color: selectedIndex == index ? _kAccentBlue : Colors.black54,
              ),
              title: Text(
                menuOptions[index],
                style: GoogleFonts.poppins(
                  color: selectedIndex == index ? _kAccentBlue : Colors.black87,
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
            leading: const Icon(Icons.logout, color: Color.fromARGB(255, 26, 21, 90)),
            title: Text(
              "Logout",
              style: GoogleFonts.poppins(color: const Color.fromARGB(255, 49, 24, 138)),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

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
        return const Center(child: Text("Coming Soon!"));
    }
  }

  // ---------------- DASHBOARD OVERVIEW ----------------
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final db = FirebaseFirestore.instance;

    final totalCanteens = (await db.collection('canteens').get()).docs.length;
    final totalSupervisors =
        (await db.collection('supervisors').get()).docs.length;

    int pendingOrders = 0;
    double totalRevenue = 0;

    final canteens = await db.collection('canteens').get();
    for (var c in canteens.docs) {
      final orders = await db
          .collection('canteens')
          .doc(c.id)
          .collection('orders')
          .get();
      for (var o in orders.docs) {
        final data = o.data();
        final status = data['status']['order'] ?? '';
        if (status == 'pending') pendingOrders++;
        if (status == 'completed') totalRevenue += (data['total'] ?? 0);
      }
    }

    return {
      "canteens": totalCanteens,
      "supervisors": totalSupervisors,
      "pendingOrders": pendingOrders,
      "revenue": totalRevenue,
    };
  }

  Widget _buildDashboardOverview() {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(_kLargePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard Overview",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Monitor system performance, activity, and financials at a glance.",
                style: GoogleFonts.poppins(color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // ---------------- KPI CARDS ----------------
              Row(
                children: [
                  Expanded(
                    child: _proKpiCard(
                      "Total Canteens",
                      "${data['canteens']}",
                      0.0,
                      Colors.blue.shade400,
                      Colors.blue.shade700,
                      Icons.store,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _proKpiCard(
                      "Supervisors",
                      "${data['supervisors']}",
                      0.0,
                      Colors.orange.shade400,
                      Colors.orange.shade700,
                      Icons.people,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _proKpiCard(
                      "Pending Orders",
                      "${data['pendingOrders']}",
                      0.0,
                      Colors.purple.shade400,
                      Colors.purple.shade700,
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _proKpiCard(
                      "Revenue",
                      "₨${data['revenue'].toStringAsFixed(0)}",
                      12.0,
                      Colors.green.shade400,
                      Colors.green.shade700,
                      Icons.monetization_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ---------------- CHART SECTION ----------------
              // ---------------- CHART SECTION ----------------
              Text(
                "Revenue Trend",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (data['revenue'] / 5).clamp(
                            1,
                            double.infinity,
                          ),
                          getTitlesWidget: (value, meta) => Text(
                            '₨${value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                            int index = value.toInt();
                            if (index < 0 || index >= labels.length)
                              return const SizedBox();
                            return Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 0),
                          FlSpot(1, data['revenue'] * 0.2),
                          FlSpot(2, data['revenue'] * 0.4),
                          FlSpot(3, data['revenue'] * 0.6),
                          FlSpot(4, data['revenue']),
                        ],
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade200,
                          ],
                        ),
                        barWidth: 4,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withOpacity(0.3),
                              Colors.green.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '₨${spot.y.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              // Tooltip background color set here
                              //backgroundColor: Colors.blueGrey.withOpacity(0.8),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Recent Activity",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _recentActivityCard(
                "Supervisor Sabrina approved for Canteen SFC",
              ),
              _recentActivityCard("Order #12345 received from DMS."),
              _recentActivityCard("Payment received from Canteen GCR"),
            ],
          ),
        );
      },
    );
  }

  // ---------------- KPI CARD ----------------
  Widget _proKpiCard(
    String title,
    String value,
    double percentChange,
    Color gradientStart,
    Color gradientEnd,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
        gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
        boxShadow: [
          BoxShadow(
            color: gradientEnd.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(title, style: GoogleFonts.poppins(color: Colors.white70)),
              const SizedBox(width: 8),
              Icon(
                percentChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white70,
                size: 14,
              ),
              Text(
                "${percentChange.abs()}%",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- RECENT ACTIVITY ----------------
  Widget _recentActivityCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Colors.redAccent),
        title: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // ---------------- CANTEEN MANAGEMENT ----------------
  // ---------------- CANTEEN MANAGEMENT ----------------
  Widget _buildCanteenManagement() {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('canteens').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final canteens = snapshot.data!.docs;
        if (canteens.isEmpty)
          return const Center(child: Text("No Canteens Found"));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: canteens.length,
          itemBuilder: (context, index) {
            final c = canteens[index];
            final data = c.data() as Map<String, dynamic>? ?? {};
            final canteenName = (data['name'] ?? 'Unnamed Canteen') as String;
            final canteenLocation =
                (data['location'] ?? 'Unknown Location') as String;

            return _canteenCard(c.id, canteenName, canteenLocation);
          },
        );
      },
    );
  }

  Widget _canteenCard(String id, String name, String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.store, color: Colors.blue),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          location,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('canteens')
                  .doc(id)
                  .collection('orders')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final orders = snapshot.data!.docs;

                int totalOrders = orders.length;
                int pendingOrders = orders.where((o) {
                  final data = o.data() as Map<String, dynamic>? ?? {};
                  final status = (data['status']?['order'] ?? '') as String;
                  return status == 'pending';
                }).length;

                double revenue = orders.fold(0.0, (sum, o) {
                  final data = o.data() as Map<String, dynamic>? ?? {};
                  final t = data['total'];
                  final totalDouble = (t is num)
                      ? t.toDouble()
                      : double.tryParse("$t") ?? 0.0;
                  return sum + totalDouble;
                });

                double fee = revenue * 0.10;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statsChip(
                      Icons.receipt_long,
                      "Orders",
                      "$totalOrders",
                      Colors.indigo,
                    ),
                    _statsChip(
                      Icons.pending_actions,
                      "Pending",
                      "$pendingOrders",
                      Colors.orange,
                    ),
                    _statsChip(
                      Icons.attach_money,
                      "Revenue",
                      "₨${revenue.toStringAsFixed(0)}",
                      Colors.green,
                    ),
                    _statsChip(
                      Icons.person,
                      "Fee",
                      "₨${fee.toStringAsFixed(0)}",
                      Colors.red,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsChip(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ---------------- SUPERVISOR MANAGEMENT ----------------
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No records found."));
        final supervisors = docs
            .map((d) => SupervisorModel.fromFirestore(d))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(_kLargePadding),
          itemCount: supervisors.length,
          itemBuilder: (context, index) {
            final s = supervisors[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kCardRadius),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('assets/form.jpeg'),
                ),
                title: Text(
                  s.name.isNotEmpty ? s.name : 'Unnamed Supervisor',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${s.email}', style: GoogleFonts.poppins()),
                    if (s.canteenName != null)
                      Text(
                        'Canteen: ${s.canteenName}',
                        style: GoogleFonts.poppins(),
                      ),
                    if (s.phone != null)
                      Text('Phone: ${s.phone}', style: GoogleFonts.poppins()),
                  ],
                ),
                trailing: _buildSupervisorActions(status, s, docs[index]),
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

  // -------------------- PREMIUM PAYMENTS & TRANSACTIONS UI --------------------

  Widget _buildPaymentsAndTransactions() {
    final firestore = FirebaseFirestore.instance;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('canteens').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final canteens = snapshot.data!.docs;
        if (canteens.isEmpty) {
          return const Center(
            child: Text(
              "No Canteens Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: canteens.length,
          itemBuilder: (context, index) {
            final c = canteens[index];
            final cData = c.data() as Map<String, dynamic>;

            return FutureBuilder<QuerySnapshot>(
              future: firestore
                  .collection('canteens')
                  .doc(c.id)
                  .collection('orders')
                  .get(),
              builder: (context, orderSnap) {
                if (!orderSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }

                int totalOrders = orderSnap.data!.docs.length;
                int pendingOrders = orderSnap.data!.docs.where((o) {
                  final status =
                      (o.data() as Map<String, dynamic>)['status']['order'];
                  return status == 'pending';
                }).length;

                double revenue = orderSnap.data!.docs.fold(0.0, (sum, o) {
                  final t = (o.data() as Map<String, dynamic>)['total'];
                  if (t is num) return sum + t.toDouble();
                  return sum + (double.tryParse("$t") ?? 0);
                });

                double supervisorFee = revenue * 0.10;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Theme(
                    data: ThemeData().copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),

                      // ----------- Header -----------
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payments,
                          color: Colors.deepPurple,
                          size: 26,
                        ),
                      ),

                      title: Text(
                        cData['name'] ?? "Unnamed Canteen",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),

                      subtitle: Text(
                        cData['location'] ?? "",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      collapsedIconColor: Colors.deepPurple,
                      iconColor: Colors.deepPurple,

                      // ----------- Expanded Content -----------
                      children: [
                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statsChip(
                                Icons.receipt_long,
                                "Orders",
                                "$totalOrders",
                                Colors.indigo,
                              ),

                              _statsChip(
                                Icons.pending_actions,
                                "Pending",
                                "$pendingOrders",
                                Colors.orange,
                              ),

                              _statsChip(
                                Icons.attach_money,
                                "Revenue",
                                "₨${revenue.toStringAsFixed(0)}",
                                Colors.green,
                              ),

                              _statsChip(
                                Icons.person,
                                "Supervisor Fee",
                                "₨${supervisorFee.toStringAsFixed(0)}",
                                Colors.red,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
