import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color _bgColor = Color(0xFFF5F5F5);
const double _cardRadius = 22;

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});

  // ---------------- STATUS COLOR ----------------
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'ready':
      case 'completed':
      case 'complete':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<String> _getCanteenName(String? canteenId) async {
    if (canteenId == null || canteenId.isEmpty) return "Canteen";
    final snap = await FirebaseFirestore.instance
        .collection('canteens')
        .doc(canteenId)
        .get();
    return snap.data()?['name'] ?? "Canteen";
  }

  String _capitalize(String str) =>
      str.isNotEmpty ? "${str[0].toUpperCase()}${str.substring(1).toLowerCase()}" : "";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Text(
            "Please log in to view your orders",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final ordersStream = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("orders")
        .orderBy("createdAt", descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Orders",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No orders yet",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final order = docs[index].data() as Map<String, dynamic>;
              final orderId = order['orderId'] ?? docs[index].id;
              final items = (order['items'] ?? []).map<Widget>((e) {
                final item = Map<String, dynamic>.from(e);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${item['name']} x${item['quantity'] ?? 1}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        "Rs ${(item['price'] * item['quantity']).toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();

              final paymentStatus =
                  order['status']?['payment']?.toString() ?? "pending";
              final orderStatus =
                  order['status']?['order']?.toString() ?? "pending";
              final total = (order['total'] ?? 0).toDouble();

              return FutureBuilder<String>(
                future: _getCanteenName(order['canteenId']?.toString()),
                builder: (context, canteenSnapshot) {
                  final canteenName = canteenSnapshot.data ?? "Canteen";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(_cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER: Canteen + Icon
                          Row(
                            children: [
                              const Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                              const SizedBox(width: 10),
                              Text(
                                canteenName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "#$orderId",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ITEMS LIST
                          ...items,
                          const SizedBox(height: 12),

                          // STATUS BADGES
                          Row(
                            children: [
                              _statusBadge(
                                "Order: ${_capitalize(orderStatus)}",
                                _statusColor(orderStatus),
                              ),
                              _statusBadge(
                                "Payment: ${_capitalize(paymentStatus)}",
                                _statusColor(paymentStatus),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // TOTAL ROW
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.deepOrange.shade100, Colors.deepOrange.shade200],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepOrange.shade100.withOpacity(0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "Total: Rs ${total.toStringAsFixed(0)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
