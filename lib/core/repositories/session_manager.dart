class SessionManager {

  static String? userId;
  static String? apartmentId;
  static String? userName;
  static String? userRole;
  static String? userPhone;
  static String? flatNumber;
  static String? flatId; 
  static String? workerService;

  static void setSession({
    required String id,
    required String apartmentId,
    required String userName,
    required String userRole,
    required String flatNumber,
    required String flatId, 
    String? userPhone,
    String? workerService,
  }) {
    SessionManager.userId = id;
    SessionManager.apartmentId = apartmentId;
    SessionManager.userName = userName;
    SessionManager.userRole = userRole;
    SessionManager.userPhone = userPhone;
    SessionManager.flatNumber = flatNumber;
    SessionManager.flatId = flatId;
    SessionManager.workerService = workerService;
    
  }

  static void clearSession() {
    userId = null;
    apartmentId = null;
    userName = null;
    userRole = null;
    userPhone = null;
    flatNumber =null;
    flatId = null;
  }
}
