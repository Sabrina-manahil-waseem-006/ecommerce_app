import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class UpdateItemsScreen extends StatefulWidget {
  final String canteenId;
  const UpdateItemsScreen({super.key, required this.canteenId});

  State<UpdateItemsScreen> createState() => _UpdateItemsScreenState();
}

class _UpdateItemsScreenState extends State<UpdateItemsScreen> {
  bool isLoading = false;
  List<String> availableCategories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final itemsRef = FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items');
      final snapshot = await itemsRef
          .where('type', isEqualTo: 'category')
          .get();
      final cats = snapshot.docs.map((doc) => doc.id).toList();
      setState(() => availableCategories = cats);
    } catch (e) {
      debugPrint("❌ Error loading categories: $e");
    }
  }

  Future<String?> uploadToCloudinary(
    Uint8List imageBytes,
    String folder,
  ) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dlkrm0osa/image/upload",
      );
      final request = http.MultipartRequest("POST", uri)
        ..fields['upload_preset'] = 'NedEats'
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: "upload.jpg",
          ),
        );
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

  Future<void> deleteItemWithConfirmation(
    String itemId, {
    String? parentCategory,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final itemsRef = FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items');
      if (parentCategory != null) {
        await itemsRef
            .doc(parentCategory)
            .collection('items')
            .doc(itemId)
            .delete();
      } else {
        await itemsRef.doc(itemId).delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Item deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error deleting item: $e")));
    }
  }

  Future<void> editItem(
    String itemId,
    Map<String, dynamic> itemData, {
    String? parentCategory,
  }) async {
    final nameController = TextEditingController(text: itemData['name']);
    final priceController = TextEditingController(
      text: itemData['price']?.toString() ?? '',
    );
    bool isAvailable = itemData['isAvailable'] ?? true;
    Uint8List? pickedImage;

    String? selectedCategory = parentCategory;
    final newCategoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Item"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Item Name"),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price (Rs.)"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Select Category",
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("Select Category"),
                    ),
                    ...availableCategories.map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    ),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      selectedCategory = val;
                      newCategoryController.text = '';
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCategoryController,
                  decoration: const InputDecoration(
                    labelText: "Or type new category",
                  ),
                  onChanged: (val) {
                    setDialogState(() => selectedCategory = null);
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null)
                      setDialogState(
                        () => pickedImage = result.files.single.bytes,
                      );
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: pickedImage != null
                        ? Image.memory(pickedImage!, fit: BoxFit.cover)
                        : (itemData['imageUrl'] != null &&
                                  itemData['imageUrl'].toString().isNotEmpty
                              ? Image.network(
                                  itemData['imageUrl'],
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.fastfood,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                )),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Availability"),
                    Switch(
                      value: isAvailable,
                      activeColor: Colors.green,
                      onChanged: (val) =>
                          setDialogState(() => isAvailable = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1C1C),
              ),
              onPressed: () async {
                setState(() => isLoading = true);

                String? uploadedUrl = itemData['imageUrl'];
                if (pickedImage != null)
                  uploadedUrl =
                      await uploadToCloudinary(pickedImage!, "item_images") ??
                      uploadedUrl;

                String? finalCategory;
                if (selectedCategory != null && selectedCategory!.isNotEmpty)
                  finalCategory = selectedCategory;
                else if (newCategoryController.text.trim().isNotEmpty)
                  finalCategory = newCategoryController.text.trim();

                final itemsRef = FirebaseFirestore.instance
                    .collection('canteens')
                    .doc(widget.canteenId)
                    .collection('items');

                // If category changed, move the document
                if (parentCategory != finalCategory) {
                  // Delete old item
                  if (parentCategory != null) {
                    await itemsRef
                        .doc(parentCategory)
                        .collection('items')
                        .doc(itemId)
                        .delete();
                  } else {
                    await itemsRef.doc(itemId).delete();
                  }

                  if (finalCategory == null) {
                    // Save at root
                    await itemsRef.doc(itemId).set({
                      'name': nameController.text.trim(),
                      'price':
                          double.tryParse(priceController.text.trim()) ?? 0,
                      'imageUrl': uploadedUrl ?? '',
                      'isAvailable': isAvailable,
                      'type': 'item',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    // Ensure category exists
                    final categoryDoc = itemsRef.doc(finalCategory);
                    final catSnap = await categoryDoc.get();
                    if (!catSnap.exists) {
                      await categoryDoc.set({
                        'name': finalCategory,
                        'type': 'category',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                    // Save inside new category
                    await categoryDoc.collection('items').doc(itemId).set({
                      'name': nameController.text.trim(),
                      'price':
                          double.tryParse(priceController.text.trim()) ?? 0,
                      'imageUrl': uploadedUrl ?? '',
                      'isAvailable': isAvailable,
                      'type': 'item',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  }
                } else {
                  // Update in same location
                  if (parentCategory != null) {
                    await itemsRef
                        .doc(parentCategory)
                        .collection('items')
                        .doc(itemId)
                        .update({
                          'name': nameController.text.trim(),
                          'price':
                              double.tryParse(priceController.text.trim()) ?? 0,
                          'imageUrl': uploadedUrl ?? '',
                          'isAvailable': isAvailable,
                        });
                  } else {
                    await itemsRef.doc(itemId).update({
                      'name': nameController.text.trim(),
                      'price':
                          double.tryParse(priceController.text.trim()) ?? 0,
                      'imageUrl': uploadedUrl ?? '',
                      'isAvailable': isAvailable,
                    });
                  }
                }

                loadCategories();
                setState(() => isLoading = false);
                Navigator.pop(context);
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> fetchAllItems() async* {
    final itemsRef = FirebaseFirestore.instance
        .collection('canteens')
        .doc(widget.canteenId)
        .collection('items');
    await for (var snapshot in itemsRef.snapshots()) {
      List<Map<String, dynamic>> displayItems = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['type'] == 'item') {
          displayItems.add({
            'data': data,
            'id': doc.id,
            'parentCategory': null,
          });
        } else if (data['type'] == 'category') {
          final categoryItems = await doc.reference.collection('items').get();
          for (var cdoc in categoryItems.docs) {
            displayItems.add({
              'data': cdoc.data(),
              'id': cdoc.id,
              'parentCategory': doc.id,
            });
          }
        }
      }
      yield displayItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Items"),
        backgroundColor: const Color(0xFF9B1C1C),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: fetchAllItems(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final displayItems = snapshot.data!;
              if (displayItems.isEmpty)
                return const Center(child: Text("No items yet"));

              return ListView.builder(
                itemCount: displayItems.length,
                itemBuilder: (context, i) {
                  final item = displayItems[i];
                  final data = item['data'] as Map<String, dynamic>;
                  final parentCategory = item['parentCategory'] as String?;
                  final price = (data['price'] is num)
                      ? (data['price'] as num).toDouble()
                      : 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            (data['imageUrl'] != null &&
                                data['imageUrl'].toString().isNotEmpty)
                            ? Image.network(
                                data['imageUrl'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.fastfood,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ),
                      title: Text(data['name'] ?? 'Unnamed'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rs. $price"),
                          Text(
                            data['isAvailable'] == true
                                ? "Available"
                                : "Not Available",
                            style: TextStyle(
                              color: data['isAvailable'] == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (parentCategory != null)
                            Text(
                              "Category: $parentCategory",
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editItem(
                              item['id'],
                              data,
                              parentCategory: parentCategory,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteItemWithConfirmation(
                              item['id'],
                              parentCategory: parentCategory,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
