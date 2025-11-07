import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/cart_item.dart';
import '/services/cart_service.dart';

class UserCartScreen extends StatelessWidget {
  final String canteenId; // required for canteen-specific carts
  final CartService _cartService = CartService();

  UserCartScreen({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: const Color(0xFF9B1C1C),
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cartService.getCartItems(canteenId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                "🛒 Your cart is empty for this canteen",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          double total = 0;
          for (var i in items) {
            total += i.price * i.quantity;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              (item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.fastfood,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                        title: Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          "Rs. ${item.price}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  _cartService.updateQuantity(
                                    canteenId, // ✅ Correct order
                                    item.itemId,
                                    item.quantity - 1,
                                  );
                                } else {
                                  _cartService.removeFromCart(
                                    canteenId, // ✅ Correct order
                                    item.itemId,
                                  );
                                }
                              },
                            ),
                            Text(
                              "${item.quantity}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                _cartService.updateQuantity(
                                  canteenId, // ✅ Correct order
                                  item.itemId,
                                  item.quantity + 1,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
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
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Checkout coming soon! 🧾'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B1C1C),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text("Proceed to Checkout"),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
