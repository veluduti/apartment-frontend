import 'package:flutter/material.dart';
import '../../core/repositories/request_repository.dart';

class ServiceTimeline extends StatelessWidget {
  final ServiceRequest request;

  const ServiceTimeline({
    super.key,
    required this.request,
  });

  List<Map<String, dynamic>> _buildSteps() {
    return [
      {
        "title": "Request Placed",
        "completed": true,
        "date": request.createdAt,
      },
      {
        "title": "Plumber Accepted",
        "completed": request.status == "ACCEPTED" ||
            request.status == "VISITED" ||
            request.status == "QUOTED" ||
            request.status == "IN_PROGRESS" ||
            request.status == "COMPLETED",
        "date": request.acceptedAt,
      },
      {
        "title": "Visited",
        "completed": request.status == "VISITED" ||
            request.status == "QUOTED" ||
            request.status == "IN_PROGRESS" ||
            request.status == "COMPLETED",
        "date": request.visitedAt,
      },
      {
        "title": "Quote Provided",
        "completed": request.status == "QUOTED" ||
            request.status == "IN_PROGRESS" ||
            request.status == "COMPLETED",
        "date": request.quotedAt,
      },
      {
        "title": "Work In Progress",
        "completed": request.status == "IN_PROGRESS" ||
            request.status == "COMPLETED",
        "date": request.startedAt,
      },
      {
        "title": "Completed",
        "completed": request.status == "COMPLETED",
        "date": request.completedAt,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCompleted = step["completed"] as bool;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : Colors.grey.shade400,
                  ),
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? Colors.green
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      step["title"],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                    if (step["date"] != null)
                      Text(
                        step["date"]
                            .toString()
                            .substring(0, 16),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}