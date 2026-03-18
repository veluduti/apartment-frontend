import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/request_repository.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/service_timeline.dart';
import '../../core/repositories/session_manager.dart';
import '../chat/chat_screen.dart';

class ResidentRequestDetailsScreen extends StatelessWidget {

  final ServiceRequest request;
  const ResidentRequestDetailsScreen({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {

    final repo = context.read<RequestRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          /// =========================
          /// SERVICE TITLE
          /// =========================
          Text(
            request.problemTitle ?? "Service Request",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            request.details ?? "",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 20),

          /// =========================
          /// IMAGE
          /// =========================
          if (request.photos != null && request.photos!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                request.photos!.first,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 25),

          /// =========================
          /// TIMELINE
          /// =========================
          const Text(
            "Service Timeline",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ServiceTimeline(request: request),

          const SizedBox(height: 25),

          /// =========================
          /// QUOTE
          /// =========================
          if (request.status == "QUOTED" ||
              request.status == "IN_PROGRESS" ||
              request.status == "COMPLETED")
            _buildQuoteCard(context),

          const SizedBox(height: 20),

          /// =========================
          /// ACTION BUTTONS
          /// =========================
          if (request.status == "QUOTED")
            _buildApproveReject(context, repo),

          if (request.status == "IN_PROGRESS")
            _buildInProgress(),

          if (request.status == "COMPLETED")
            _buildCompleted(),

          const SizedBox(height: 20),

          /// =========================
          /// CHAT
          /// =========================
          if (request.status != "PENDING")
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text("Chat with Worker"),
              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      requestId: request.id,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// =========================
  /// QUOTE CARD
  /// =========================
  Widget _buildQuoteCard(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade100,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Plumber Quote",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text("Visit Charge: ₹${request.payment?.amount ?? 0}"),

          const SizedBox(height: 6),

          Text(
            "Total Amount: ₹${request.totalAmount}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// APPROVE / REJECT
  /// =========================
  Widget _buildApproveReject(
      BuildContext context,
      RequestRepository repo) {

    return Row(
      children: [

        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),

            onPressed: () async {

              await ApiService.post(
                "/plumber/approve",
                {
                  "requestId": request.id,
                  "approved": true,
                  "userId": SessionManager.userId
                },
              );

              repo.fetchRequests();
              Navigator.pop(context);
            },

            child: const Text("Approve"),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),

            onPressed: () async {

              await ApiService.post(
                "/plumber/approve",
                {
                  "requestId": request.id,
                  "approved": false,
                  "userId": SessionManager.userId
                },
              );

              repo.fetchRequests();
              Navigator.pop(context);
            },

            child: const Text("Reject"),
          ),
        ),
      ],
    );
  }

  /// =========================
  /// IN PROGRESS
  /// =========================
  Widget _buildInProgress() {

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.shade100,
      ),
      child: const Text(
        "Work is currently in progress.",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// =========================
  /// COMPLETED
  /// =========================
  Widget _buildCompleted() {

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.shade100,
      ),
      child: const Text(
        "Service completed successfully.",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}