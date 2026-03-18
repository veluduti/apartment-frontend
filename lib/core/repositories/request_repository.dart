import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'session_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../../core/models/pickup_slot_model.dart';

//////////////////////////////////////////////////////////////
// SERVICE REQUEST MODEL
//////////////////////////////////////////////////////////////

class ServiceRequest {
  final String id;
  final String serviceType;
  final String? details;
  final String status;
  final String? reason;
  final DateTime? createdAt;
  final Payment? payment;

  final String residentName;
  final String residentPhone;
  final String? flatNumber;

  final Worker? worker;
  final List<RequestStatusLog> logs;
  final String? problemTitle;
  final List<String>? photos;
  int? visitCharge;
  int? materialCharge;

  // 🔥 IRON FIELDS
  final DateTime? pickupDate;
  final String? plumberNote;
  final PickupSlot? pickupSlot;
  final bool isEscalated;
  final int totalAmount;
  final int? confirmedClothes;
  final String? bagColor;
  final List<IronItem> ironItems;
  final int? requestedClothes;
  

  final DateTime? acceptedAt;
  final DateTime? visitedAt;
  final DateTime? quotedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  ServiceRequest({
    required this.id,
    required this.serviceType,
    required this.details,
    required this.status,
    required this.createdAt,
    this.reason,
    this.plumberNote, 
    this.payment,
    this.requestedClothes,
    required this.residentName,
    required this.residentPhone,
    required this.flatNumber,
    this.worker,
    required this.logs,
    this.pickupDate,
    this.pickupSlot,
    required this.isEscalated,
    required this.totalAmount,
    this.confirmedClothes,
    this.bagColor,
    required this.ironItems,
    this.problemTitle,
    this.photos,
    this.acceptedAt,
    this.visitedAt,
    this.quotedAt,
    this.startedAt,
    this.completedAt,
    this.visitCharge,
    this.materialCharge,
    
});

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      serviceType: json['serviceType'],
      details: json['details'],
      status: json['status'],
      createdAt: json["createdAt"] != null
    ? DateTime.parse(json["createdAt"])
    : null,
      reason: json['reason'],
      residentName: json['resident']?['name'] ?? "",
      residentPhone: json['resident']?['phone'] ?? "",
      //flatNumber: json['flatNumber'] ?? "",
      flatNumber: json["flat"]?["number"] ?? "",

      worker: json["worker"] != null
          ? Worker.fromJson(json["worker"])
          : null,

      requestedClothes: json["requestedClothes"],

      problemTitle: json['plumberDetails']?['problemTitle'],
      plumberNote: json['plumberDetails']?['note'],   // ⭐ ADD THIS
      photos: json['plumberDetails']?['photos'] != null
      ? List<String>.from(json['plumberDetails']['photos'])
      : [],
      visitCharge: json['plumberDetails']?['visitCharge'] == null
    ? null
    : (json['plumberDetails']['visitCharge'] as num).toInt(),
    materialCharge: json['plumberDetails']?['materialCharge'] == null
    ? null
    : (json['plumberDetails']['materialCharge'] as num).toInt(),

      logs: json["logs"] != null
          ? (json["logs"] as List)
              .map((e) => RequestStatusLog.fromJson(e))
              .toList()
          : [],

      pickupDate: json["pickupDate"] != null
          ? DateTime.parse(json["pickupDate"])
          : null,

      pickupSlot: json["pickupSlot"] != null
          ? PickupSlot.fromJson(json["pickupSlot"])
          : null,

      isEscalated: json["isEscalated"] ?? false,

      totalAmount: json["totalAmount"] == null
      ? 0
      : (json["totalAmount"] as num).toInt(),

      payment: json['payment'] != null
          ? Payment.fromJson(json['payment'])
          : null,

      bagColor: json["bagColor"],

