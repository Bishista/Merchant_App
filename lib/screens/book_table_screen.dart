import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'restaurant_screen.dart';
import 'package:http/http.dart' as http;

class BookTableScreen extends StatefulWidget {
  const BookTableScreen({super.key});

  @override
  State<BookTableScreen> createState() => _BookTableScreenState();
}

class _BookTableScreenState extends State<BookTableScreen> {
  List<Map<String, dynamic>> tableList = [];

  @override
  void initState() {
    super.initState();
    fetchTables();
  }

  Future<void> fetchTables() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/bookings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          tableList = data.map<Map<String, dynamic>>((item) {
            return {
              "number": item['table_number'] ?? 0,
              "seats": item['seats'] ?? 2,
              "reserved": item['is_reserved'] ?? false,
            };
          }).toList();
        });
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Failed to fetch tables: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 30),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const RestaurantScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Select table",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  return Container(
                    width: 100,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.grey, blurRadius: 4, offset: Offset(2, 2))
                      ],
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  itemCount: tableList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final table = tableList[index];
                    final isReserved = table["reserved"] as bool;

                    return GestureDetector(
                      onTap: () {
                        if (!isReserved) {
                          // you can add booking logic here
                          print("Table ${table['number']} selected");
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isReserved ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Table No: ${table['number']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 8),
                            Text("Total Seats: ${table['seats']}",
                                style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(isReserved ? "Reserved" : "Available",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
