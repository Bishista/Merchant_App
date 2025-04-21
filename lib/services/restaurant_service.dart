import 'dart:convert';
import 'package:http/http.dart' as http;

class RestaurantService {
  static const String baseUrl = 'http://your-django-api.com/api'; // Replace with your API URL
  final String restaurantId; // Store the restaurant ID

  RestaurantService({required this.restaurantId});

  Future<Map<String, dynamic>> getRestaurantDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/$restaurantId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load restaurant details');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRestaurantMenu() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menu/?restaurant=$restaurantId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load menu');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}