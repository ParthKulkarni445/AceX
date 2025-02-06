import 'package:cf_buddy/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final authService = AuthService();
  final storage = const FlutterSecureStorage();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiSecretController = TextEditingController();
  String? _apiKeyError;
  String? _apiSecretError;
  bool _isLoading = true;
  bool _hasCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final apiKey = await storage.read(key: 'api_key');
    final apiSecret = await storage.read(key: 'api_secret');
    
    if (apiKey != null && apiSecret != null) {
      _apiKeyController.text = apiKey;
      _apiSecretController.text = apiSecret;
      setState(() {
        _hasCredentials = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasCredentials = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCredentials() async {
    setState(() {
      _apiKeyError = _apiKeyController.text.isEmpty ? 'API Key is required' : null;
      _apiSecretError = _apiSecretController.text.isEmpty ? 'API Secret is required' : null;
    });

    if (_apiKeyError != null || _apiSecretError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await storage.write(key: 'api_key', value: _apiKeyController.text);
      await storage.write(key: 'api_secret', value: _apiSecretController.text);
      
      setState(() => _hasCredentials = true);
    } catch (e) {
      setState(() {
        _apiKeyError = 'Failed to save credentials';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCredentials() async {
    setState(() => _isLoading = true);
    
    try {
      await storage.delete(key: 'api_key');
      await storage.delete(key: 'api_secret');
      _apiKeyController.clear();
      _apiSecretController.clear();
      setState(() => _hasCredentials = false);
    } catch (e) {
      setState(() {
        _apiKeyError = 'Failed to clear credentials';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Theme(
          data:Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionHandleColor: Colors.cyan[900],
              cursorColor: Colors.cyan[900],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null 
                  ? Colors.red[400]!.withOpacity(0.5) 
                  : Colors.cyan[900]!,
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: true,
              enabled: !_hasCredentials,
              style: TextStyle(
                color: Colors.black,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(
                  icon, 
                  color: errorText != null ? Colors.red[400] : Colors.grey[600],
                  size: 20,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  void signOutUser() {
    authService.signOut(context);
  }

  Future<void> launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('Could not launch $url');
  }
}

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: Colors.cyan[900],
          surfaceTintColor: Colors.cyan[900],
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[400],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.white,
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'API Credentials',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'These credentials are required to reach the Codeforces servers to fetch sensitive information. These credentials are kept safe in the application, and are not recorded by our servers. \n\nTo find these credentials, visit the Codeforces API page, using the link below. Click on the "Add API Key" button to generate credentials, and then click "API key Info" to view them. Copy and paste the API Key and API Secret into the fields given.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => launchURL('https://codeforces.com/settings/api'),
                              child: Text(
                                '\nhttps://codeforces.com/settings/api',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.cyan[900],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildTextField(
                              controller: _apiKeyController,
                              label: 'API Key',
                              icon: Icons.vpn_key,
                              errorText: _apiKeyError,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _apiSecretController,
                              label: 'API Secret',
                              icon: Icons.lock,
                              errorText: _apiSecretError,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyan[900],
                                    elevation: 5
                                  ),
                                  onPressed: _saveCredentials,
                                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: _clearCredentials,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    elevation: 5
                                  ),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[900],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 8
                      ),
                      onPressed: signOutUser,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text('Sign Out', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
