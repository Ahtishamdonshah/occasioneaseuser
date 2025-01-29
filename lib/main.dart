import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:occasioneaseuser/Screens/Registerationpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51PXhhWHFN9uHDd0rnxsPH6aOs7EZGAvcTRHXCQAfQbYWbf7mqejZEfAfIogri0DqDBSxVKeKd7QuO0cP2SRxwb9h008QssWoSB';
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Authentication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:
          Registrationpage(), // Set initial screen directly to RegistrationPage
    );
  }
}
