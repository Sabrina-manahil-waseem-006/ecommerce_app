import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get all canteens
  Future<List<Map<String, dynamic>>> getCanteens() async {
    final snap = await _db.collection('canteens').get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  // Get items of a specific canteen
  Future<List<Map<String, dynamic>>> getCanteenItems(String canteenId) async {
    final snap = await _db
        .collection('canteens')
        .doc(canteenId)
        .collection('items')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }
}
