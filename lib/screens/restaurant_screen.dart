import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'loyalty_screen.dart';
import 'profile_screen.dart';
import 'order_screen.dart';
import 'merchant_booking_screen.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  List<Map<String, dynamic>> foodMenu = [];
  List<dynamic> kotNotifications = [];

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
    fetchKOTs();
  }

  Future<void> fetchMenuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/menu/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          foodMenu = data.map<Map<String, dynamic>>((item) {
            double price = double.tryParse(item["price"].toString()) ?? 0.0;
            return {
              "name": item["name"] ?? "No Name",
              "description": item["description"] ?? "",
              "price": price.toStringAsFixed(2),
              "image": item["image"] != null
                  ? item["image"].toString().startsWith("http")
                      ? item["image"]
                      : "http://10.0.2.2:8000${item["image"]}"
                  : "",
            };
          }).toList();
        });
      }
    } catch (e) {
      print("Error fetching menu: $e");
    }
  }

  Future<void> fetchKOTs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/api/kots/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          kotNotifications = data;
        });
      }
    } catch (e) {
      print("Error fetching KOTs: $e");
    }
  }

    Future<void> updateKOT(int id, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.patch(
        Uri.parse("http://10.0.2.2:8000/api/kots/$id/update_status/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"status": newStatus}),
      );

      if (response.statusCode == 200) {
        final refreshed = await http.get(
          Uri.parse("http://10.0.2.2:8000/api/kots/"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (refreshed.statusCode == 200) {
          final List<dynamic> data = jsonDecode(refreshed.body);
          setState(() {
            kotNotifications = data;
          });
        }
      } else {
        print("Failed to update KOT: ${response.body}");
      }
    } catch (e) {
      print("Error updating KOT: $e");
    }
  }


    Future<void> deleteKOT(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse("http://10.0.2.2:8000/api/kots/$id/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        final refreshed = await http.get(
          Uri.parse("http://10.0.2.2:8000/api/kots/"),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (refreshed.statusCode == 200) {
          final List<dynamic> data = jsonDecode(refreshed.body);
          setState(() {
            kotNotifications = data;
          });
        }
      } else {
        print("Failed to delete KOT: ${response.statusCode}");
      }
    } catch (e) {
      print("Error deleting KOT: $e");
    }
  }


  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoyaltyProgramsPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MerchantBookingScreen()));
    } else if (index == 2) {
      print("Scan button tapped");
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RestaurantScreen()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Food Menu"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              fetchKOTs();
              _showKOTNotifications(context);
            },
          ),
        ],
      ),
      body: foodMenu.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: foodMenu.length,
              itemBuilder: (context, index) {
                final item = foodMenu[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderScreen(
                          foodName: item['name'],
                          imagePath: item['image'],
                          price: item['price'],
                          description: item['description'],
                          tableNumber: 1,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15),
                            ),
                            child: item['image'] != ""
                                ? Image.network(
                                    item['image'],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 80),
                                  )
                                : const Icon(Icons.image_not_supported, size: 100),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'],
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text(item['description'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text("Rs. ${item['price']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ""),
          const BottomNavigationBarItem(icon: Icon(Icons.local_cafe, size: 30), label: ""),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
            ),
            label: "",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu, size: 30), label: ""),
          const BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: ""),
        ],
      ),
    );
  }

  void _showKOTNotifications(BuildContext context) {
    if (kotNotifications.isEmpty) {
      showDialog(
        context: context,
        useSafeArea: true,
        builder: (_) => const AlertDialog(
          title: Text("No KOTs"),
          content: Text("There are no active kitchen orders."),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context ) {
        return StatefulBuilder(
          builder: (context, setStateModel) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("KOT Notifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: kotNotifications.length,
                      itemBuilder: (context, index) {

                       
                        final kot = kotNotifications[index];
                        final id = kot['id'];
                        final table = kot['table_number'];
                        final itemsFormatted = kot['order_items']
                            .map((item) => "${item['item']} x${item['quantity']}")
                            .join(', ');
                        final status = kot['status'] ?? 'Pending';
                        final customer = kot['customer_name'] ?? 'Unknown';
                        final orderId = kot['order_id'] ?? '';
            
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Table No: $table", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () async {
                                                  final result = await _editKOT(context, kot);
                                                  if (result != null) {
                                                    await updateKOT(id, result['status']);
                                                    setStateModel(() {});
                                                  }
                                                },

                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                          onPressed: () async {
                                            await deleteKOT(id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text("Order ID: $orderId", style: const TextStyle(fontSize: 14)),
                                Text("Customer: $customer", style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Text("Items: $itemsFormatted", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text("Status: $status"),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _editKOT(BuildContext context, Map<String, dynamic> kot) async {
    String selectedStatus = kot['status'] ?? 'pending';

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit KOT (Table ${kot['table_number']})"),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: (value) {
              selectedStatus = value!;
            },
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {'status': selectedStatus});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
