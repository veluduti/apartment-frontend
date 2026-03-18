import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/repositories/session_manager.dart';

class PlumberQuoteScreen extends StatefulWidget {
  final String requestId;

  const PlumberQuoteScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<PlumberQuoteScreen> createState() =>
      _PlumberQuoteScreenState();
}

class _PlumberQuoteScreenState extends State<PlumberQuoteScreen> {

  final visitController = TextEditingController();
  final materialController = TextEditingController();
  final noteController = TextEditingController();

  bool loading = false;

  Future<void> submitQuote() async {

    final visit = int.tryParse(visitController.text) ?? 0;
    final material = int.tryParse(materialController.text) ?? 0;

    if (visit == 0 && material == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter at least one charge"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.submitPlumberQuote({
  "requestId": widget.requestId,
  "visitCharge": visit,
  "materialCharge": material,
  "note": noteController.text,
  "userId": SessionManager.userId
});

    setState(() => loading = false);

    if (response["success"] == true) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Quote"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: visitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Visit Charge",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: materialController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Material Charge",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submitQuote,
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Submit Quote"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}