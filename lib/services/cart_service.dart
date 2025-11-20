import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';


class CartService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  ///  Add or update item in specific canteen's cart
  Future<void> addToCart(CartItem item) async {
    final cartRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(item.canteenId)
        .collection('items')
        .doc(item.itemId);

    final doc = await cartRef.get();

    if (doc.exists) {
      await cartRef.update({'quantity': FieldValue.increment(1)});
    } else {
      await cartRef.set(item.toFirestore());
    }
  }

  /// ✅ Get all cart items for a specific canteen
  Stream<List<CartItem>> getCartItems(String canteenId) {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(canteenId)
        .collection('items')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CartItem.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  /// ✅ Remove an item from a specific canteen's cart
  Future<void> removeFromCart(String canteenId, String itemId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(canteenId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  /// ✅ Update item quantity in specific canteen's cart
  Future<void> updateQuantity(
    String canteenId,
    String itemId,
    int newQuantity,
  ) async {
    final itemRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(canteenId)
        .collection('items')
        .doc(itemId);

    if (newQuantity <= 0) {
      await itemRef.delete(); // remove if 0 or less
    } else {
      await itemRef.update({'quantity': newQuantity});
    }
  }

  /// ✅ Clear all items from a specific canteen's cart
  Future<void> clearCart(String canteenId) async {
    final cartRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('cart')
        .doc(canteenId)
        .collection('items');

    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
