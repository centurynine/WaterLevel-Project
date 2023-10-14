import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'auth/auth_changename.dart';
import 'auth/auth_changepassword.dart';
import 'auth/auth_forgotpassword.dart';
import 'auth/auth_graphlog.dart';
import 'auth/auth_report.dart';
import 'auth/auth_setting.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/nav.dart';
import 'pages/signup.dart';
import 'utils/storage.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'การแจ้งเตือนทั่วไป', // title
  description: 'แสดงข้อมูลการแจ้งเตือนระดับน้ำ', // description
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Water Level',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Kanit',
          scaffoldBackgroundColor: Color.fromARGB(255, 240, 249, 255),
          textTheme: GoogleFonts.kanitTextTheme(),
          appBarTheme: const AppBarTheme(
            color: Color.fromARGB(255, 240, 249, 255),
            elevation: 0,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const MyHomePage(),
        routes: {
          '/home': (context) => const MyHomePage(),
          '/login': (context) => const Login(),
          '/register': (context) => const Signup(),
          '/setting': (context) => const Setting(),
          '/graph': (context) => const GraphLog(),
          '/report': (context) => const Report(),
          '/forgotpassword': (context) => const ForgotPassword(),
          '/changepassword': (context) => const ChangePassword(),
          '/changename': (context) => const ChangeName(),
        },
        builder: EasyLoading.init(),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? message;
  String channelId = "1000";
  String channelName = "แจ้งเตือนการอัปเดตแอปพลิเคชั่น";
  String channelDescription = "";
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
 
  @override
  initState() {
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('notiicon');

    var initializationSettingsIOS = DarwinInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) async {
      setState(() {
        message = payload.payload;
      });
    });
    initFirebaseMessaging();
 
    super.initState();
  }

  

  void initFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification!;
      AndroidNotification? android = message.notification?.android;
      if (android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
                android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
            )));
      }
    });
    firebaseMessaging.getToken().then((String? token) {
      assert(token != null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
    return Home(
        key: drawerKey,
        drawer: Container(
            width: MediaQuery.of(context).size.width / 1.3,
            child: const DrawerWidget()));
  }
}
