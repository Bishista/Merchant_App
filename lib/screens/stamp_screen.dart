import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StampScreen extends StatefulWidget {
  final String backgroundImage;
  final String slotImage;
  final int slotNumber;
  final int cardId;

  const StampScreen({
    super.key,
    required this.backgroundImage,
    required this.slotImage,
    required this.slotNumber,
    required this.cardId,
  });

  @override
  State<StampScreen> createState() => _StampScreenState();
}

class _StampScreenState extends State<StampScreen> {
  final TextEditingController _phoneController = TextEditingController();
  int selectedQuantity = 1;

  void submitStamp() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number.")),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing auth token")),
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8000/api/loyalty/issue-stamp/');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'phone': phone,
      'card_id': widget.cardId,
      'stamp': selectedQuantity,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$selectedQuantity stamp(s) assigned to $phone")),
        );
        _phoneController.clear();
        setState(() => selectedQuantity = 1);
      } else {
        print("Stamp issue failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to assign stamps")),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error assigning stamps")),
      );
    }
  }

  void _startQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onScan: (String scannedPhone) {
            Navigator.pop(context);
            setState(() {
              _phoneController.text = scannedPhone;
            });
            submitStamp(); // auto-submit after scan
          },
        ),
      ),
    );
  }

  Widget buildStampButton(int number) {
    final bool isSelected = selectedQuantity == number;
    return GestureDetector(
      onTap: () => setState(() => selectedQuantity = number),
      child: Container(
        alignment: Alignment.center,
        width: 60,
        height: 60,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.amber,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Loyalty"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.backgroundImage,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Use either by Mobile Number or QR Code", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone),
                      hintText: "Enter number",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _startQRScanner,
                  icon: const Icon(Icons.qr_code_scanner, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Stamp Quantity", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(widget.slotNumber, (index) => buildStampButton(index + 1)),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitStamp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerScreen({super.key, required this.onScan});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.black,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (hasScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            setState(() => hasScanned = true);
            widget.onScan(barcodes.first.rawValue!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to scan QR Code')),
            );
          }
        },
      ),
    );
  }
}
