import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert';

Future<String?> createPaymentIntent(int amount, String currency) async {
  final url = Uri.parse(
      'https://hiujojdqefjthfrlmosn.supabase.co/functions/v1/payment_service');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpdWpvamRxZWZqdGhmcmxtb3NuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MjI3MjMsImV4cCI6MjA3ODQ5ODcyM30.0h35RpTj0xjF_LFKWxo5GFAGeQx-_KZjIbNpcYanIUA',
    },
    body: jsonEncode({'amount': amount, 'currency': currency}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['clientSecret'];
  } else {
    print('Error: ${response.body}');
    return null;
  }
}

Future<void> payWithStripe(int amount, String currency) async {
  try {
    final clientSecret = await createPaymentIntent(amount, currency);
    if (clientSecret == null) return;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Ned Eats',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    print('Payment successful ✅');
  } catch (e) {
    print('Payment failed ❌: $e');
  }
}
