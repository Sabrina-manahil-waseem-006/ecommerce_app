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

  Stream<QuerySnapshot> getOrdersStream(String status) {
    return FirebaseFirestore.instance
        .collection('canteens')
        .doc(widget.canteenId)
        .collection('orders')
        .where('status.order', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return;

      final data = orderDoc.data()!;
      final userId = data['userId'];

      // update in canteen
      await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('orders')
          .doc(orderId)
          .update({
            "status.order": newStatus,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      // update in user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({
            "status.order": newStatus,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order marked as $newStatus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Custom Tab Button
  Widget buildTab(String label, String value) {
    bool active = selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.deepOrange : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
            border: Border.all(
              color: active
                  ? Colors.deepOrange
                  : Colors.deepOrange.withOpacity(0.3),
              width: 1.4,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Main Order Card UI (matching Checkout/Receipt look)
  Widget buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final items = List<Map<String, dynamic>>.from(data['items']);
    final total = data['total'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.deepOrange.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.deepOrange, size: 24),
              const SizedBox(width: 10),
              Text(
                "Order #${doc.id.substring(0, 6)}",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Items
          Text(
            "Items",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${item['name']} × ${item['quantity']}",
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Rs ${(item['price'] * item['quantity']).toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Total Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Rs $total",
                style: GoogleFonts.poppins(
                  color: Colors.deepOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Button only in pending tab
          if (selectedTab == "pending")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => updateOrderStatus(doc.id, "completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 5,
                  shadowColor: Colors.green.withOpacity(0.4),
                ),
                child: Text(
                  "Mark as Completed",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),

      // Top Gradient AppBar (matching your style)
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        elevation: 4,
        centerTitle: true,
        title: Text(
          "Canteen Orders",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        ),
      ),

      body: Stack(
        children: [
          // Top pastel circle
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.shade100,
                    Colors.deepOrange.shade300,
                  ],
                ),
              ),
            ),
          ),

          // Bottom pastel circle
          Positioned(
            bottom: -70,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.orange.shade100, Colors.orange.shade300],
                ),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    buildTab("Pending", "pending"),
                    const SizedBox(width: 12),
                    buildTab("Completed", "completed"),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: getOrdersStream(selectedTab),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No ${selectedTab == 'pending' ? 'pending' : 'completed'} orders",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      }

                      return ListView(
                        children: snapshot.data!.docs
                            .map((doc) => buildOrderCard(doc))
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
