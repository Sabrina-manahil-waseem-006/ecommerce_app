import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/cart_item.dart';
import '/screens/user/checkout_screen.dart';
import '/services/cart_service.dart';

class UserCartScreen extends StatelessWidget {
  final String canteenId;
  final CartService _cartService = CartService();

  UserCartScreen({super.key, required this.canteenId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // Same pastel theme

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Your Cart",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: StreamBuilder<List<CartItem>>(
        stream: _cartService.getCartItems(canteenId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Text(
                "🛒 Your cart is empty",
                style: GoogleFonts.poppins(fontSize: 17, color: Colors.grey),
              ),
            );
          }

          double total = items.fold(
            0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          return Column(
            children: [
              // --------------------------
              // MAIN CARD UI (JUST LIKE CHECKOUT PAGE)
              // --------------------------
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(18),
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
                            Icons.shopping_cart,
                            color: Colors.deepOrange,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Cart Items",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // --------------------------
                      // CART ITEMS LIST
                      // --------------------------
                      ...items.map((item) {
                        return Container(
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
                                      "Rs ${item.price}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // QUANTITY BUTTONS
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.deepOrange,
                                    ),
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        _cartService.updateQuantity(
                                          canteenId,
                                          item.itemId,
                                          item.quantity - 1,
                                        );
                                      } else {
                                        _cartService.removeFromCart(
                                          canteenId,
                                          item.itemId,
                                        );
                                      }
                                    },
                                  ),
                                  Text(
                                    "${item.quantity}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.deepOrange,
                                    ),
                                    onPressed: () {
                                      _cartService.updateQuantity(
                                        canteenId,
                                        item.itemId,
                                        item.quantity + 1,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      const Divider(thickness: 1, height: 30),
                      const SizedBox(height: 12),

                      // --------------------------
                      // TOTAL AMOUNT BOX (Same UI as Checkout)
                      // --------------------------
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

              // --------------------------
              // BOTTOM BUTTON (Same as Pay Now button UI)
              // --------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            canteenId: canteenId,
                            items: items,
                            total: total,
                          ),
                        ),
                      );
                    },
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
                      "Proceed to Checkout",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
