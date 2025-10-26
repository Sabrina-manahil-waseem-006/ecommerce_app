import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

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

  @override
  void initState() {
    super.initState();
    loadCanteen();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ Canteen not found")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading canteen: $e")));
    }
  }

  Future<void> uploadProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;

      final fileName =
          'canteen_images/${widget.canteenId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      String newUrl;
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) throw Exception("No bytes found for web upload");
        await ref.putData(bytes);
        newUrl = await ref.getDownloadURL();
      } else {
        final path = result.files.single.path;
        if (path == null) throw Exception("No file path found for upload");
        final file = File(path);
        await ref.putFile(file);
        newUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .set({'imageUrl': newUrl}, SetOptions(merge: true));

      setState(() => imageUrl = newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile image updated successfully")),
      );
    } catch (e) {
      debugPrint("❌ Error uploading image: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error uploading image: $e")));
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items')
          .doc(itemId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ Item deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error deleting item: $e")));
    }
  }

  Future<void> showAddItemDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    Uint8List? pickedImageBytes;
    bool isAvailable = true;

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
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (result != null) {
                      setDialogState(
                        () => pickedImageBytes = result.files.single.bytes,
                      );
                    }
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
                      onChanged: (val) {
                        setDialogState(() => isAvailable = val);
                      },
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
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0;

                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("⚠️ Please enter valid name & price"),
                    ),
                  );
                  return;
                }

                Navigator.pop(context); // close dialog
                await addItemToFirestore(
                  name,
                  price,
                  pickedImageBytes,
                  isAvailable,
                );
              },
              child: const Text("Add Item"),
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
    bool isAvailable,
  ) async {
    try {
      String? imageUrl;
      if (imageBytes != null) {
        try {
          final fileName =
              'item_images/${widget.canteenId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child(fileName);
          await ref.putData(
            imageBytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          imageUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint("❌ Image upload failed: $e");
        }
      }

      final itemsRef = FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items');

      await itemsRef.add({
        'name': name,
        'price': price,
        'imageUrl': imageUrl ?? '',
        'isAvailable': isAvailable,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Item added successfully")),
      );
    } catch (e) {
      debugPrint("❌ Error adding item: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error adding item: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = canteenData?['name'] ?? 'Unnamed Canteen';
    final desc = canteenData?['description'] ?? 'No description provided';
    final img = imageUrl;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9B1C1C),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadCanteen),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9B1C1C), Color(0xFFB71C1C)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: uploadProfileImage,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage: img != null && img.isNotEmpty
                          ? NetworkImage(img)
                          : null,
                      child: img == null || img.isEmpty
                          ? const Icon(Icons.camera_alt, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
            buildDrawerOption(Icons.update, "Update Items", Colors.purple),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: uploadProfileImage,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFECECEC),
                      backgroundImage: img != null && img.isNotEmpty
                          ? NetworkImage(img)
                          : null,
                      child: img == null || img.isEmpty
                          ? const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
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
                            color: const Color(0xFF9B1C1C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
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
                color: const Color(0xFF9B1C1C),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('canteens')
                  .doc(widget.canteenId)
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        "No items added yet!",
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                final items = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final data = item.data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                              : const Icon(
                                  Icons.fastfood,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                        title: Text(
                          data['name'] ?? 'Unnamed Item',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "Price: Rs. ${data['price'] ?? 'N/A'}",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteItem(item.id),
                        ),
                      ),
                    );
                  },
                );
              },
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
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}
