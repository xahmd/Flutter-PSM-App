import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'registration_form.dart';
import 'homePage.dart';
import 'land_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSM Management Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Set LandPage as initial route
      routes: {
        '/': (context) => const LandPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationForm(),
        '/home': (context) => const HomePage(),
        '/land': (context) => const LandPage(),
      },
    );
  }
}
