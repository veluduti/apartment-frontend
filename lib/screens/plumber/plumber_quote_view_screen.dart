import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/repositories/session_manager.dart';

class PlumberQuoteViewScreen extends StatefulWidget {

  final String requestId;
  final int visitCharge;
  final int materialCharge;
  final int totalAmount;
  final String? note;
  final String status;

  const PlumberQuoteViewScreen({
    super.key,
    required this.requestId,
    required this.visitCharge,
    required this.materialCharge,
    required this.totalAmount,
    this.note,
    required this.status,
  });

  @override
  State<PlumberQuoteViewScreen> createState() =>
      _PlumberQuoteViewScreenState();
}

class _PlumberQuoteViewScreenState
    extends State<PlumberQuoteViewScreen> {

  bool loading = false;

  Future<void> approve(bool approved, [String? reason]) async {

    setState(() => loading = true);

    final response = await ApiService.post(
  "/plumber/approve",
  {
    "requestId": widget.requestId,
    "approved": approved,
    "reason": reason,
    "userId": SessionManager.userId
  },
);

    setState(() => loading = false);

    if (response["success"] == true) {
      Navigator.pop(context, true);
    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action failed")),
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
              "Quote Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _row("Visit Charge", widget.visitCharge),
            _row("Material Charge", widget.materialCharge),

            const Divider(),

            _row("Total Amount", widget.totalAmount),

            if (widget.note != null) ...[
              const SizedBox(height: 10),
              Text("Note: ${widget.note}")
            ],

            const Spacer(),

            if (widget.status == "QUOTED")
Row(
  children: [

    Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
        onPressed: loading ? null : () => approve(true),
        child: loading
    ? const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : const Text("Approve"),
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
    ),
    onPressed: loading
        ? null
        : () async {

            final reasonController = TextEditingController();

            final reason = await showDialog<String>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Reject Reason"),
                content: TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: "Enter reason",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      reasonController.text.trim(),
                    ),
                    child: const Text("Submit"),
                  ),
                ],
              ),
            );

            if (reason != null && reason.trim().isNotEmpty) {
              approve(false, reason);
            }
          },
    child: const Text("Reject"),
  ),
),
  ],
)
else
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.green.withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),
  ),
  child: const Center(
    child: Text(
      "Quote already accepted",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    ),
  ),
)
          ],
        ),
      ),
    );
  }

  Widget _row(String label, int amount) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(label),
          Text("₹$amount"),
        ],
      ),
    );
  }
}