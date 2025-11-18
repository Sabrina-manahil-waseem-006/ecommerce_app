import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'update_items_screen.dart';
import 'package:ecommerce_app/screens/canteen/update_items_screen.dart';

class CanteenDashboardScreen extends StatefulWidget {
  final String canteenId;
  const CanteenDashboardScreen({super.key, required this.canteenId});

  @override
  State<CanteenDashboardScreen> createState() => _CanteenDashboardScreenState();
}

class _CanteenDashboardScreenState extends State<CanteenDashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic>? canteenData;
  String? imageUrl;
  List<String> availableCategories = [];
  List<Map<String, dynamic>> allItems =
      []; // All items including category items

  @override
  void initState() {
    super.initState();
    loadCanteen();
    loadCategories();
    loadAllItems();
  }

  Future<void> loadCanteen() async {
    try {
      setState(() => isLoading = true);
      final doc = await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          canteenData = data;
          imageUrl = data['imageUrl'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Canteen not found"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading canteen: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      debugPrint("Error loading categories: $e");
    }
  }

  Future<void> loadAllItems() async {
    try {
      final itemsRef = FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items');
      final snapshot = await itemsRef
          .orderBy('createdAt', descending: true)
          .get();
      List<Map<String, dynamic>> itemsList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'item') {
          itemsList.add({'data': data, 'id': doc.id, 'parentCategory': null});
        } else if (data['type'] == 'category') {
          final categoryItems = await doc.reference.collection('items').get();
          for (var cdoc in categoryItems.docs) {
            itemsList.add({
              'data': cdoc.data(),
              'id': cdoc.id,
              'parentCategory': doc.id,
            });
          }
        }
      }

      setState(() => allItems = itemsList);
    } catch (e) {
      debugPrint("Error loading items: $e");
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

  Future<void> uploadProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) throw Exception("No image data found");

      final newUrl =
          await uploadToCloudinary(bytes, "canteen_images") ?? imageUrl;

      await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .set({'imageUrl': newUrl}, SetOptions(merge: true));

      setState(() => imageUrl = newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile image updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteItem(String itemId, {String? parentCategory}) async {
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
      await loadAllItems();
      await loadCategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting item: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> showAddItemDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    Uint8List? pickedImageBytes;
    bool isAvailable = true;

    String? selectedCategory;
    final newCategoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        () => pickedImageBytes = result.files.single.bytes,
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
                    child: pickedImageBytes != null
                        ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                        : const Center(child: Text("Tap to upload image")),
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
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0;
                String? category;
                if (selectedCategory != null && selectedCategory!.isNotEmpty)
                  category = selectedCategory;
                else if (newCategoryController.text.trim().isNotEmpty)
                  category = newCategoryController.text.trim();

                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter valid name & price"),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                await addItemToFirestore(
                  name,
                  price,
                  pickedImageBytes,
                  isAvailable,
                  category,
                );
              },
              child: const Text(
                "Add Item",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addItemToFirestore(
    String name,
    double price,
    Uint8List? imageBytes,
    bool isAvailable, [
    String? category,
  ]) async {
    try {
      String? uploadedUrl;
      if (imageBytes != null)
        uploadedUrl = await uploadToCloudinary(imageBytes, "item_images");

      final itemsRef = FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items');

      if (category == null) {
        await itemsRef.add({
          'name': name,
          'price': price,
          'imageUrl': uploadedUrl ?? '',
          'isAvailable': isAvailable,
          'type': 'item',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final categoryDocRef = itemsRef.doc(category);
        final categoryDoc = await categoryDocRef.get();
        if (!categoryDoc.exists) {
          await categoryDocRef.set({
            'name': category,
            'type': 'category',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await categoryDocRef.collection('items').add({
          'name': name,
          'price': price,
          'imageUrl': uploadedUrl ?? '',
          'isAvailable': isAvailable,
          'type': 'item',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item added successfully"),
          backgroundColor: Colors.green,
        ),
      );
      await loadCategories();
      await loadAllItems();
    } catch (e) {
      debugPrint("Error adding item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding item: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = canteenData?['name'] ?? 'Unnamed Canteen';
    final desc = canteenData?['description'] ?? 'No description provided';
    final img = imageUrl;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Group items by category
    final Map<String, List<Map<String, dynamic>>> categorizedItems = {};
    final List<Map<String, dynamic>> uncategorizedItems = [];

    for (var item in allItems) {
      final category = item['parentCategory'];
      if (category != null) {
        categorizedItems[category] ??= [];
        categorizedItems[category]!.add(item);
      } else {
        uncategorizedItems.add(item);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Same as login screen
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: loadAllItems,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: uploadProfileImage,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: img != null && img.isNotEmpty
                          ? NetworkImage(img)
                          : null,
                      child: img == null || img.isEmpty
                          ? Icon(Icons.camera_alt, color: Colors.grey.shade600)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Canteen Dashboard",
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            buildDrawerOption(Icons.receipt_long, "View Orders", Colors.orange),
            buildDrawerOption(
              Icons.delivery_dining,
              "Track Orders",
              Colors.blue,
            ),
            buildDrawerOption(Icons.bar_chart, "Statistics", Colors.green),
            buildDrawerOption(
              Icons.add_box,
              "Add Items",
              Colors.red,
              onTap: showAddItemDialog,
            ),
            buildDrawerOption(
              Icons.update,
              "Update Items",
              Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UpdateItemsScreen(canteenId: widget.canteenId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Canteen info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: uploadProfileImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: img != null && img.isNotEmpty
                          ? NetworkImage(img)
                          : null,
                      child: img == null || img.isEmpty
                          ? Icon(
                              Icons.camera_alt,
                              color: Colors.grey.shade600,
                              size: 30,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "Available Items",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // ---- Display categorized items ----
            if (allItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    "No items added yet!",
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...categorizedItems.entries.map((entry) {
                    final catName = entry.key;
                    final items = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        Text(
                          catName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...items.map((item) {
                          final data = item['data'] as Map<String, dynamic>;
                          final price = (data['price'] is num)
                              ? (data['price'] as num).toDouble()
                              : 0.0;
                          final available = data['isAvailable'] ?? true;
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            color: Colors.white.withOpacity(0.8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    data['imageUrl'] != null &&
                                        (data['imageUrl'] as String).isNotEmpty
                                    ? Image.network(
                                        data['imageUrl'],
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: Colors.grey.shade600,
                                      ),
                              ),
                              title: Text(
                                data['name'] ?? 'Unnamed Item',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                "Price: Rs. $price",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: available
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      available ? "Available" : "Unavailable",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () => deleteItem(
                                      item['id'],
                                      parentCategory: item['parentCategory'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),

                  // Un-categorized items
                  if (uncategorizedItems.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        Text(
                          "Uncategorized",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...uncategorizedItems.map((item) {
                          final data = item['data'] as Map<String, dynamic>;
                          final price = (data['price'] is num)
                              ? (data['price'] as num).toDouble()
                              : 0.0;
                          final available = data['isAvailable'] ?? true;
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            color: Colors.white.withOpacity(0.8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    data['imageUrl'] != null &&
                                        (data['imageUrl'] as String).isNotEmpty
                                    ? Image.network(
                                        data['imageUrl'],
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: Colors.grey.shade600,
                                      ),
                              ),
                              title: Text(
                                data['name'] ?? 'Unnamed Item',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                "Price: Rs. $price",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: available
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      available ? "Available" : "Unavailable",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () => deleteItem(
                                      item['id'],
                                      parentCategory: null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  ListTile buildDrawerOption(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}