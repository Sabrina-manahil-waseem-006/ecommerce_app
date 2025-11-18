import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ecommerce_app/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

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

  final supabase = Supabase.instance.client;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> processPayment(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await supabase.functions.invoke('payment_service', body: {
        'amount': (total * 100).toInt(),
        'currency': 'usd',
      });

      final clientSecret = response.data['clientSecret'];

      if (clientSecret == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initialization failed!')),
        );
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'NedEats',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await firestore.collection('payments').add({
        'canteenId': canteenId,
        'items': items
            .map((e) => {
                  'name': e.name,
                  'price': e.price,
                  'quantity': e.quantity,
                })
            .toList(),
        'total': total,
        'status': 'success',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful & saved in Firebase!')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5), // Soft pastel background
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

                    // Cart items
                    ...items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
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
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          "Rs. ${item.price} × ${item.quantity} = Rs. ${(item.price * item.quantity).toStringAsFixed(0)}",
                        ),
                      ),
                    ),

                    const Divider(height: 30, thickness: 1.2),

                    // Total row
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

            // Pay Now Button
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
                "Pay Now 💳",
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
