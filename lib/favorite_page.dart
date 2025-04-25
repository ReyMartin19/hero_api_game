import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'drawer_widget.dart'; // Import the AppDrawer

class FavoritePage extends StatefulWidget {
  final String apiKey;

  const FavoritePage({super.key, required this.apiKey});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> _favorites = [];

  String currentPage = "Home"; // Track the current page for highlighting

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await DatabaseHelper.instance.getFavoriteHeroes();
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> _removeFromFavorites(dynamic id) async {
    try {
      final int heroId = id is int ? id : int.tryParse(id.toString()) ?? 0;
      if (heroId == 0) throw Exception("Invalid hero ID");

      debugPrint('Attempting to remove hero ID: $heroId');

      // 1. First remove from database
      await DatabaseHelper.instance.removeFavoriteHero(heroId);

      // 2. Then update UI
      setState(() {
        final initialCount = _favorites.length;
        _favorites.removeWhere(
          (hero) => hero['id'].toString() == heroId.toString(),
        );
        debugPrint(
          'UI update - Removed: ${initialCount - _favorites.length} items',
        );
      });

      // 3. Verify by reloading from database
      final updatedFavorites =
          await DatabaseHelper.instance.getFavoriteHeroes();
      debugPrint('Database now contains ${updatedFavorites.length} favorites');

      if (updatedFavorites.length == _favorites.length) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hero removed successfully!")),
        );
      } else {
        // If mismatch, sync UI with database
        setState(() => _favorites = updatedFavorites);
        throw Exception('Database and UI out of sync');
      }
    } catch (e) {
      debugPrint("Deletion error: $e");
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      // Reload from database on error
      _loadFavorites();
    }
  }

  Widget _buildStatRow(String label, dynamic value) {
    final int statValue = int.tryParse(value ?? '0') ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
      children: [
        SizedBox(
          width: 100, // Fixed width for the label
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: statValue / 100,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40, // Fixed width for percentage text
          child: Text(
            "$statValue%",
            style: const TextStyle(fontSize: 12, color: Colors.white),
            textAlign: TextAlign.right, // Align text to the right
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> hero) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          12,
        ), // Ensure content respects border radius
        child: Container(
          color: Colors.black, // Set container background to black
          child: Center(
            // Add Center widget to center content vertically
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Center the content vertically
              children: [
                const SizedBox(height: 16), // Add spacing above the image
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.blue.withOpacity(
                          0.6,
                        ), // Glowing blue color
                        blurRadius: 100, // Glow intensity
                        spreadRadius: 0, // Glow spread
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 80, // Set radius for the circular image
                    backgroundImage: NetworkImage(hero['image']['url']),
                    onBackgroundImageError:
                        (_, __) => const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.white,
                        ),
                  ),
                ),
                const SizedBox(height: 16), // Add spacing below the image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        hero['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Set text color to white
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        "🧠 Intelligence",
                        hero['powerstats']['intelligence'],
                      ),
                      _buildStatRow(
                        "💪 Strength",
                        hero['powerstats']['strength'],
                      ),
                      _buildStatRow("⚡ Speed", hero['powerstats']['speed']),
                      _buildStatRow(
                        "🛡️ Durability",
                        hero['powerstats']['durability'],
                      ),
                      _buildStatRow("🔥 Power", hero['powerstats']['power']),
                      _buildStatRow("⚔️ Combat", hero['powerstats']['combat']),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFromFavorites(hero['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorite Heroes")),
      drawer: AppDrawer(
        currentPage: currentPage,
        apiKey: widget.apiKey,
      ),
      body:
          _favorites.isEmpty
              ? const Center(
                child: Text(
                  "No favorite heroes yet.",
                  style: TextStyle(color: Colors.white),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    return _buildHeroCard(_favorites[index]);
                  },
                ),
              ),
    );
  }
}
