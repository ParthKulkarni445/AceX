import 'package:cf_buddy/auth_page.dart';
import 'package:cf_buddy/landing_page.dart';
import 'package:cf_buddy/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: Colors.blue,
          cursorColor: Colors.blue,
        ),
        fontFamily: 'Poppins',
        primaryColor: Colors.white,
      ),
      home: Provider.of<UserProvider>(context).user.token.isEmpty
          ? const AuthPage()
          : const LandingPage(),
    );
  }
}
