class ItemModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final String? parentCategory;

  ItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    this.parentCategory,
  });

  factory ItemModel.fromMap(Map<String, dynamic> data, String id, {String? parentCategory}) {
    return ItemModel(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      imageUrl: data['imageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      parentCategory: parentCategory,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
      };
}
