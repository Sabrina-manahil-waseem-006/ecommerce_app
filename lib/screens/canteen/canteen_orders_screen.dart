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

      // Update Canteen Side
      await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('orders')
          .doc(orderId)
          .update({
            "status.order": newStatus,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      // Update User Side
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

  Widget buildOrderCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order ID: ${doc.id}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            "Items",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 6),

          ...((data['items'] as List).map((item) {
            return Text(
              "• ${item['name']} x ${item['quantity']}",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            );
          })),

          const SizedBox(height: 12),

          Text(
            "Total Amount: Rs ${data['total']}",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 14),

          if (selectedTab == "pending")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => updateOrderStatus(doc.id, "completed"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Mark as Completed",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTab(String label, String value) {
    bool isActive = selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 10,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Same theme as login

      appBar: AppBar(
        title: Text(
          "Canteen Orders",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      body: Padding(
        padding: const EdgeInsets.all(18.0),
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
