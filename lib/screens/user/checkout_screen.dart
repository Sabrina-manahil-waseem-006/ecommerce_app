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

  /// Function to process payment using Stripe Payment Sheet
  Future<void> processPayment(BuildContext context) async {
    try {
      // 🔹 Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 1️⃣ Call Supabase Edge Function "payment_service" to get PaymentIntent
      final response = await supabase.functions.invoke('payment_service', body: {
        'amount': (total * 100).toInt(), // Stripe expects amount in cents
        'currency': 'usd',
      });

      final clientSecret = response.data['clientSecret'];

      if (clientSecret == null) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initialization failed!')),
        );
        return;
      }

      // 2️⃣ Initialize Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'NedEats',
        ),
      );

      // 3️⃣ Present Payment Sheet to user
      await Stripe.instance.presentPaymentSheet();

      // 4️⃣ Payment success → save in Firebase
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

      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful & saved in Firebase!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      print('Payment failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Summary'),
        backgroundColor: const Color(0xFF9B1C1C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text(
                    "Order Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // List of cart items
                  ...items.map(
                    (item) => ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                            ? Image.network(
                                item.imageUrl!,
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.fastfood, size: 40),
                      ),
                      title: Text(item.name),
                      subtitle: Text(
                        "Rs. ${item.price} × ${item.quantity} = Rs. ${(item.price * item.quantity).toStringAsFixed(0)}",
                      ),
                    ),
                  ),

                  const Divider(height: 30),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rs. ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pay Now Button with Stripe Payment Sheet
            ElevatedButton(
              onPressed: () => processPayment(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1C1C),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Pay Now 💳",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
