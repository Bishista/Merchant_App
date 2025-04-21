import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Screens
import 'loyalty_crud_screen.dart';
import 'restaurant_screen.dart';
import 'profile_screen.dart';
import 'stamp_screen.dart';
import 'merchant_booking_screen.dart';
import 'merchant_qr_scanner.dart'; // ✅ new import

class LoyaltyProgramsPage extends StatefulWidget {
  const LoyaltyProgramsPage({super.key});

  @override
  _LoyaltyProgramsPageState createState() => _LoyaltyProgramsPageState();
}

class _LoyaltyProgramsPageState extends State<LoyaltyProgramsPage> {
  List<Map<String, dynamic>> loyaltyCards = [];

  @override
  void initState() {
    super.initState();
    fetchLoyaltyCardsFromAPI();
  }

  Future<void> fetchLoyaltyCardsFromAPI() async {
    final url = Uri.parse('http://10.0.2.2:8000/api/loyalty/create-card-with-reward/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        url,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          loyaltyCards = data.map<Map<String, dynamic>>((item) {
            return {
              "name": item["name"] ?? "No Name",
              "backgroundImage": item["background_image"] != null
                  ? item["background_image"].toString().startsWith("http")
                      ? item["background_image"]
                      : "http://10.0.2.2:8000${item["background_image"]}"
                  : "",
              "slotImage": item["slot_image"] != null
                  ? item["slot_image"].toString().startsWith("http")
                      ? item["slot_image"]
                      : "http://10.0.2.2:8000${item["slot_image"]}"
                  : "",
              "slotNumber": item["slot_number"] ?? 0,
              "cardId": item["id"] ?? 0,
            };
          }).toList();
        });
      } else {
        print("Failed to fetch cards: ${response.body}");
      }
    } catch (e) {
      print("Error fetching cards: $e");
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MerchantBookingScreen()),
      );
    } else if (index == 2) {
      // ✅ Open QR scanner for reward assignment
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MerchantQRScannerScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RestaurantScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          decoration: InputDecoration(
            hintText: "Search",
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[300],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black, size: 28),
            onPressed: () async {
              final updatedPrograms = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoyaltyCRUDScreen(
                    initialPrograms: loyaltyCards.map<Map<String, String>>((item) {
                      return {
                        "name": item["name"] ?? "",
                        "backgroundImage": item["backgroundImage"] ?? "",
                        "slotImage": item["slotImage"] ?? "",
                        "slotNumber": item["slotNumber"].toString(),
                        "cardId": item["cardId"].toString(),
                      };
                    }).toList(),
                  ),
                ),
              );

              if (updatedPrograms != null) {
                setState(() {
                  loyaltyCards = updatedPrograms;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              "Loyalty Programs",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: loyaltyCards.isEmpty
                ? const Center(child: Text("No loyalty programs added yet!"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: loyaltyCards.length,
                    itemBuilder: (context, index) {
                      final item = loyaltyCards[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StampScreen(
                                backgroundImage: item["backgroundImage"],
                                slotImage: item["slotImage"],
                                slotNumber: item["slotNumber"],
                                cardId: item["cardId"],
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  item["backgroundImage"],
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 100),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                item["name"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
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
}
