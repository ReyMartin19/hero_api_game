import 'package:flutter/material.dart';
import 'package:hero_games/about_page.dart';

class AppDrawer extends StatelessWidget {
  final String currentPage;
  final String apiKey;

  const AppDrawer({
    super.key,
    required this.currentPage,
    required this.apiKey,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("Navigation", style: TextStyle(color: Colors.white)),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: "Home",
            isSelected: currentPage == "Home",
            onTap: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.sports_martial_arts,
            title: "Battle",
            isSelected: currentPage == "Battle",
            onTap: () {
              Navigator.pushReplacementNamed(context, '/battle');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.search,
            title: "Search",
            isSelected: currentPage == "Search",
            onTap: () {
              Navigator.pushReplacementNamed(context, '/search');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.favorite,
            title: "Favorites",
            isSelected: currentPage == "Favorites",
            onTap: () {
              Navigator.pushReplacementNamed(context, '/favorites');
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.info,
            title: "About",
            isSelected: currentPage == "About",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AboutPage(apiKey: apiKey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0x1F661FFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        textColor: isSelected ? const Color(0xFF661FFF) : null,
        onTap: onTap,
      ),
    );
  }
}