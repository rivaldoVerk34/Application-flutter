import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import 'pages/auth_page.dart';
import 'pages/home_page.dart';

// Logger global pour ce fichier
final Logger _logger = Logger('Main');

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage m) async {
  await Firebase.initializeApp();
  _logger.info('BG Notification: ${m.messageId}');
}

void main() async {
  // Initialisation du logger global
  Logger.root.level = Level.ALL; // Affiche tous les niveaux de logs
  Logger.root.onRecord.listen((record) {
    // Tu peux personnaliser la sortie ici, par exemple vers un fichier, console, etc.
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final Logger _logger = Logger('MyAppState');

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final auth = FirebaseAuth.instance.currentUser;

    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    if (auth != null) {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('fcmTokens').doc(auth.uid).set({
          'token': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _logger.info('FCM token saved for user ${auth.uid}');
      }
    }

    FirebaseMessaging.onMessage.listen((msg) {
      if (msg.notification != null) {
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(content: Text('${msg.notification!.title}: ${msg.notification!.body}')),
        );
        _logger.info('Foreground notification received: ${msg.notification!.title}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _logger.info('Notification tapped with data: ${msg.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Music App',
      scaffoldMessengerKey: _scaffoldKey,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.hasData ? const HomePage() : const AuthPage();
      },
    );
  }
}
