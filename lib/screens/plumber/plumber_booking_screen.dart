import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/request_repository.dart';
import '../../core/repositories/session_manager.dart';
import '../../core/services/api_service.dart';

class PlumberBookingScreen extends StatefulWidget {
  const PlumberBookingScreen({super.key});

  @override
  State<PlumberBookingScreen> createState() =>
      _PlumberBookingScreenState();
}

class _PlumberBookingScreenState
    extends State<PlumberBookingScreen> {

  final TextEditingController detailsController =
      TextEditingController();

  String selectedCategory = "Tap Issue";
  String selectedPriority = "MEDIUM";
  List<String> uploadedPhotos = [];
  File? selectedImage;

  final List<String> categories = [
    "Tap Issue",
    "Shower Issue",
    "Toilet Issue",
    "Leakage",
    "Installation",
    "Other"
  ];

  Future<void> pickImage() async {
  final picker = ImagePicker();

  final picked =
      await picker.pickImage(source: ImageSource.gallery);

  if (picked == null) return;

  final file = File(picked.path);

  setState(() {
    selectedImage = file;
  });

  try {

    final url = await ApiService.uploadPlumbingImage(file);

    uploadedPhotos.add(url);

  } catch (e) {
    print("Upload failed: $e");
  }
}

  @override
  Widget build(BuildContext context) {

    final repo = context.read<RequestRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Plumber Service"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              "Select Problem Category",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((category) {
                final isSelected =
                    selectedCategory == category;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            const Text(
              "Describe the Issue",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: detailsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Explain the problem...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Urgency Level",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: ["LOW", "MEDIUM", "HIGH"]
                  .map((priority) {
                final isSelected =
                    selectedPriority == priority;

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.red
                            : Colors.grey.shade300,
                        foregroundColor: isSelected
                            ? Colors.white
                            : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedPriority =
                              priority;
                        });
                      },
                      child: Text(priority),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            const Text(
              "Upload Image (Optional)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: selectedImage == null
                    ? const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.grey,
                        ),
                      )
                    : ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Image.file(
                          selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {

                  if (detailsController.text
                      .trim()
                      .isEmpty) {
                    return;
                  }

                  await repo.addRequest({
                    "apartmentId":
                        SessionManager.apartmentId,
                    "residentId":
                        SessionManager.userId,
                    "serviceType": "PLUMBING",
                    "problemTitle": selectedCategory,
                    "details": detailsController.text.trim(),
                    "priority": selectedPriority,
                    "flatId":
                        SessionManager.flatId,
                    "photos": uploadedPhotos 
                  });

                  Navigator.pop(context);
                },
                child: const Text(
                  "Submit Request",
                  style: TextStyle(
                      fontWeight:
                          FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}