import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerce_app/models/cart_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutScreen extends StatelessWidget {
  final String canteenId;
  final List<CartItem> items;
  final double total;

  CheckoutScreen({
    super.key,
    required this.canteenId,
    required this.items,
    required this.total,
  });

  Future<String> createPendingOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw "User not logged in";

    final orderRef = FirebaseFirestore.instance
        .collection('canteens')
        .doc(canteenId)
        .collection('orders')
        .doc();

    final orderData = {
      "userId": user.uid,
      "canteenId": canteenId,
      "items": items
          .map(
            (item) => {
              "itemId": item.itemId,
              "name": item.name,
              "quantity": item.quantity,
              "price": item.price,
              "imageUrl": item.imageUrl ?? "",
            },
          )
          .toList(),
      "total": total,
      "status": {
        "payment": "pending", // Payment status
        "order": "pending", // Order preparation status
      },
      "createdAt": FieldValue.serverTimestamp(),
      "orderId": orderRef.id,
    };

    // Save order under canteen
    await orderRef.set(orderData);

    // Save order under user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderRef.id)
        .set(orderData);

    return orderRef.id;
  }

  void processPayment(BuildContext context) async {
    // Create pending order first
    String orderId = await createPendingOrder();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayFastPaymentPage(
          amount: total,
          canteenId: canteenId,
          orderId: orderId,
          cartItems: items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Pastel background

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Checkout Summary",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // MAIN SUMMARY CARD
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 22,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Order Summary",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ITEM LIST TILE
                    ...items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  (item.imageUrl != null &&
                                      item.imageUrl!.isNotEmpty)
                                  ? Image.network(
                                      item.imageUrl!,
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 55,
                                      height: 55,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fastfood),
                                    ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Rs ${item.price} × ${item.quantity}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              "Rs ${(item.price * item.quantity).toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(thickness: 1, height: 30),
                    const SizedBox(height: 12),

                    // TOTAL BOX
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.deepOrange.withOpacity(0.4),
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Amount",
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "Rs ${total.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // PAY NOW BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => processPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 5,
                  shadowColor: Colors.deepOrange.withOpacity(0.4),
                ),
                child: Text(
                  "Pay Now",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PayFast Payment Page
class PayFastPaymentPage extends StatelessWidget {
  final double amount;
  final String canteenId;
  final String orderId;
  final List<CartItem> cartItems;

  PayFastPaymentPage({
    required this.amount,
    required this.canteenId,
    required this.orderId,
    required this.cartItems,
  });

  Future<void> clearCart() async {
    // Implement your cart clearing here if needed
  }

  Future<void> launchPayment(BuildContext context) async {
    String merchantId = "10043843";
    String merchantKey = "2b6mq39mdxiuh";
    String passphrase = "mysandbox123";

    int amt = amount.round();
    String encodedItem = Uri.encodeComponent(orderId);

    String signatureString =
        "amount=$amt&item_name=$encodedItem&merchant_id=$merchantId&merchant_key=$merchantKey&passphrase=$passphrase";

    String signature = md5.convert(utf8.encode(signatureString)).toString();

    String url =
        "https://sandbox.payfast.co.za/eng/process?"
        "merchant_id=$merchantId"
        "&merchant_key=$merchantKey"
        "&amount=$amt"
        "&item_name=$encodedItem"
        "&signature=$signature";

    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Update payment status after paymentR
      await FirebaseFirestore.instance
          .collection('canteens')
          .doc(canteenId)
          .collection('orders')
          .doc(orderId)
          .update({"status.payment": "paid"});

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .update({"status.payment": "paid"});
      }

      // Clear user's cart
      await clearCart();

      // Navigate to receipt screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(canteenId: canteenId, orderId: orderId),
        ),
      );
    } else {
      throw "Could not launch PayFast URL";
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => launchPayment(context));
    return Scaffold(
      appBar: AppBar(title: const Text("Redirecting to PayFast")),
      body: const Center(
        child: Text(
          "Redirecting to PayFast Sandbox...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// Receipt Screen
class ReceiptScreen extends StatelessWidget {
  final String canteenId;
  final String orderId;

  const ReceiptScreen({
    super.key,
    required this.canteenId,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final orderRef = FirebaseFirestore.instance
        .collection('canteens')
        .doc(canteenId)
        .collection('orders')
        .doc(orderId);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Stack(
        children: [
          //  Soft Pastel Red Circle
          Positioned(
            top: -60,
            left: -30,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.red.shade100, Colors.red.shade300],
                ),
              ),
            ),
          ),

          // Soft Pastel Blue Circle
          Positioned(
            bottom: -80,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade300],
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<DocumentSnapshot>(
                future: orderRef.get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final order = snapshot.data!.data() as Map<String, dynamic>;
                  final items = List<Map<String, dynamic>>.from(
                    order['items'] ?? [],
                  );
                  final total = order['total'] ?? 0;

                  final status = order['status'] ?? {};
                  final paymentStatus = status["payment"] ?? "pending";
                  final orderStatus = status["order"] ?? "pending";

                  return Column(
                    children: [
                      Text(
                        "Order Receipt",
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Order #$orderId",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // CARD UI
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // STATUS BADGES
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _statusBadge(
                                    "Payment: $paymentStatus",
                                    paymentStatus == "paid"
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  _statusBadge(
                                    "Order: $orderStatus",
                                    (orderStatus == "ready" ||
                                            orderStatus == "complete")
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Text(
                                "Items",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Expanded(
                                child: ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'],
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                "${item['quantity']} × Rs. ${item['price']}",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            "Rs. ${(item['quantity'] * item['price']).toStringAsFixed(0)}",
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const Divider(height: 30),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Total Amount",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Rs. ${total.toStringAsFixed(0)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
