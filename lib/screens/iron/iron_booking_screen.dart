import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/session_manager.dart';
import '../../core/models/pickup_slot_model.dart';
import "../../core/services/api_service.dart";

class IronBookingScreen extends StatefulWidget {
  const IronBookingScreen({super.key});

  @override
  State<IronBookingScreen> createState() =>
      _IronBookingScreenState();
}

class _IronBookingScreenState
    extends State<IronBookingScreen> {

  DateTime selectedDate = DateTime.now();
  List<PickupSlot> slots = [];
  bool loading = false;

  List<dynamic> pricingList = [];
  Map<String, int> selectedItems = {};
  int totalAmount = 0;
  int totalClothes = 0;

  Future<void> fetchSlots() async {
    setState(() => loading = true);

    final formatted =
        DateFormat("yyyy-MM-dd").format(selectedDate);

    final response =
        await ApiService.getAvailableSlots(
      apartmentId: SessionManager.apartmentId!,
      flatId: SessionManager.flatId!,
      date: formatted,
    );

    if (response["success"]) {
      slots = (response["data"] as List)
          .map((e) => PickupSlot.fromJson(e))
          .toList();
    } else {
      slots = [];
    }

    setState(() => loading = false);
  }

  Future<void> fetchPricing() async {
    final response = await ApiService.getIronPricing(
        SessionManager.apartmentId!);

    if (response["success"]) {
      pricingList = response["data"];

      for (var item in pricingList) {
        selectedItems[item["clothType"]] = 0;
      }

      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSlots();
    fetchPricing();
  }

  void calculateTotal() {
    totalAmount = 0;
    totalClothes = 0;

    for (var item in pricingList) {
      final type = item["clothType"];
      final price = (item["price"] as num).toInt();
      final qty = selectedItems[type] ?? 0;

      totalAmount += qty * price;
      totalClothes += qty;
    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          "Iron Pickup Booking",
          style: text.titleLarge,
        ),
      ),
      body: Column(
        children: [

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selected Date",
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat("dd MMM yyyy")
                          .format(selectedDate),
                      style: text.titleMedium,
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 7)),
                    );
                    if (date != null) {
                      selectedDate = date;
                      fetchSlots();
                    }
                  },
                  child: const Text("Change"),
                )
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
                    horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Available Slots",
                style: text.titleMedium,
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),

          Expanded(
            child: slots.isEmpty
                ? Center(
                    child: Text(
                      "No slots available",
                      style: text.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 16),
                    itemCount: slots.length,
                    itemBuilder: (_, index) {
                      final slot = slots[index];

                      return Container(
                        margin:
                            const EdgeInsets.only(
                                bottom: 12),
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  theme.dividerColor),
                        ),
                        child: InkWell(
                          onTap: () =>
                              bookSlotDialog(slot),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [

                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    "${DateFormat("hh:mm a").format(slot.startTime)} - "
                                    "${DateFormat("hh:mm a").format(slot.endTime)}",
                                    style:
                                        text.titleMedium,
                                  ),
                                  const SizedBox(
                                      height: 6),
                                  Text(
                                    "Remaining: ${slot.remaining}",
                                    style:
                                        text.bodyMedium,
                                  ),
                                ],
                              ),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal:
                                            12,
                                        vertical: 6),
                                decoration:
                                    BoxDecoration(
                                  color: colors.primary
                                      .withOpacity(
                                          0.08),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                              6),
                                ),
                                child: Text(
                                  slot.type,
                                  style:
                                      text.bodyMedium
                                          ?.copyWith(
                                    color: colors
                                        .primary,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
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
    );
  }

  void bookSlotDialog(PickupSlot slot) {
    final bagController =
        TextEditingController();
    final _formKey = GlobalKey<FormState>();

    calculateTotal();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {

          final theme =
              Theme.of(context);
          final colors =
              theme.colorScheme;
          final text =
              theme.textTheme;

          return AlertDialog(
            title: Text(
              "Select Items",
              style: text.titleMedium,
            ),
            content: Form(
  key: _formKey,
  child: SizedBox(
    width: 400,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          ...pricingList.map((item) {
            final type = item["clothType"];
            final price = item["price"];
            final qty = selectedItems[type] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(type,
                          style: text.titleMedium),
                      Text("₹$price",
                          style: text.bodyMedium),
                    ],
                  ),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: qty > 0
                            ? () {
                                setStateDialog(() {
                                  selectedItems[type] =
                                      qty - 1;
                                  calculateTotal();
                                });
                              }
                            : null,
                      ),
                      Text(qty.toString(),
                          style: text.bodyLarge),
                      IconButton(
                        icon: Icon(Icons.add,
                            color: colors.primary),
                        onPressed: () {
                          setStateDialog(() {
                            selectedItems[type] =
                                qty + 1;
                            calculateTotal();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // ✅ REQUIRED BAG COLOR FIELD
          TextFormField(
            controller: bagController,
            decoration: const InputDecoration(
              labelText: "Bag Color *",
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return "Bag Color is required";
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.05),
              borderRadius:
                  BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Clothes: $totalClothes",
                  style: text.bodyLarge,
                ),
                Text(
                  "₹$totalAmount",
                  style: text.titleMedium
                      ?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),
actions: [
  TextButton(
    onPressed: () =>
        Navigator.pop(context),
    child: const Text("Cancel"),
  ),
  ElevatedButton(
    onPressed: () async {

      // ✅ VALIDATE FORM FIRST
      if (!_formKey.currentState!
          .validate()) {
        return;
      }

      final items = pricingList
          .where((item) =>
              (selectedItems[
                          item["clothType"]] ??
                      0) >
                  0)
          .map((item) => {
                "clothType":
                    item["clothType"],
                "quantity":
                    selectedItems[
                        item["clothType"]]
              })
          .toList();

      if (items.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
                "Select at least one item"),
          ),
        );
        return;
      }

      final response =
          await ApiService.bookSlot({
        "slotId": slot.id,
        "residentId":
            SessionManager.userId,
        "apartmentId":
            SessionManager.apartmentId,
        "flatId":
            SessionManager.flatId,
        "bagColor":
            bagController.text,
        "items": items
      });

      Navigator.pop(context);

      if (response["success"]) {

        for (var key
            in selectedItems.keys) {
          selectedItems[key] = 0;
        }
        calculateTotal();

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text("Booking Confirmed"),
          ),
        );

        fetchSlots();

      } else {

        if (response["type"] ==
            "CAPACITY_FULL") {
          showEscalationDialog(slot);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                  response["message"] ??
                      "Booking failed"),
            ),
          );
        }
      }
    },
    child: const Text(
        "Confirm Booking"),
  ),
],
          );
        },
      ),
    );
  }

  // ================= ESCALATION DIALOG =================
  void showEscalationDialog(PickupSlot slot) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Slot Full"),
        content: const Text(
          "Primary worker slot is full.\n\n"
          "Would you like to send request to other workers?"
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              suggestNextDay();
            },
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await escalateToOtherWorkers(slot);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  // ================= ESCALATE REQUEST =================

  Future<void> escalateToOtherWorkers(PickupSlot slot) async {

  final items = pricingList
      .where((item) =>
          (selectedItems[item["clothType"]] ?? 0) > 0)
      .map((item) => {
            "clothType": item["clothType"],
            "quantity":
                selectedItems[item["clothType"]]
          })
      .toList();

  if (items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Select at least one item"),
      ),
    );
    return;
  }

  final response = await ApiService.bookSlot({
    "slotId": slot.id,
    "residentId": SessionManager.userId,
    "apartmentId": SessionManager.apartmentId,
    "flatId": SessionManager.flatId,
    "items": items,
    "isEscalated": true
  });

  if (response["success"]) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Request sent to other workers"),
      ),
    );

    fetchSlots();

  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response["message"] ?? "Failed"),
      ),
    );
  }
}

  // ================= SUGGEST NEXT DAY =================
  void suggestNextDay() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please try booking next available day."),
      ),
    );
  }
}