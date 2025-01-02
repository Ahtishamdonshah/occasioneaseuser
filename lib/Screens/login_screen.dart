import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:occasioneaseuser/Screens/Registerationpage.dart';
import 'package:occasioneaseuser/Screens/home_screem.dart';
// Add your home screen

class login_screen extends StatefulWidget {
  @override
  _login_screenState createState() => _login_screenState();
}

class _login_screenState extends State<login_screen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to handle login with email and password
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Check if email is verified
        if (!userCredential.user!.emailVerified) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Please verify your email to login.";
          });
          return;
        }

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => home_screem()),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    }
  }

  // Function to handle password reset
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email to reset password.';
      });
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      // Show dialog to confirm that email is sent
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Password Reset'),
            content:
                Text('Password reset email sent. Please check your inbox.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
  }

  // Validate Email Format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Validate Password Format
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Section
                Center(
                  child: Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                SizedBox(height: 30.0),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                SizedBox(height: 16.0),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: _validatePassword,
                ),
                SizedBox(height: 24.0),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Login',
                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                        ),
                ),
                SizedBox(height: 16.0),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                SizedBox(height: 24.0),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Link to Registration screen
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Registrationpage()),
                        );
                      },
                      child: Text('Register here'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
