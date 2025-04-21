import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'restaurant_screen.dart';
import 'profile_screen.dart';
import 'loyalty_screen.dart';

class MerchantBookingScreen extends StatefulWidget {
  const MerchantBookingScreen({super.key});

  @override
  State<MerchantBookingScreen> createState() => _MerchantBookingScreenState();
}

class _MerchantBookingScreenState extends State<MerchantBookingScreen> {
  List<dynamic> bookings = [];
  String selectedStatus = "All";
  bool isLoading = true;
  bool hasError = false;

  final List<String> statusFilters = ["All", "Confirmed", "Pending"];
  final url = Uri.parse('http://10.0.2.2:8000/api/bookings/');

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

 Future<void> fetchBookings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    log("Token used: $token");

    if (token == null || token.isEmpty) {
      log("Token missing");
      setState(() {
        hasError = true;
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    log("Response status: ${response.statusCode}");
    log("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        bookings = data;
        isLoading = false;
      });
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching bookings: $e');
    setState(() {
      hasError = true;
      isLoading = false;
    });
  }
}


  List<dynamic> get filteredBookings {
    if (selectedStatus == "All") return bookings;
    return bookings.where((b) => b["status"] == selectedStatus).toList();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoyaltyProgramsPage()));
    } else if (index == 1) {
      // Current screen
    } else if (index == 2) {
      // QR Scanner
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RestaurantScreen()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoyaltyProgramsPage()));
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Failed to load bookings'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Wrap(
                        spacing: 10,
                        children: statusFilters.map((status) {
                          final isSelected = selectedStatus == status;
                          return ChoiceChip(
                            label: Text(status),
                            selected: isSelected,
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            onSelected: (_) {
                              setState(() {
                                selectedStatus = status;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredBookings.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking['customer_name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Customer ID: ${booking['customer'] ?? ''}"),
                                  const SizedBox(height: 4),
                                  Text("Booking Time: ${booking['booking_time'] ?? ''}"),
                                  const SizedBox(height: 4),
                                  Text("Expires At: ${booking['expires_at'] ?? ''}"),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
