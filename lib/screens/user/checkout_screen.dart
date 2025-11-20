import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerce_app/models/cart_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

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

  void processPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayFastPaymentPage(amount: total),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('Checkout Summary'),
        backgroundColor: const Color(0xFF9B1C1C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    Text(
                      "Order Summary",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ...items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              (item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.fastfood, size: 50),
                        ),
                        title: Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          "Rs. ${item.price} × ${item.quantity} = Rs. ${(item.price * item.quantity).toStringAsFixed(0)}",
                        ),
                      ),
                    ),
                    const Divider(height: 30, thickness: 1.2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total:",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Rs. ${total.toStringAsFixed(0)}",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9B1C1C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => processPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1C1C),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                "Pay Now",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PayFastPaymentPage extends StatelessWidget {
  final double amount;

  PayFastPaymentPage({required this.amount});

  String _generateOrderId() {
    // Random 8-digit order ID
    final random = Random();
    return "ORDER${random.nextInt(99999999).toString().padLeft(8, '0')}";
  }

  Future<void> launchPayment() async {
    String merchantId = "10043843";
    String merchantKey = "2b6mq39mdxiuh";
    String passphrase = "mysandbox123";

    int amt = amount.round(); // PayFast sandbox expects integer amount
    String orderId = _generateOrderId(); // Unique per order
    String encodedItem = Uri.encodeComponent(orderId);

    // Signature string in exact sandbox order
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
    } else {
      throw "Could not launch PayFast URL";
    }
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => launchPayment());
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
