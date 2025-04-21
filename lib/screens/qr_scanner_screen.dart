import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;

class QRScannerScreen extends StatefulWidget {
  final Function(String) onScan;

  const QRScannerScreen({super.key, required this.onScan});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool hasScanned = false;
  final ImagePicker _picker = ImagePicker();
  final mobile.MobileScannerController _controller = mobile.MobileScannerController();

  Future<void> _scanFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final mlkit.InputImage inputImage = mlkit.InputImage.fromFilePath(image.path);
    final mlkit.BarcodeScanner barcodeScanner = mlkit.BarcodeScanner();

    try {
      final List<mlkit.Barcode> barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        final String scannedValue = barcodes.first.rawValue!;
        widget.onScan(scannedValue);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR code found in image")),
        );
      }
    } catch (e) {
      print("Error scanning from gallery: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error scanning image")),
      );
    } finally {
      barcodeScanner.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          mobile.MobileScanner(
            controller: _controller,
            onDetect: (mobile.BarcodeCapture capture) {
              if (hasScanned) return;
              final List<mobile.Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() => hasScanned = true);
                widget.onScan(barcodes.first.rawValue!);
                Navigator.pop(context);
              }
            },
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.black.withOpacity(0.5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Scan QR Code",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.white),
                    onPressed: _scanFromGallery,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
