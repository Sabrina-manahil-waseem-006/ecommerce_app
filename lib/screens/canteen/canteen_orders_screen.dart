import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _bgColor = Color(0xFFF5F5F5);
const double _cardRadius = 22;

class CanteenOrdersScreen extends StatefulWidget {
  final String canteenId;
  final String supervisorId;

  const CanteenOrdersScreen({
    super.key,
    required this.canteenId,
    required this.supervisorId,
  });

  @override
  State<CanteenOrdersScreen> createState() => _CanteenOrdersScreenState();
}

class _CanteenOrdersScreenState extends State<CanteenOrdersScreen> {
  String selectedTab = "pending";
  bool isUpdating = false;

  Stream<QuerySnapshot> getOrdersStream() {
    return FirebaseFirestore.instance
        .collection('canteens')
        .doc(widget.canteenId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    setState(() => isUpdating = true);
    try {
      final orderRef = FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('orders')
          .doc(orderId);

      await orderRef.update({
        'status.order': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final snapshot = await orderRef.get();
      final userId = snapshot['userId'] as String;

      final userOrderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId);

      await userOrderRef.update({
        'status.order': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order marked as $newStatus')));
    } catch (e) {
      print('Error updating order: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update order')));
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'ready':
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

  String _capitalize(String str) => str.isNotEmpty
      ? "${str[0].toUpperCase()}${str.substring(1).toLowerCase()}"
      : "";

  Widget buildTab(String label, String value) {
    bool active = selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? Colors.blue : Colors.blue.withOpacity(0.3),
              width: 1.4,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (data['status'] == null) return const SizedBox.shrink();

    final orderStatus = (data['status'] as Map)['order'] ?? 'pending';
    if (orderStatus != selectedTab) return const SizedBox.shrink();

    final items = List<Map<String, dynamic>>.from(data['items']);
    final total = data['total'] ?? 0.0;

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
            // HEADER: Order # + Icon
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                const SizedBox(width: 10),
                Text(
                  "Canteen", // Optional: you can fetch name as in template
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "#${doc.id.substring(0, 6)}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ITEMS
            ...items.map(
              (item) => Padding(
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
              ),
            ),
            const SizedBox(height: 12),

            // STATUS BADGE
            Row(
              children: [
                _statusBadge(
                  "Order: ${_capitalize(orderStatus)}",
                  _statusColor(orderStatus),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TOTAL + Button if pending
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (selectedTab == "pending")
                  ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () => updateOrderStatus(doc.id, "completed"),
                    child: isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Mark as Completed"),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepOrange.shade100,
                        Colors.deepOrange.shade200,
                      ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Canteen Orders",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                buildTab("Pending", "pending"),
                const SizedBox(width: 12),
                buildTab("Completed", "completed"),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getOrdersStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs
                    .where(
                      (doc) =>
                          ((doc['status'] as Map)['order'] ?? 'pending') ==
                          selectedTab,
                    )
                    .toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No orders",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return buildOrderCard(docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
