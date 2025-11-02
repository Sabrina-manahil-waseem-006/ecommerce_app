import 'package:flutter/material.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final List<Map<String, String>> allCanteens = [
    {
      'name': 'DMS Canteen',
      'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5'
    },
    {
      'name': 'GCR Canteen',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836'
    },
    {
      'name': 'Staff Canteen',
      'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4'
    },
    {
      'name': 'SFC Canteen',
      'image': 'https://images.unsplash.com/photo-1528605248644-14dd04022da1'
    },
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredCanteens = allCanteens
        .where((canteen) =>
            canteen['name']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 2,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Row(
          children: [
            Text(
              'NEDEats ',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text('', style: TextStyle(fontSize: 22)),
          ],
        ),
        actions: const [
          Icon(Icons.shopping_cart_outlined, color: Colors.black),
          SizedBox(width: 10),
          Icon(Icons.account_circle_outlined, color: Colors.black),
          SizedBox(width: 15),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search canteen...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Available Canteens',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 🧊 Grid View for Canteens
            Expanded(
              child: GridView.builder(
                itemCount: filteredCanteens.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (context, index) {
                  final canteen = filteredCanteens[index];
                  return InkWell(
                    onTap: () {
                      // navigate to canteen detail page later
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              canteen['image']!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                    child: Icon(Icons.fastfood, size: 40));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              canteen['name']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
