import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'battle_page.dart'; // Import the BattlePage
import 'search_page.dart'; // Add this import
import 'favorite_page.dart'; // Add this import
import 'about_page.dart'; // Add this import

class HomePage extends StatefulWidget {
  final String apiKey;

  const HomePage({
    super.key,
    required this.apiKey,
  }); // Accept apiKey as a required parameter

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? heroData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRandomHero();
  }

  Future<void> _fetchRandomHero() async {
    final randomId = Random().nextInt(731) + 1; // Hero IDs are 1-731
    final url = Uri.parse(
      'https://superheroapi.com/api/${widget.apiKey}/$randomId',
    ); // Use widget.apiKey

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['response'] == 'success') {
        setState(() {
          heroData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          heroData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        heroData = null;
        isLoading = false;
      });
    }
  }

  Widget _buildPowerStats(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow("🧠", stats['intelligence']),
        _buildStatRow("💪", stats['strength']),
        _buildStatRow("⚡", stats['speed']),
        _buildStatRow("🛡️", stats['durability']),
        _buildStatRow("🔥", stats['power']),
        _buildStatRow("⚔️", stats['combat']),
      ],
    );
  }

  Widget _buildStatRow(String emoji, dynamic value) {
    final int statValue = int.tryParse(value ?? '0') ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        double barMaxWidth =
            constraints.maxWidth > 350 ? 500 : constraints.maxWidth - 90;
        barMaxWidth = barMaxWidth.clamp(120, 500);
        return Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 8),
            SizedBox(
              width: barMaxWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: statValue / 100,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                  minHeight: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text("$statValue%", style: const TextStyle(fontSize: 14)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero of the Day")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("Navigation", style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              title: const Text("Home Page"),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              title: const Text("Battle Page"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BattlePage(apiKey: widget.apiKey),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text("Search Page"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(apiKey: widget.apiKey),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text("Favorites Page"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritePage(apiKey: widget.apiKey),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text("About Page"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutPage(apiKey: widget.apiKey),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : heroData == null
              ? const Center(child: Text("Failed to load hero."))
              : LayoutBuilder(
                builder: (context, constraints) {
                  bool isNarrow = constraints.maxWidth < 700;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child:
                          isNarrow
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Flexible(
                                    flex: 4,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        heroData!['image']['url'],
                                        height: 200, // Increased from 120
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => const Icon(
                                              Icons.error,
                                              size: 80, // Reduced icon size
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Flexible(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Name and Work
                                        Container(
                                          // Removed maxWidth constraint here for narrow layout
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.5,
                                                ),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                heroData!['name'],
                                                style: const TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Work: ${heroData!['work']['occupation'] ?? 'N/A'}",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Power Stats
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.5,
                                                ),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Power Stats",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              _buildPowerStats(
                                                heroData!['powerstats'],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image on the left
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      heroData!['image']['url'],
                                      height: 500, // Increased from 180
                                      width: 300, // Reduced from 250
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.error,
                                            size: 80, // Reduced icon size
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Name and Power Stats on the right
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Name and Work
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 80, // Reduced from 100
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.5,
                                                ),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                heroData!['name'],
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Work: ${heroData!['work']['occupation'] ?? 'N/A'}",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // Power Stats
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.5,
                                                ),
                                                spreadRadius: 2,
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Power Stats",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              _buildPowerStats(
                                                heroData!['powerstats'],
                                              ),
                                            ],
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
              ),
    );
  }
}
