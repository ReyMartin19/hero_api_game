   import 'dart:io';
   import 'package:flutter/material.dart';
   import 'package:sqflite/sqflite.dart';
   import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Import FFI library for desktop
   import 'login_page.dart';
   import 'home_page.dart';
   import 'database_helper.dart';
   import 'battle_page.dart'; // Import BattlePage

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     // Initialize the database factory based on the platform
     if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
       databaseFactory = databaseFactoryFfi; // Use FFI for desktop
     }

     // Check for saved API key
     final apiKey = await DatabaseHelper.instance.getApiKey();

     // If the API key is null, direct the user to the login page
     runApp(HeroApiGameApp(apiKey: apiKey));
   }

class HeroApiGameApp extends StatelessWidget {
  final String? apiKey;

  const HeroApiGameApp({super.key, this.apiKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hero API Game',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute:
          apiKey == null
              ? '/login'
              : '/home', // Navigate based on saved API key
      routes: {
        '/login': (context) => const LoginPage(),
        '/home':
            (context) =>
                apiKey != null
                    ? HomePage(apiKey: apiKey!)
                    : const LoginPage(), // Ensure API key is not null before passing it
        '/battle':
            (context) => const BattlePage(
              apiKey: 'your_api_key',
            ), // Add BattlePage route
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
  