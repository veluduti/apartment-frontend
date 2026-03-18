import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/repositories/session_manager.dart';

class ResidentQuoteScreen extends StatelessWidget {
  final String requestId;
  final int visitCharge;
  final int materialCharge;
  final int totalAmount;
  final String? note;

  const ResidentQuoteScreen({
    super.key,
    required this.requestId,
    required this.visitCharge,
    required this.materialCharge,
    required this.totalAmount,
    this.note,
  });

  Future<void> approveQuote(BuildContext context, bool approved) async {

    final response = await ApiService.post(
      "/plumber/approve",
      {
        "requestId": requestId,
        "approved": approved,
        "userId": SessionManager.userId
      },
    );

    if (response["success"] == true) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? "Quote Approved"
                : "Quote Rejected",
          ),
        ),
      );

      Navigator.pop(context);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"] ?? "Action failed",
          ),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Plumber Quote"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Repair Estimate",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Visit Charge"),
                Text("₹$visitCharge"),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Material Charge"),
                Text("₹$materialCharge"),
              ],
            ),

            const Divider(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "₹$totalAmount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (note != null && note!.isNotEmpty)
              Text("Note: $note"),

            const Spacer(),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () =>
                        approveQuote(context, false),
                    child: const Text("Reject"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        approveQuote(context, true),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}