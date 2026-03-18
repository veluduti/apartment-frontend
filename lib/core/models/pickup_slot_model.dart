class PickupSlot {
  final String id;
  final String type;
  final DateTime startTime;
  final DateTime endTime;

  final int maxCapacity;
  final int usedCapacity;
  final int remaining;

  PickupSlot({
    required this.id,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    required this.usedCapacity,
    required this.remaining,
  });

  factory PickupSlot.fromJson(Map<String, dynamic> json) {
    return PickupSlot(
      id: json["id"],
      type: json["type"],

      // ✅ Always convert to local time
      startTime: DateTime.parse(json["startTime"]).toLocal(),
      endTime: DateTime.parse(json["endTime"]).toLocal(),

      maxCapacity: json["maxCapacity"] ?? 0,
      usedCapacity: json["usedCapacity"] ?? 0,
      remaining: json["remaining"] ?? 0,
    );
  }
}