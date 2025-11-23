import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const Color _bgColor = Color(0xFFF5F5F5);
const double _cardRadius = 20;

class UpdateItemsScreen extends StatefulWidget {
  final String canteenId;
  const UpdateItemsScreen({super.key, required this.canteenId});

  @override
  State<UpdateItemsScreen> createState() => _UpdateItemsScreenState();
}

class _UpdateItemsScreenState extends State<UpdateItemsScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<String> availableCategories = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -100,
      end: 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    loadCategories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items')
          .where('type', isEqualTo: 'category')
          .get();
      setState(() {
        availableCategories = snapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
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
        print("Cloudinary upload failed: $resBody");
        return null;
      }
    } catch (e) {
      print("Upload error: $e");
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
        const SnackBar(
          content: Text("Item deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting item: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
                  onChanged: (val) => setDialogState(() {
                    selectedCategory = val;
                    newCategoryController.text = '';
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCategoryController,
                  decoration: const InputDecoration(
                    labelText: "Or type new category",
                  ),
                  onChanged: (val) =>
                      setDialogState(() => selectedCategory = null),
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
                      borderRadius: BorderRadius.circular(12),
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
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                setState(() => isLoading = true);

                String? uploadedUrl = itemData['imageUrl'];
                if (pickedImage != null)
                  uploadedUrl =
                      await uploadToCloudinary(pickedImage!, "item_images") ??
                      uploadedUrl;

                String? finalCategory;
                if ((selectedCategory ?? '').isNotEmpty) {
                  finalCategory = selectedCategory;
                } else if (newCategoryController.text.trim().isNotEmpty)
                  finalCategory = newCategoryController.text.trim();

                final itemsRef = FirebaseFirestore.instance
                    .collection('canteens')
                    .doc(widget.canteenId)
                    .collection('items');

                // Update or move item
                if (parentCategory != finalCategory) {
                  if (parentCategory != null)
                    await itemsRef
                        .doc(parentCategory)
                        .collection('items')
                        .doc(itemId)
                        .delete();
                  if (finalCategory == null) {
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
                    final catDoc = itemsRef.doc(finalCategory);
                    final catSnap = await catDoc.get();
                    if (!catSnap.exists)
                      await catDoc.set({
                        'name': finalCategory,
                        'type': 'category',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    await catDoc.collection('items').doc(itemId).set({
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
              child: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white),
              ),
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
        if (data['type'] == 'item')
          displayItems.add({
            'data': data,
            'id': doc.id,
            'parentCategory': null,
          });
        if (data['type'] == 'category') {
          final catItems = await doc.reference.collection('items').get();
          for (var cdoc in catItems.docs)
            displayItems.add({
              'data': cdoc.data(),
              'id': cdoc.id,
              'parentCategory': doc.id,
            });
        }
      }
      yield displayItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: Text(
          "Update Items",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Manage Items",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Edit or delete your menu items",
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: fetchAllItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());

                      if (!snapshot.hasData || snapshot.data!.isEmpty)
                        return Center(
                          child: Text(
                            "No items added yet",
                            style: GoogleFonts.poppins(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        );

                      final displayItems = snapshot.data!;
                      return ListView.builder(
                        itemCount: displayItems.length,
                        itemBuilder: (context, i) {
                          final item = displayItems[i];
                          final data = item['data'] as Map<String, dynamic>;
                          final parentCategory =
                              item['parentCategory'] as String?;
                          final price = (data['price'] is num)
                              ? (data['price'] as num).toDouble()
                              : 0.0;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(_cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade100,
                                  child:
                                      (data['imageUrl'] != null &&
                                          data['imageUrl']
                                              .toString()
                                              .isNotEmpty)
                                      ? Image.network(
                                          data['imageUrl'],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.fastfood,
                                          size: 30,
                                          color: Colors.grey.shade600,
                                        ),
                                ),
                              ),
                              title: Text(
                                data['name'] ?? 'Unnamed Item',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Rs. $price",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data['isAvailable'] == true
                                        ? "Available"
                                        : "Not Available",
                                    style: TextStyle(
                                      color: data['isAvailable'] == true
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (parentCategory != null)
                                    Text(
                                      "Category: $parentCategory",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                    ),
                                    onPressed: () => editItem(
                                      item['id'],
                                      data,
                                      parentCategory: parentCategory,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red.shade400,
                                    ),
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
                ),
              ],
            ),
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
