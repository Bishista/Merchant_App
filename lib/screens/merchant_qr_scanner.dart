import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MerchantQRScannerScreen extends StatefulWidget {
  const MerchantQRScannerScreen({super.key});

  @override
  State<MerchantQRScannerScreen> createState() => _MerchantQRScannerScreenState();
}

class _MerchantQRScannerScreenState extends State<MerchantQRScannerScreen> {
  bool isProcessing = false;
  final MobileScannerController controller = MobileScannerController();

  Future<void> assignReward(String phoneNumber) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://10.0.2.2:8000/api/loyalty/assign-reward/'); // 🛠️ Your reward assignment API

    try {
      final response = await http.post(
        url,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({"phone": phoneNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Reward assigned successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to assign reward: ${response.body}")),
        );
      }

      Navigator.pop(context); // go back after scan
    } catch (e) {
      print("Reward error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Error while assigning reward")),
      );
      setState(() => isProcessing = false);
    }
  }

  void handleQRDetect(BarcodeCapture capture) {
    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      controller.stop(); // ✅ stop scanning after first scan
      assignReward(code); // ⬅️ Send phone number to backend
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Invalid QR code")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Customer QR"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: handleQRDetect,
          ),
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
