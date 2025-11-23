import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/user_service.dart';
import '/services/cart_service.dart';
import '/models/cart_item.dart';
import 'user_cart_screen.dart';
import 'order_screen.dart';
import '../auth/login_screen.dart';
import 'user_cart_screen.dart';

const _kBackground = Color(0xFFF5F5F5);
const _kTextDark = Color(0xFF222222);
const _kAccentBlue = Color(0xFF0D47A1);
const _kCardRadius = 18.0;

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openOrdersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserOrdersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: _kBackground,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kAccentBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: _kAccentBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'NEDEats',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _kAccentBlue,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Open a canteen first to view the cart 🛒"),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined, color: _kTextDark),
            ),
            IconButton(
              onPressed: _openOrdersScreen,
              icon: const Icon(Icons.list_alt_outlined, color: _kTextDark),
              tooltip: "My Orders",
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: _kTextDark),
              tooltip: "Logout",
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- NEW HEADER: NEDEats + Hello Foodie --------
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NEDEats Logo Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepOrangeAccent,
                              Colors.orangeAccent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Bite into happiness',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Welcome Text
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hello, Foodie! ',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _kTextDark,
                              ),
                            ),
                            TextSpan(
                              text: '🍕🍔🥗',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Discover delicious meals near you 🌟",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // -------- SEARCH FIELD --------
                  _buildSearchField(),
                  const SizedBox(height: 24),

                  // -------- POPULAR CANTEENS TEXT --------
                  Text(
                    'Popular Canteens',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // -------- GRID OF CANTEENS --------
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
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
          'No canteens found 😢',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      itemCount: _filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 3 / 2.2,
      ),
      itemBuilder: (context, i) {
        final c = _filtered[i];
        final imageUrl = (c['imageUrl'] ?? '').toString();
        final isPopular = (c['isPopular'] ?? false) as bool;
        final deliveryTime = (c['deliveryTime'] ?? '20-30 min').toString();
        final priceRange = (c['priceRange'] ?? "").toString();
        final isVeg = (c['isVeg'] ?? true) as bool;

        return InkWell(
          onTap: () => _openItemsScreen(c),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kCardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(_kCardRadius),
                              ),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, _, __) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.fastfood,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.fastfood, size: 40),
                            ),
                      if (isPopular)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "🔥 Trending",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBadge(
                            isVeg ? "Non-Veg" : "Veg",
                            isVeg ? Colors.green[50]! : Colors.red[50]!,
                            isVeg ? Colors.green[800]! : Colors.red[800]!,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c['name'] ?? 'Unnamed',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _kTextDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          Icon(Icons.star, size: 16, color: Colors.amber[700]),
                          Icon(
                            Icons.star_half,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "4.5",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            deliveryTime,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceRange,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

const double _kLargePadding = 18.0;

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
  int quantity = 1;

  final double _cardRadius = 20;
  final Color _accentOrange1 = Color(0xFFFF6B35);
  final Color _accentOrange2 = Color(0xFFFF3D00);
  final Color _background = Color(0xFFF9F9F9);
  final CartService _cartService = CartService();

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
      final snapshot = await itemsRef
          .orderBy('createdAt', descending: true)
          .get();

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

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
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
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- HEADER IMAGE ----------------
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(_cardRadius),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 220,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.fastfood,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            "Hungry? Let's satisfy your cravings 🍕🍔🌮",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---------------- SEARCH BAR ----------------
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: _searchItems,
                      decoration: InputDecoration(
                        hintText: 'Search for your favorite dish...',
                        hintStyle: GoogleFonts.poppins(color: Colors.black45),
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------------- ITEMS LIST ----------------
                  filteredItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              "No items found 😢",
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: filteredItems
                              .map((item) => _buildItemCard(item))
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }

  // ---------------- ITEM CARD ----------------
  Widget _buildItemCard(Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>;
    final price = (data['price'] is num)
        ? (data['price'] as num).toDouble()
        : 0.0;
    final available = data['isAvailable'] ?? true;
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final badges = (data['badges'] as List<dynamic>?) ?? [];
    final isTrending = data['isPopular'] ?? false;
    final isVeg = data['isVeg'] ?? true;

    return GestureDetector(
      onTap: () => _openItemDetail(item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // ---------------- IMAGE ----------------
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.fastfood,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                ),
                if (isTrending)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "🔥 Trending",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isVeg ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isVeg ? "" : "",
                      style: GoogleFonts.poppins(
                        color: isVeg ? Colors.green[800] : Colors.red[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Unnamed Item',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Rs. ${price.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: _accentOrange1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: badges.map<Widget>((b) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            b.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: available ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        available ? "Available" : "Unavailable",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: available ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    available
                        ? ElevatedButton.icon(
                            onPressed: () async {
                              final cartItem = CartItem(
                                id: '',
                                itemId: item['id'],
                                canteenId: widget.canteenId,
                                name: data['name'] ?? '',
                                price: price,
                                quantity: 1,
                                imageUrl: imageUrl,
                              );
                              await _cartService.addToCart(cartItem);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${data['name']} added to cart 🛒",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: Text(
                              "Add to Cart",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentOrange1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final price = (widget.itemData['price'] is num)
        ? (widget.itemData['price'] as num).toDouble()
        : 0.0;
    final isAvailable = widget.itemData['isAvailable'] ?? true;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_kLargePadding),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- IMAGE ----------------
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? FadeInImage.assetNetwork(
                        placeholder: 'assets/placeholder.png',
                        image: imageUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, _, __) => Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.fastfood,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 230,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.fastfood,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
              ),

              const SizedBox(height: 18),

              // ---------------- NAME + PRICE ----------------
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Rs. ${price.toStringAsFixed(0)}",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: _kAccentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // ---------------- AVAILABILITY ----------------
              Row(
                children: [
                  Icon(
                    isAvailable ? Icons.check_circle : Icons.cancel,
                    color: isAvailable ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable ? "Available" : "Currently Unavailable",
                    style: GoogleFonts.poppins(
                      color: isAvailable ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------------- DESCRIPTION ----------------
              if (description.isNotEmpty) ...[
                Text(
                  "Description",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ---------------- RATING + REVIEWS ----------------
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber[700], size: 20),
                  Icon(Icons.star, color: Colors.amber[700], size: 20),
                  Icon(Icons.star, color: Colors.amber[700], size: 20),
                  Icon(Icons.star, color: Colors.amber[700], size: 20),
                  Icon(Icons.star_half, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 6),
                  Text(
                    "4.5 (120 reviews)",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------------- BADGES ----------------
              Row(
                children: [
                  _buildBadge("Veg", Colors.green[50]!, Colors.green[800]!),
                  const SizedBox(width: 10),
                  _buildBadge("Bestseller", Colors.red[50]!, Colors.red[800]!),
                  const SizedBox(width: 10),
                  _buildBadge(
                    "🔥 Spicy",
                    Colors.orange[50]!,
                    Colors.orange[800]!,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ---------------- CALORIES + PREP TIME ----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "250 kcal",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "15 mins",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---------------- QUANTITY + ADD TO CART ----------------
              if (isAvailable)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (quantity > 1) setState(() => quantity--);
                          },
                        ),
                        Text(
                          '$quantity',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => quantity++),
                        ),
                      ],
                    ),
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
                          SnackBar(
                            content: Text("$name added to cart 🛒"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        "Add to Cart",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    "Not Available",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPER: BADGE ----------------
  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
