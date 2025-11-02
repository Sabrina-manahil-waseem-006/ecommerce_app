import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/services/admin_service.dart';
import 'package:ecommerce_app/models/supervisor_model.dart';

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
    'Orders Management',
    'Payments & Transactions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _buildSelectedScreen(),
    );
  }

  // 🧭 Drawer
  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF6F2F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red.shade900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage('assets/admin_profile.png'),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(menuOptions.length, (index) {
            return ListTile(
              leading: Icon(_getIcon(index),
                  color: selectedIndex == index
                      ? Colors.red.shade900
                      : Colors.black87),
              title: Text(
                menuOptions[index],
                style: TextStyle(
                  color: selectedIndex == index
                      ? Colors.red.shade900
                      : Colors.black87,
                  fontWeight: selectedIndex == index ? FontWeight.bold : null,
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
            title: const Text('Logout',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // Sidebar icons
  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.store_mall_directory;
      case 2:
        return Icons.supervisor_account;
      case 3:
        return Icons.receipt_long;
      case 4:
        return Icons.payment;
      default:
        return Icons.help_outline;
    }
  }

  // Screen Switcher
  Widget _buildSelectedScreen() {
    switch (selectedIndex) {
      case 0:
        return _buildDashboardOverview();
      case 2:
        return _buildSupervisorManagement();
      default:
        return const Center(
          child: Text(
            'Static Content Placeholder',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        );
    }
  }

  // 📊 Professional Dashboard Overview
  Widget _buildDashboardOverview() {
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

          // Row 1: Key Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCard("Total Canteens", "8", Icons.store, Colors.blue),
              _metricCard("Supervisors", "12", Icons.people, Colors.orange),
              _metricCard("Pending Orders", "23", Icons.receipt_long,
                  Colors.purpleAccent),
              _metricCard("Revenue", "₨45,000", Icons.monetization_on,
                  Colors.green),
            ],
          ),
          const SizedBox(height: 30),

          // Activity Summary
          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _recentActivityCard("Supervisor Ahmed approved for Canteen #5"),
          _recentActivityCard("Order #142 marked as completed."),
          _recentActivityCard("New payment received from Canteen #3."),

          const SizedBox(height: 30),

          // Insights Section
          const Text(
            "Insights & Analytics",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _insightCard(
            "System Uptime",
            "99.8%",
            "Performance is stable this week.",
            Icons.timeline,
            Colors.teal,
          ),
          const SizedBox(height: 10),
          _insightCard(
            "Order Growth",
            "+12%",
            "Increase in orders compared to last week.",
            Icons.trending_up,
            Colors.indigo,
          ),
        ],
      ),
    );
  }

  // Metric Card (compact)
  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // Recent Activity Item
  Widget _recentActivityCard(String message) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: Colors.redAccent),
        title: Text(message,
            style: const TextStyle(fontSize: 14, color: Colors.black87)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // Insight Card
  Widget _insightCard(
      String title, String value, String desc, IconData icon, Color color) {
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
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // 👥 SUPERVISOR MANAGEMENT (same logic)
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
                  borderRadius: BorderRadius.circular(12)),
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
                    if (s.phone != null)
                      Text('Phone: ${s.phone}'),
                  ],
                ),
                trailing: _buildSupervisorActions(
                    status, s, snapshot.data!.docs[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupervisorActions(
      String status, SupervisorModel supervisor, DocumentSnapshot doc) {
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
            onPressed: () =>
                adminService.rejectSupervisorRequest(doc, context),
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
