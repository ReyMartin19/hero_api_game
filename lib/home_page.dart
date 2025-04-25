import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'drawer_widget.dart'; // Import the AppDrawer

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

  String currentPage = "Home"; // Track the current page for highlighting

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
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 30),
        ), // Increased emoji size
        const SizedBox(width: 8),
        SizedBox(
          width: 500, // Adjusted width of the percentage bar
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8), // Rounded corners
            child: LinearProgressIndicator(
              value: statValue / 100, // Normalize to a percentage (0.0 - 1.0)
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
              minHeight: 14, // Increased thickness
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text("$statValue%", style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hero of the Day")),
      drawer: AppDrawer(
        currentPage: currentPage,
        apiKey: widget.apiKey,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : heroData == null
              ? const Center(child: Text("Failed to load hero."))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  // Center the container
                  child: Container(
                    width: 950, // Adjusted width
                    height: 550, // Adjusted height
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image on the left
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            heroData!['image']['url'],
                            height: double.infinity, // Match container height
                            width: 250,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.error, size: 100),
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ), // Spacing between image and text
                        // Name and Power Stats on the right
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name and Work
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      "Work: {heroData!['work']['occupation'] ?? 'N/A'}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 24,
                              ), // Spacing below the box
                              // Power Stats
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      // ignore: deprecated_member_use
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Power Stats",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildPowerStats(heroData!['powerstats']),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}