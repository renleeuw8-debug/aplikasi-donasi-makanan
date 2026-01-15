// Placeholder for notifications (Firestore + FCM)
// Later: integrate firebase_messaging and topic subscriptions

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  // TODO: implement with Firebase Cloud Messaging (FCM)
  Future<void> init() async {}

  // TODO: implement sending or storing notifications in Firestore
  Future<void> sendTestNotification(String userId, String message) async {}
}