      ironItems: json["ironItems"] != null
          ? (json["ironItems"] as List)
              .map((e) => IronItem.fromJson(e))
              .toList()
          : [],
      confirmedClothes: json["confirmedClothes"],
      acceptedAt: json["acceptedAt"] != null
    ? DateTime.parse(json["acceptedAt"])
    : null,

visitedAt: json["visitedAt"] != null
    ? DateTime.parse(json["visitedAt"])
    : null,

quotedAt: json["quotedAt"] != null
    ? DateTime.parse(json["quotedAt"])
    : null,

startedAt: json["startedAt"] != null
    ? DateTime.parse(json["startedAt"])
    : null,

completedAt: json["completedAt"] != null
    ? DateTime.parse(json["completedAt"])
    : null,
    );
  }
}

class Payment {
  final String status;
  final int amount;

  Payment({
    required this.status,
    required this.amount,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      status: json['status'],
      amount: json['amount'] ?? 0,
    );
  }
}

class IronItem {
  final String clothType;
  final int quantity;
  final int pricePerUnit;

  IronItem({
    required this.clothType,
    required this.quantity,
    required this.pricePerUnit,
  });

  factory IronItem.fromJson(Map<String, dynamic> json) {
    return IronItem(
      clothType: json["clothType"],
      quantity: json["quantity"],
      pricePerUnit: json["pricePerUnit"],
    );
  }
}

// 🔥 NEW Worker model
class Worker {
  final String id;
  final String name;
  final String? phone;

  Worker({
    required this.id,
    required this.name,
    this.phone,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json["id"],
      name: json["name"],
      phone: json["phone"],
    );
  }
}

// 🔥 NEW Log model
class RequestStatusLog {
  final String newStatus;
  final Worker changedByUser;
  final String? note;

  RequestStatusLog({
    required this.newStatus,
    required this.changedByUser,
    this.note,
  });

  factory RequestStatusLog.fromJson(Map<String, dynamic> json) {
    return RequestStatusLog(
      newStatus: json["newStatus"],
      changedByUser:
          Worker.fromJson(json["changedByUser"]),
      note: json["note"],
    );
  }
}

class RequestRepository extends ChangeNotifier {

  List<ServiceRequest> _allRequests = [];
  List<ServiceRequest> get allRequests => _allRequests;

  // ===============================
  // FETCH
  // ===============================
  Future<void> fetchRequests() async {

    final apartmentId = SessionManager.apartmentId;
    final role = SessionManager.userRole;
    final userId = SessionManager.userId;

    if (apartmentId == null || role == null || userId == null) return;

    try {

      final response = await ApiService.getRequests(
        apartmentId,
        role,
        userId,
      );

      if (response["success"] == true) {

        final data = response["data"] as List;

        print("FULL RESPONSE DATA:");
        print(data);

        _allRequests =
            data.map((e) => ServiceRequest.fromJson(e)).toList();

        notifyListeners();
      }

    } catch (e) {
      print("FETCH ERROR: $e");
    }
  }

  // ===============================
  // CREATE
  // ===============================
  Future<bool> addRequest(Map<String, dynamic> body) async {

    try {

      final response =
          await ApiService.createRequest(body);

      print("RESPONSE FROM BACKEND:");
      print(response);

      if (response["success"] == true) {

        await fetchRequests();
        return true;
      }

      return false;

    } catch (e, stack) {
      print("🔥 CREATE ERROR:");
      print(e);
      print(stack);
      rethrow;
    }
  }

  // ===============================
  // UPDATE STATUS
  // ===============================
  Future<void> updateStatus(
    String requestId,
    String status, {
    required String userId,
    String? reason,
  }) async {

    try {

      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/requests/status"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "requestId": requestId,
          "status": status,
          "reason": reason,
          "userId": userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await fetchRequests();
      }

    } catch (e) {
      print("Update status error: $e");
    }
  }

  // ===============================
  // SOFT DELETE
  // ===============================
  Future<void> hideRequest(
      String requestId,
      String role) async {

    try {

      final response =
          await ApiService.hideRequest(
        requestId: requestId,
        role: role,
      );

      if (response["success"] == true) {
        await fetchRequests();
      }

    } catch (e) {
      print("HIDE ERROR: $e");
    }
  }
}