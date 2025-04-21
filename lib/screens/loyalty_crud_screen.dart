import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LoyaltyCRUDScreen extends StatefulWidget {
  final List<Map<String, String>> initialPrograms;

  const LoyaltyCRUDScreen({super.key, required this.initialPrograms});

  @override
  _LoyaltyCRUDScreenState createState() => _LoyaltyCRUDScreenState();
}

class _LoyaltyCRUDScreenState extends State<LoyaltyCRUDScreen> {
  List<Map<String, String>> loyaltyPrograms = [];
  final TextEditingController nameController = TextEditingController();
  String? selectedImagePath; // 🔥 Store image path as a String (not File)
  int? editingIndex;

  @override
  void initState() {
    super.initState();
    loyaltyPrograms = List.from(widget.initialPrograms);
  }

  // 🔹 Pick Image from Gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImagePath = pickedFile.path; // 🔥 Store path instead of File
      });
    }
  }

  // 🔹 Add or Update Loyalty Program
  void addOrUpdateProgram() {
    String name = nameController.text.trim();

    if (name.isEmpty || selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name and select an image!")),
      );
      return;
    }

    setState(() {
      if (editingIndex == null) {
        // 🔹 Adding a new program
        loyaltyPrograms.add({
          "name": name,
          "image": selectedImagePath!,
        });
      } else {
        // 🔹 Updating existing program
        loyaltyPrograms[editingIndex!] = {
          "name": name,
          "image": selectedImagePath!,
        };
        editingIndex = null;
      }
      nameController.clear();
      selectedImagePath = null;
    });

    // 🔥 Send back updated list to `loyalty_screen.dart`
    Navigator.pop(context, loyaltyPrograms);
  }

  // 🔹 Edit Existing Program
  void editProgram(int index) {
    setState(() {
      nameController.text = loyaltyPrograms[index]["name"]!;
      selectedImagePath = loyaltyPrograms[index]["image"];
      editingIndex = index;
    });
  }

  // 🔹 Delete Existing Program
  void deleteProgram(int index) {
    setState(() {
      loyaltyPrograms.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Manage Loyalty Programs", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input: Program Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Loyalty Program Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            // Image Picker Button
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick Image from Gallery"),
            ),

            // Show Selected Image
            selectedImagePath != null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(File(selectedImagePath!), height: 100, width: 100, fit: BoxFit.cover),
                  )
                : const Text("No image selected"),

            const SizedBox(height: 10),

            // Add / Update Button
            ElevatedButton(
              onPressed: addOrUpdateProgram,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text(editingIndex == null ? "➕ Add Program" : "✏️ Update Program"),
            ),

            const SizedBox(height: 20),

            // Loyalty Programs List
            Expanded(
              child: ListView.builder(
                itemCount: loyaltyPrograms.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Image.file(
                        File(loyaltyPrograms[index]["image"]!),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(loyaltyPrograms[index]["name"]!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editProgram(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteProgram(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.pop(context, loyaltyPrograms),
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
