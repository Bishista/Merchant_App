import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

List<Map<String, dynamic>> kotNotifications = [];

const String baseUrl = "http://10.0.2.2:8000/api/kots/";

Future<String?> getAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

// Load all KOTs from the API
Future<void> loadKOTs() async {
  final token = await getAuthToken();
  if (token == null) return;

  final response = await http.get(
    Uri.parse(baseUrl),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List<dynamic>;
    kotNotifications = data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['id'],
        'table': item['table'] ?? 0,
        'orders': List<String>.from(item['orders']),
        'status': item['status'] ?? 'Pending',
      };
    }).toList();

    // Remove any KOTs where table is 0 or invalid
    kotNotifications = kotNotifications.where((kot) => kot['table'] != 0).toList();
  } else {
    print("Failed to load KOTs: ${response.body}");
  }
}

// Create a new KOT via the API
Future<void> createKOT(int table, List<String> orders, {String status = "Pending"}) async {
  final token = await getAuthToken();
  if (token == null) return;

  final response = await http.post(
    Uri.parse(baseUrl),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'table': table,
      'orders': orders,
      'status': status,
    }),
  );

  if (response.statusCode == 201) {
    await loadKOTs(); // Refresh the list
  } else {
    print("Failed to create KOT: ${response.body}");
  }
}

// Update an existing KOT via the API
Future<void> updateKOTOrders(int id, List<String> updatedOrders) async {
  final token = await getAuthToken();
  if (token == null) return;

  final response = await http.put(
    Uri.parse('$baseUrl$id/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'orders': updatedOrders,
    }),
  );

  if (response.statusCode == 200) {
    await loadKOTs(); // Refresh the list
  } else {
    print("Failed to update KOT orders: ${response.body}");
  }
}

// Mark a KOT as completed via the API
Future<void> markKOTCompleted(int id) async {
  final kot = kotNotifications.firstWhere((k) => k['id'] == id, orElse: () => {});
  if (kot.isNotEmpty) {
    await updateKOTStatus(id, "Completed");
  }
}

// Update status only
Future<void> updateKOTStatus(int id, String status) async {
  final token = await getAuthToken();
  if (token == null) return;

  final kot = kotNotifications.firstWhere((k) => k['id'] == id, orElse: () => {});
  final orders = kot['orders'];

  final response = await http.put(
    Uri.parse('$baseUrl$id/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'orders': orders,
      'status': status,
    }),
  );

  if (response.statusCode == 200) {
    await loadKOTs();
  } else {
    print("Failed to update status: ${response.body}");
  }
}

// Delete a KOT using the API
Future<void> deleteKOT(int id) async {
  final token = await getAuthToken();
  if (token == null) return;

  final response = await http.delete(
    Uri.parse('$baseUrl$id/'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 204) {
    kotNotifications.removeWhere((kot) => kot['id'] == id);
  } else {
    print("Failed to delete KOT: ${response.body}");
  }
}
