import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool termsAccepted = false;
  bool isLoading = false;

  // Function to call Django API for registration
  Future<void> registerUser() async {
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept the terms and conditions.")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("http://10.0.2.2:8000/api/auth/register/"); // 10.0.2.2 for emulator
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "email": emailController.text,
          "phone_number": phoneController.text,
          "password": passwordController.text,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Login Page after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MerchantLoginScreen()),
          );
        });
      } else {
        var errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${errorData.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 20),

                TextField(controller: usernameController, decoration: InputDecoration(hintText: 'Username')),
                const SizedBox(height: 15),
                TextField(controller: emailController, decoration: InputDecoration(hintText: 'Email')),
                const SizedBox(height: 15),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: 'Phone Number')),
                const SizedBox(height: 15),
                TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(hintText: 'Password')),
                const SizedBox(height: 15),
                TextField(controller: confirmPasswordController, obscureText: true, decoration: InputDecoration(hintText: 'Confirm Password')),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Checkbox(value: termsAccepted, onChanged: (value) {
                      setState(() {
                        termsAccepted = value ?? false;
                      });
                    }),
                    const Text('I agree to the terms and conditions'),
                  ],
                ),
                const SizedBox(height: 20),

                isLoading
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF80CBC4)),
                          onPressed: registerUser,
                          child: const Text('Register', style: TextStyle(fontSize: 18, color: Colors.black)),
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
