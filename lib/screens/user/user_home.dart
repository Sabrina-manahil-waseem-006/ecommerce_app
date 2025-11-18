// user_home_screens.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/user_service.dart';
import '/services/cart_service.dart';
import '/models/cart_item.dart';
import 'user_cart_screen.dart';

/// Theme constants matching your screenshot
const Color _kBackground = Color(0xFFF8EFE6); // soft cream
const Color _kTextDark = Color(0xFF2E2E2E);
const Color _kAccentBlue = Color(0xFF2D63E2);
const double _kCardRadius = 16.0;
const double _kLargePadding = 18.0;

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final UserService _service = UserService();
  List<Map<String, dynamic>> _canteens = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCanteens();
  }

  Future<void> _fetchCanteens() async {
    try {
      final data = await _service.getCanteens();
      setState(() {
        _canteens = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching canteens: $e');
      setState(() => _loading = false);
    }
  }

  void _search(String query) {
    setState(() {
      final q = query.trim().toLowerCase();
      _filtered = _canteens.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    });
  }

  void _openItemsScreen(Map<String, dynamic> canteen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CanteenItemsScreen(canteenId: canteen['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'NEDEats',
          style: GoogleFonts.poppins(
            color: _kTextDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please open a canteen first to view its cart 🛒"),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
          ),
          const SizedBox(width: 6),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.account_circle_outlined, color: Colors.black),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // welcome + search row
                  Text(
                    "Welcome!",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchField(),
                  const SizedBox(height: 20),
                  Text(
                    'Available Canteens',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildCanteensGrid()),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: _search,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Search canteen...',
        hintStyle: GoogleFonts.poppins(color: Colors.black45),
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildCanteensGrid() {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'No canteens found',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      itemCount: _filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (context, i) {
        final c = _filtered[i];
        final imageUrl = (c['imageUrl'] ?? '').toString();
        return InkWell(
          onTap: () => _openItemsScreen(c),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kCardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => const Center(
                            child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                          ),
                        )
                      : const Center(child: Icon(Icons.fastfood, size: 40)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    c['name'] ?? 'Unnamed',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _kTextDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------------------- CanteenItemsScreen ----------------------
class CanteenItemsScreen extends StatefulWidget {
  final String canteenId;
  const CanteenItemsScreen({super.key, required this.canteenId});

  @override
  State<CanteenItemsScreen> createState() => _CanteenItemsScreenState();
}

class _CanteenItemsScreenState extends State<CanteenItemsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? canteenData;
  String imageUrl = '';
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  String query = '';

  @override
  void initState() {
    super.initState();
    _loadCanteenAndItems();
  }

  Future<void> _loadCanteenAndItems() async {
    await Future.wait([loadCanteen(), loadAllItems()]);
  }

  Future<void> loadCanteen() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          canteenData = doc.data();
          imageUrl = (doc.data()!['imageUrl'] ?? '').toString();
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading canteen: $e");
    }
  }

  Future<void> loadAllItems() async {
    try {
      setState(() => isLoading = true);
      final itemsRef = FirebaseFirestore.instance
          .collection('canteens')
          .doc(widget.canteenId)
          .collection('items');
      final snapshot = await itemsRef.orderBy('createdAt', descending: true).get();

      List<Map<String, dynamic>> itemsList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'item') {
          itemsList.add({'id': doc.id, 'data': data, 'parentCategory': null});
        } else if (data['type'] == 'category') {
          final subItems = await doc.reference.collection('items').get();
          for (var sdoc in subItems.docs) {
            itemsList.add({
              'id': sdoc.id,
              'data': sdoc.data(),
              'parentCategory': data['name'] ?? doc.id,
            });
          }
        }
      }

      setState(() {
        allItems = itemsList;
        filteredItems = itemsList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading items: $e");
      setState(() => isLoading = false);
    }
  }

  void _searchItems(String value) {
    setState(() {
      query = value.trim().toLowerCase();
      filteredItems = allItems.where((item) {
        final data = item['data'] as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  void _openItemDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          canteenId: widget.canteenId,
          itemId: item['id'],
          itemData: item['data'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = canteenData?['name'] ?? 'Canteen';
    final Map<String, List<Map<String, dynamic>>> categorizedItems = {};
    final List<Map<String, dynamic>> uncategorizedItems = [];

    for (var item in filteredItems) {
      final cat = item['parentCategory'];
      if (cat != null) {
        categorizedItems[cat] ??= [];
        categorizedItems[cat]!.add(item);
      } else {
        uncategorizedItems.add(item);
      }
    }

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        title: Text(
          name,
          style: GoogleFonts.poppins(color: _kTextDark, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserCartScreen(canteenId: widget.canteenId),
                ),
              );
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(_kLargePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderImage(),
                  const SizedBox(height: 16),
                  _buildSearchField(),
                  const SizedBox(height: 18),
                  Text(
                    "Available Items",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (filteredItems.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          "No items found",
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // categories
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
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...items.map((item) => _buildItemTile(item)),
                            ],
                          );
                        }),
                        // uncategorized
                        if (uncategorizedItems.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          Text(
                            "Other Items",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...uncategorizedItems.map((item) => _buildItemTile(item)),
                        ]
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCardRadius),
      child: imageUrl.isNotEmpty
          ? Image.network(imageUrl, width: double.infinity, height: 140, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 140,
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
              ))
          : Container(
              height: 140,
              color: Colors.grey[200],
              child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: _searchItems,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Search item...',
        hintStyle: GoogleFonts.poppins(color: Colors.black45),
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>;
    final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
    final available = data['isAvailable'] ?? true;

    return GestureDetector(
      onTap: () => _openItemDetail(item),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 3,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty)
                ? Image.network(
                    data['imageUrl'],
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 30, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 55,
                    height: 55,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, size: 30, color: Colors.grey),
                  ),
          ),
          title: Text(
            data['name'] ?? 'Unnamed Item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            "Rs. ${price.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          trailing: Text(
            available ? "Available" : "Unavailable",
            style: GoogleFonts.poppins(
              color: available ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------- ItemDetailScreen ----------------------
class ItemDetailScreen extends StatefulWidget {
  final String canteenId;
  final String itemId;
  final Map<String, dynamic> itemData;

  const ItemDetailScreen({
    super.key,
    required this.canteenId,
    required this.itemId,
    required this.itemData,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int quantity = 1;
  final CartService _cartService = CartService();

  @override
  Widget build(BuildContext context) {
    final name = widget.itemData['name'] ?? 'Unnamed Item';
    final imageUrl = (widget.itemData['imageUrl'] ?? '').toString();
    final description = (widget.itemData['description'] ?? '').toString();
    final price = (widget.itemData['price'] is num) ? (widget.itemData['price'] as num).toDouble() : 0.0;
    final isAvailable = widget.itemData['isAvailable'] ?? true;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        title: Text(
          name,
          style: GoogleFonts.poppins(color: _kTextDark, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_kLargePadding),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: imageUrl,
                        width: double.infinity,
                        height: 230,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, _, __) => Container(
                          height: 230,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 230,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 18),

              Text(name, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: _kTextDark)),
              const SizedBox(height: 8),
              Text("Rs. ${price.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(fontSize: 18, color: _kAccentBlue, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(isAvailable ? Icons.check_circle : Icons.cancel, color: isAvailable ? Colors.green : Colors.red, size: 20),
                  const SizedBox(width: 6),
                  Text(isAvailable ? "Available" : "Currently Unavailable",
                      style: GoogleFonts.poppins(
                        color: isAvailable ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),

              const SizedBox(height: 16),
              if (description.isNotEmpty) ...[
                Text("Description", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(description, style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[800], height: 1.5)),
                const SizedBox(height: 18),
              ],

              if (isAvailable)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // qty selector
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (quantity > 1) setState(() => quantity--);
                          },
                        ),
                        Text('$quantity', style: GoogleFonts.poppins(fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => quantity++),
                        ),
                      ],
                    ),

                    // add to cart
                    ElevatedButton.icon(
                      onPressed: () async {
                        final cartItem = CartItem(
                          id: '',
                          itemId: widget.itemId,
                          canteenId: widget.canteenId,
                          name: name,
                          price: price,
                          quantity: quantity,
                          imageUrl: imageUrl,
                        );
                        await _cartService.addToCart(cartItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("$name added to cart 🛒"), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text("Add to Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccentBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(14)),
                  child: Text("Not Available",
                      style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 16)),
                )
            ],
          ),
        ),
      ),
    );
  }
}
