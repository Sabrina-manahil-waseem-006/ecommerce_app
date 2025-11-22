import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Theme constants
const Color _kBackground = Color(0xFFF8EFE6);
const Color _kTextDark = Color(0xFF2E2E2E);
const Color _kAccentBlue = Color(0xFF2D63E2);

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'ready':
      case 'completed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<String> _getCanteenName(String canteenId) async {
    if (canteenId.isEmpty) return "Canteen";
    final doc = await FirebaseFirestore.instance
        .collection('canteens')
        .doc(canteenId)
        .get();
    return doc.data()?['name'] ?? "Canteen";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Text(
            "Please log in to view your orders",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    final ordersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // rounded bottom like modern apps
          ),
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No orders yet",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final orderData = docs[index].data() as Map<String, dynamic>;
              final orderId = orderData['orderId'] ?? docs[index].id;

              final items = (orderData['items'] as List<dynamic>? ?? [])
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              final paymentStatus =
                  orderData['status']?['payment']?.toString() ?? "pending";
              final orderStatus =
                  orderData['status']?['order']?.toString() ?? "pending";
              final totalAmount = (orderData['total'] ?? 0.0).toDouble();

              return FutureBuilder<String>(
                future: _getCanteenName(orderData['canteenId'] ?? ""),
                builder: (context, canteenSnapshot) {
                  final canteenName = canteenSnapshot.data ?? "Canteen";

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Canteen name
                        Text(
                          canteenName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Order ID: $orderId",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Items
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items.map<Widget>((item) {
                            return Text(
                              "• ${item['name']} x${item['quantity']}",
                              style: GoogleFonts.poppins(fontSize: 13),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 8),

                        // Status and Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _statusBadge(
                                  "Order: ${orderStatus.capitalize()}",
                                  _statusColor(orderStatus),
                                ),
                                const SizedBox(height: 4),
                                _statusBadge(
                                  "Payment: ${paymentStatus.capitalize()}",
                                  _statusColor(paymentStatus),
                                ),
                              ],
                            ),
                            Text(
                              "Rs. ${totalAmount.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
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

/// Extension to capitalize first letter
extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
