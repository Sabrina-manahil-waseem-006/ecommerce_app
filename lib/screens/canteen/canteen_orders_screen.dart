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

      // Canteen side
      await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('orders')
          .doc(orderId)
          .update({
            "status.order": newStatus,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      // User side
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

  // STATUS TAB UI (Pastel Style)
  Widget buildTab(String label, String value, Color color) {
    bool isActive = selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // ORDER CARD (UserHome Style)
  Widget buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ORDER HEADER
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                "Order ID • ${doc.id.substring(0, 6)}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            "Items:",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          ...((data['items'] as List).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                "• ${item['name']} × ${item['quantity']}",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
            );
          })),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(Icons.currency_rupee, color: Colors.green, size: 20),
              const SizedBox(width: 4),
              Text(
                "Total: Rs ${data['total']}",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (selectedTab == "pending")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => updateOrderStatus(doc.id, "completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  "Mark as Completed",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
      backgroundColor: const Color(0xFFFFF8F0), // Same pastel as user dashboard

      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 220, 185),
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // rounded bottom like modern apps
          ),
        ),
        foregroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Canteen Orders",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              children: [
                buildTab("Pending", "pending", Colors.orange),
                const SizedBox(width: 12),
                buildTab("Completed", "completed", Colors.green),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getOrdersStream(selectedTab),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    );
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
    );
  }
}
