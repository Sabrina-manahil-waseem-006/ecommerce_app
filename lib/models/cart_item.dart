class CartItem {
  final String id;
  final String itemId;
  final String canteenId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.itemId,
    required this.canteenId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory CartItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CartItem(
      id: id,
      itemId: data['itemId'] ?? '',
      canteenId: data['canteenId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'itemId': itemId,
    'canteenId': canteenId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
    'createdAt': DateTime.now(),
  };
}
