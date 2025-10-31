import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/item_model.dart';

class CanteenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📦 Upload image to Cloudinary
  Future<String?> uploadImageToCloudinary(Uint8List imageBytes, String folder) async {
    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/dlkrm0osa/image/upload");
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = 'NedEats'
        ..fields['folder'] = folder
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: "upload.jpg"));
      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'];
      } else {
        print("❌ Cloudinary upload failed: $resBody");
        return null;
      }
    } catch (e) {
      print("❌ Upload error: $e");
      return null;
    }
  }

  // 📂 Get all available categories
  Future<List<String>> getCategories(String canteenId) async {
    final itemsRef = _firestore.collection('canteens').doc(canteenId).collection('items');
    final snapshot = await itemsRef.where('type', isEqualTo: 'category').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // 🧾 Stream of all items (including subcategories)
  Stream<List<ItemModel>> fetchAllItems(String canteenId) async* {
    final itemsRef = _firestore.collection('canteens').doc(canteenId).collection('items');

    await for (var snapshot in itemsRef.snapshots()) {
      List<ItemModel> displayItems = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'item') {
          displayItems.add(ItemModel.fromMap(data, doc.id));
        } else if (data['type'] == 'category') {
          final categoryItems = await doc.reference.collection('items').get();
          for (var cdoc in categoryItems.docs) {
            displayItems.add(ItemModel.fromMap(cdoc.data(), cdoc.id, parentCategory: doc.id));
          }
        }
      }
      yield displayItems;
    }
  }

  // ✏️ Update or move item
  Future<void> updateItem({
    required String canteenId,
    required String itemId,
    required Map<String, dynamic> itemData,
    String? parentCategory,
    String? newCategory,
  }) async {
    final itemsRef = _firestore.collection('canteens').doc(canteenId).collection('items');
    final category = newCategory ?? parentCategory;

    if (parentCategory != category) {
      // Move item between categories
      if (parentCategory != null) {
        await itemsRef.doc(parentCategory).collection('items').doc(itemId).delete();
      } else {
        await itemsRef.doc(itemId).delete();
      }

      if (category == null) {
        await itemsRef.doc(itemId).set(itemData);
      } else {
        final categoryDoc = itemsRef.doc(category);
        final catSnap = await categoryDoc.get();
        if (!catSnap.exists) {
          await categoryDoc.set({
            'name': category,
            'type': 'category',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await categoryDoc.collection('items').doc(itemId).set(itemData);
      }
    } else {
      // Simple update
      if (parentCategory != null) {
        await itemsRef.doc(parentCategory).collection('items').doc(itemId).update(itemData);
      } else {
        await itemsRef.doc(itemId).update(itemData);
      }
    }
  }

  // ❌ Delete item
  Future<void> deleteItem({
    required String canteenId,
    required String itemId,
    String? parentCategory,
  }) async {
    final itemsRef = _firestore.collection('canteens').doc(canteenId).collection('items');
    if (parentCategory != null) {
      await itemsRef.doc(parentCategory).collection('items').doc(itemId).delete();
    } else {
      await itemsRef.doc(itemId).delete();
    }
  }
}
