import '../../core/repositories/request_repository.dart'; 

class RequestEdit {
  final String id;
  final String requestId;
  final List<dynamic> items;
  final String status;
  final ServiceRequest? request;
   final String? reason;

  RequestEdit({
    required this.id,
    required this.requestId,
    required this.items,
    required this.status,
    this.request,
    this.reason,
  });

  factory RequestEdit.fromJson(Map<String, dynamic> json) {
    return RequestEdit(
      id: json["id"],
      requestId: json["requestId"],
      status: json["status"] ?? "",
      items: json["items"] ?? [],
      reason: json["reason"],
      request: json["request"] != null
          ? ServiceRequest.fromJson(json["request"])
          : null,
    );
  }
}