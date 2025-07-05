import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';

typedef OnMessageCallback = void Function(RemoteMessage message);

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Logger pour cette classe
  final Logger _logger = Logger('FirebaseMessagingService');

  // Pour récupérer le token FCM unique de l'appareil
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Demander la permission (sur iOS)
  Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    _logger.info('Permission status: ${settings.authorizationStatus}');
  }

  // Initialiser les listeners avec callbacks pour sécuriser l'accès au BuildContext
  void initFirebaseMessaging({
    required OnMessageCallback onMessageReceived,
    required OnMessageCallback onMessageOpenedApp,
    required OnMessageCallback onInitialMessage,
  }) {
    // Notification reçue quand l’app est ouverte (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      onMessageReceived(message);
    });

    // Notification quand l’app est en background et que l'utilisateur clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onMessageOpenedApp(message);
    });

    // Gérer la notification quand l’app est complètement fermée (cold start)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        onInitialMessage(message);
      }
    });
  }
}
