import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Stream<QuerySnapshot> getOrdersStream(String status) {
    // Fetch all orders and filter locally for simplicity
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
      ).showSnackBar(SnackBar(content: Text('Failed to update order')));
    } finally {
      setState(() => isUpdating = false);
    }
  }

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
    final total = data['total'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${doc.id.substring(0, 6)}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${item['name']} × ${item['quantity']}"),
                  Text(
                    "Rs ${(item['price'] * item['quantity']).toStringAsFixed(0)}",
                  ),
                ],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Rs $total", style: const TextStyle(color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Canteen Orders")),
      body: Column(
        children: [
          Row(
            children: [
              buildTab("Pending", "pending"),
              buildTab("Completed", "completed"),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getOrdersStream(selectedTab),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final status = (doc['status'] as Map)['order'] ?? 'pending';
                  return status == selectedTab;
                }).toList();
                if (filtered.isEmpty) return Center(child: Text("No orders"));
                return ListView(
                  children: filtered.map((doc) => buildOrderCard(doc)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
