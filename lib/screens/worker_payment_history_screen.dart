import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/repositories/session_manager.dart';

class WorkerPaymentHistoryScreen extends StatefulWidget {
  const WorkerPaymentHistoryScreen({super.key});

  @override
  State<WorkerPaymentHistoryScreen> createState() =>
      _WorkerPaymentHistoryScreenState();
}

class _WorkerPaymentHistoryScreenState
    extends State<WorkerPaymentHistoryScreen> {

  bool loading = true;
  List payments = [];
  int todayTotal = 0;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    final response =
        await ApiService.getWorkerPayments(
            SessionManager.userId!);

    if (response["success"]) {
      payments = response["payments"];
      todayTotal = response["todayTotal"];
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Payment History"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator())
          : Column(
              children: [

                /// ================= TODAY EARNINGS =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Today's Earnings",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹$todayTotal",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ================= PAYMENT LIST =================
                Expanded(
                  child: payments.isEmpty
                      ? const Center(
                          child:
                              Text("No payments yet"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: payments.length,
                          itemBuilder: (_, index) {

                            final payment =
                                payments[index];
                            final request =
                                payment["request"];

                            /// 🔥 Paid Time (ONLY THIS)
                            DateTime? paidAt;
                            try {
                              if (payment["paidAt"] != null) {
                                paidAt = DateTime.parse(
                                        payment["paidAt"]).toLocal();
                              }
                            } catch (_) {}

                            final formattedPaidTime =
                                paidAt != null
                                    ? DateFormat(
                                            "dd MMM yyyy | hh:mm a")
                                        .format(paidAt)
                                    : "-";

                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                      bottom: 14),
                              padding:
                                  const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(
                                        16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.04),
                                    blurRadius: 8,
                                    offset:
                                        const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  /// SERVICE + TICK
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        request[
                                                "serviceType"] ??
                                            "",
                                        style:
                                            const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      Icon(
                                        payment["status"] ==
                                                "PAID"
                                            ? Icons
                                                .check_circle
                                            : Icons
                                                .radio_button_unchecked,
                                        color:
                                            payment["status"] ==
                                                    "PAID"
                                                ? Colors
                                                    .green
                                                : Colors
                                                    .grey,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  /// FLAT NUMBER
                                  Text(
                                    "Flat: ${request["flat"]?["number"] ?? request["flatNumber"] ?? "-"}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  /// 🔥 PAID TIME ONLY
                                  Text(
                                    "Paid on: $formattedPaidTime",
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.black54,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  /// AMOUNT
                                  Text(
                                    "₹${payment["amount"]}",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}