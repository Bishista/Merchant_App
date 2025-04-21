import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000/api"; // Change for production

  // User Registration
  Future<Map<String, dynamic>> registerUser(String username, String email, String phone, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "phone_number": phone,
        "password": password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/verify-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "otp": otp,
      }),
    );
    return jsonDecode(response.body);
  }

  // User Login
  Future<Map<String, dynamic>> loginUser(String phone, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone_number": phone,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access']); // Store token
    }

    return jsonDecode(response.body);
  }

  // Fetch Restaurants
  Future<List<dynamic>> fetchRestaurants() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse("$baseUrl/restaurants/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  // Fetch Restaurant Details
  Future<Map<String, dynamic>> fetchRestaurantDetails(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse("$baseUrl/restaurants/$id/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }
}
