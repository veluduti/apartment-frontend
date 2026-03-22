import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {

  // 🔥 Make sure this IP matches your PC Ip
  static const String baseUrl = "http://192.168.1.6:5000/api";
  
  static Future<Map<String, dynamic>> getWorkersByService(String service) async {
  final response = await http.get(
    Uri.parse("$baseUrl/users/workers?service=$service"),
  );

  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> post(
  String endpoint,
  Map<String, dynamic> body,
) async {

  final response = await http.post(
    Uri.parse("$baseUrl$endpoint"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {
      "success": false,
      "message": response.body,
    };
  }
}

static Future<String> uploadPlumbingImage(File file) async {

  var request = http.MultipartRequest(
    "POST",
    Uri.parse("http://192.168.1.6:5000/upload/plumbing"),
  );

  request.files.add(
    await http.MultipartFile.fromPath(
      "image",
      file.path,
    ),
  );

  var response = await request.send();
  var res = await http.Response.fromStream(response);

  print("UPLOAD RESPONSE: ${res.body}");

  final data = jsonDecode(res.body);

  return data["url"];
}

// ===============================
// CREATE RAZORPAY ORDER
// ===============================
static Future<Map<String, dynamic>> createOrder(
    String requestId) async {

  final response = await http.post(
    Uri.parse("$baseUrl/payment/create-order"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "requestId": requestId,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {
      "success": false,
      "message": response.body,
    };
  }
}

static Future<Map<String, dynamic>> submitPlumberQuote(
    Map<String, dynamic> body) async {

  final response = await http.post(
    Uri.parse("$baseUrl/plumber/quote"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode(body),
  );

  return jsonDecode(response.body);
}

// ===============================
// GET WORKER PAYMENT HISTORY
// ===============================
static Future<Map<String, dynamic>> getWorkerPayments(
    String workerId) async {

  final response = await http.get(
    Uri.parse("$baseUrl/payment/worker/$workerId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {"success": false};
  }
}

// ===============================
// VERIFY PAYMENT
// ===============================
static Future<Map<String, dynamic>> verifyPayment(
    Map<String, dynamic> body) async {

  final response = await http.post(
    Uri.parse("$baseUrl/payment/verify"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {
      "success": false,
      "message": response.body,
    };
  }
}

static Future<Map<String, dynamic>> getAvailableSlots({
  required String apartmentId,
  required String flatId,
  required String date,
}) async {

  final response = await http.get(
    Uri.parse(
      "$baseUrl/slots/available"
      "?apartmentId=$apartmentId"
      "&flatId=$flatId"
      "&date=$date",
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {"success": false};
  }
}

static Future<Map<String, dynamic>> bookSlot(
    Map<String, dynamic> body) async {

  final response = await http.post(
    Uri.parse("$baseUrl/slots/book"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {"success": false};
  }
}

static Future<Map<String, dynamic>> getIronPricing(
    String apartmentId) async {

  final response = await http.get(
    Uri.parse("$baseUrl/iron/pricing?apartmentId=$apartmentId"),
  );

  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> getAssignedResidents(String workerId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/users/assigned-residents/$workerId"),
  );

  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> getWorkerCapacity({
  required String workerId,
  required String date,
}) async {

  final response = await http.get(
    Uri.parse(
      "$baseUrl/slots/capacity?workerId=$workerId&date=$date",
    ),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {"success": false};
  }
}

static Future<Map<String, dynamic>> setWorkerCapacity(
    Map<String, dynamic> body) async {

  final response = await http.post(
    Uri.parse("$baseUrl/slots/set-capacity"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {"success": false};
  }
}

  // ===============================
  // CREATE REQUEST
  // ===============================
  static Future<Map<String, dynamic>> createRequest(
      Map<String, dynamic> body) async {

    final response = await http.post(
      Uri.parse("$baseUrl/requests"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": response.body
    };
      //throw Exception("Create failed: ${response.body}");
    }
  }

  // ===============================
  // GET REQUESTS (ROLE BASED)
  // ===============================
  static Future<Map<String, dynamic>> getRequests(
      String apartmentId,
      String role,
      String userId) async {

    final response = await http.get(
      Uri.parse(
        "$baseUrl/requests?apartmentId=$apartmentId&role=$role&userId=$userId",
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Fetch failed: ${response.body}");
    }
  }

  // ===============================
  // SOFT HIDE (ROLE DELETE)
  // ===============================
  static Future<Map<String, dynamic>> hideRequest({
    required String requestId,
    required String role,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/requests/hide"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "requestId": requestId,
        "role": role,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Hide failed: ${response.body}");
    }
  }

  // ===============================
  // TranslateText
  // ===============================

  static Future<String?> translateText(
  String text,
  String targetLang,
) async {
  try {

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/translate/translate"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "text": text,
        "targetLang": targetLang,
      }),
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      return data["translatedText"];
    }

  } catch (e) {
    print("Translate error: $e");
  }

  return null;
}

  // ================================
// SAVE FCM TOKEN
// ================================
static Future<Map<String, dynamic>> saveToken(
    Map<String, dynamic> body) async {

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/requests/save-token"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);

  } catch (e) {
    print("SAVE TOKEN ERROR: $e");
    return {"success": false};
  }
}


  // ===============================
  // UPDATE STATUS
  // ===============================
 static Future<Map<String, dynamic>> updateStatus({
  required String requestId,
  required String status,
  required String userId,
  String? reason,
  int? confirmedClothes,
}) async {

  final response = await http.post(
    Uri.parse("$baseUrl/requests/status"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "requestId": requestId,
      "status": status,
      "reason": reason,
      "userId": userId,
      "confirmedClothes": confirmedClothes,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return {
      "success": false,
      "message": "Server error"
    };
  }
}
}