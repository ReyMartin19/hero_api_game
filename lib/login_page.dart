import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database_helper.dart';
import 'home_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _validateApiKey() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final apiKey = _apiKeyController.text.trim();
    final url = Uri.parse("https://superheroapi.com/api/$apiKey/1");

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['response'] == 'success') {
        // Save API key to local storage
        await DatabaseHelper.instance.saveApiKey(apiKey);

        // Proceed to Home Page
        if (context.mounted) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(builder: (context) => HomePage(apiKey: apiKey)),
          );
        }
      } else {
        setState(() {
          _errorText = 'Invalid API Key';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300.0, // Adjusted width
                child: TextField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    errorText: _errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _validateApiKey,
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
