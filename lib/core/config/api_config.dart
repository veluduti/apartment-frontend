class ApiConfig {

  // 🔥 Change this if your system IP changes
  static const String baseUrl = "http://192.168.1.6:5000";

  // ===============================
  // USER APIs
  // ===============================

  static String checkUser({
    required String phone,
    required String apartmentId,
  }) {
    return "$baseUrl/api/users/check-user"
        "?phone=${Uri.encodeComponent(phone)}"
        "&apartmentId=$apartmentId";
  }

  static String login() {
    return "$baseUrl/api/users/login";
  }

  static String register() {
    return "$baseUrl/api/users/register";
  }

  // ===============================
  // OTP APIs (Future Use)
  // ===============================

  static String sendOtp() {
    return "$baseUrl/api/otp/send-otp";
  }

  static String verifyOtp() {
    return "$baseUrl/api/otp/verify-otp";
  }

  // ===============================
  // Requests APIs
  // ===============================

  static String createRequest() {
  return "$baseUrl/api/requests";
}

  static String getRequests() {
    return "$baseUrl/api/requests";
  }
}
