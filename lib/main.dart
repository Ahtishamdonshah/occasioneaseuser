import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool _isUploading = false; // Track if data is being uploaded

  // Function to create a new collection named 'hello' in Firestore
  Future<void> _createFirestoreCollection() async {
    setState(() {
      _isUploading = true; // Start showing the loader
    });

    try {
      // Reference to the Firestore collection
      CollectionReference helloCollection =
          FirebaseFirestore.instance.collection('hello');

      // Add a new document with some data
      await helloCollection.add({
        'message': 'Hello from Firebase!',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show a success message after creating the collection/document
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Collection "hello" created in Firestore!')),
      );
    } catch (e) {
      // Handle errors (e.g., network or Firestore errors)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create collection: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false; // Hide the loader once the operation is complete
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ), // Show the loading spinner while uploading
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_isUploading) {
            // Prevent double-tapping while uploading
            await _createFirestoreCollection(); // Create Firestore collection
            _incrementCounter(); // Increment the counter
          }
        },
        tooltip: 'Create Collection',
        child: const Icon(Icons.add),
      ),
    );
  }
}
