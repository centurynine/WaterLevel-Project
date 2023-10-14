import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as Math;

import '../admin/admin_function.dart';
import '../main.dart';
import '../pages/nav.dart';
import '../utils/error_log.dart';
import 'auth_function.dart';

class Report extends StatefulWidget {
  const Report({super.key});
  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? name;
  String? topicDescript;
  String topic = 'เลือกหัวข้อที่ต้องการติดต่อ';
  bool _isChecked = false;
  Map<String, dynamic>? location;
  // List of items in our dropdown menu
  var items = [
    'เลือกหัวข้อที่ต้องการติดต่อ',
    'ติดต่อผู้ดูแลระบบ',
    'ปัญหาการใช้งาน',
    'ข้อเสนอแนะ',
  ];

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getName();
      getNodeInfo();
    }

    super.initState();
  }

  Future<void> getPosision() async {
    determinePosition();
  }

  Future<void> getName() async {
    try {
    await FirebaseFirestore.instance
        .collection('user')
        .doc(auth.currentUser!.email?.trim())
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        name = documentSnapshot['name'];
      } else {
        Navigator.pushNamed(context, '/home');
      }
    });
    } catch (e) {
      sendErrorLog('$e', 'auth_report');        
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  void checkInformation() {
    if (topic == 'เลือกหัวข้อที่ต้องการติดต่อ') {
      EasyLoading.showError('กรุณาเลือกหัวข้อที่ต้องการติดต่อ');
    } else if (topicDescript == null) {
      EasyLoading.showError('กรุณากรอกรายละเอียด');
    } else {
      createReport();
    }
  }

  int allNode = 0;
  List<double> listLat = [];
  List<double> listLng = [];
  Future<void> getNodeInfo() async {
    try {
      QuerySnapshot<Map<String, dynamic>> countNode =
          await FirebaseFirestore.instance.collection('node').get();
      setState(() {
        allNode = countNode.size;
      });

      QuerySnapshot<Map<String, dynamic>> nodeInfo =
          await FirebaseFirestore.instance.collection('node').get();
      for (var doc in nodeInfo.docs) {
        double lat = doc['location']['latitude'].toDouble();
        double lng = doc['location']['longitude'].toDouble();
        try {
          listLat.add(lat);
        } catch (e) {
          listLat.add(0.0);
        }
        try {
          listLng.add(lng);
        } catch (e) {
          listLng.add(0.0);
        }
      }
    } catch (e) {
      sendErrorLog('$e', 'auth_report');
      EasyLoading.showError('เกิดข้อผิดพลาดในการเรียกตำแหน่ง');
    }
  }

  Future<void> createReport() async {
    String latitude = '0';
    String longitude = '0';
    EasyLoading.show(status: 'กำลังโหลด...');
    if (_isChecked == true) {
      try {
        Position position = await determinePosition();
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
      } catch (e) {
        if (e == 'NoPermission') {
          EasyLoading.showError('กรุณาเปิด GPS');
          return;
        }
      }
      location = {
        "latitude": latitude,
        "longitude": longitude,
      };
    } else {
      location = {
        "latitude": latitude,
        "longitude": longitude,
      };
    }
    final User? user = auth.currentUser;
    final email = user!.email;
    final dateTimeNow = DateTime.now().toUtc().add(const Duration(hours: 7));
 
    String dateTimeNowString = dateTimeNow.toString().substring(0, 24);
    String dateTime1 = dateTimeNowString.replaceAll(' ', '') ;
    String dateTime2 = dateTime1.replaceAll('-', '') ;
    String dateTime3 = dateTime2.replaceAll(':', '') ;
    String dateTime4 = dateTime3.replaceAll('.', '') ;
    await FirebaseFirestore.instance.collection('user_report').doc(
      dateTime4
    ).set({
      'email': email,
      'name': name,
      'topic': topic,
      'descript': topicDescript,
      'location': location,
      'date': dateTimeNow,
      'id': dateTime4,
      'solve': 'false',
    });
    await FirebaseMessaging.instance.subscribeToTopic(dateTime4);
    sendFCMProblem('admin', 'แจ้งเตือนแอดมิน', 'พบการแจ้งปัญหาใหม่เข้ามา');
       EasyLoading.showSuccess('ส่งข้อมูลสำเร็จ');
    Future.delayed(const Duration(seconds: 1), () {
      EasyLoading.dismiss().then((value) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return const MyApp();
        }));
      });
    });
  }

 

  var distanceInMeter = 0.0;
  Future getDistance(List lat, List lng) async {
    double PI = 3.141592653589793;
    double latitude = 0.0;
    double longitude = 0.0;
    try {
      Position position = await determinePosition();
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      if (e == 'NoPermission') {
        EasyLoading.showError('กรุณาเปิด GPS');
        return 0.0;
      }
    }
    for (var i = 0; i < allNode;) {
      double lat2 = lat[i];
      double lng2 = lng[i];
      var R = 6378.137; // Radius of earth in KM
      var dLat = lat2 * PI / 180 - latitude * PI / 180;
      var dLon = lng2 * PI / 180 - longitude * PI / 180;
      var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
          Math.cos(latitude * PI / 180) *
              Math.cos(lat2 * PI / 180) *
              Math.sin(dLon / 2) *
              Math.sin(dLon / 2);
      var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      var d = R * c;
      i++;
      double meter = d * 1000;
      if (meter <= 100) {
        return meter;
      }
      return meter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            const Text(' แจ้งปัญหา', style: TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: SizedBox(
                  height: 100,
                  child: Image.asset("assets/images/error.png"),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "          Report Problem",
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              Text(
                "             กรอกปัญหาที่พบในการใช้งาน",
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Container(
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: topicProblem()),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Container(
                    height: 200,
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                    child: problemText()),
              ),
              CheckboxListTile(
                title: const Text(
                    "ส่งตำแหน่งที่ตั้งปัจจุบัน (กรณีพบอุปกรณ์มีปัญหา)"),
                value: _isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _isChecked = value!;
                  });
                },
                controlAffinity:
                    ListTileControlAffinity.leading, //  <-- leading Checkbox
              ),
              const SizedBox(height: 20),
              Container(
                  margin: const EdgeInsets.only(left: 100.0, right: 100.0),
                  child: buildButton()),
            ]),
      ),
    );
  }

  DropdownButton<String> topicProblem() {
    return DropdownButton(
      value: topic,
      icon: const Icon(Icons.keyboard_arrow_down),
      items: items.map((String items) {
        return DropdownMenuItem(
          value: items,
          child: Text(items),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          topic = newValue!;
        });
      },
    );
  }

  TextFormField problemText() {
    return TextFormField(
      controller: nameController,
      minLines: 5,
      maxLines: 10,
      maxLength: 500,
      onChanged: (value) {
        topicDescript = value.trim();
      },
      validator: (value) {
        if (!validateUsername(value!)) {
          return 'กรุณากรอกปัญหาให้มากกว่า 6 ตัวอักษร';
        } else {
          setState(() {
            topicDescript = value;
          });
        }
        return null;
      },
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
        ),
        labelText: 'ปัญหา',
        prefixIcon: Icon(Icons.sync_problem),
        hintText: 'Your Name',
      ),
    );
  }

  ElevatedButton buildButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        primary: Colors.red[400],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      onPressed: () async {
        if (_isChecked == true) {
          distanceInMeter = await getDistance(listLat, listLng);
          if (distanceInMeter > 100) {
            EasyLoading.showError(
                'กรุณาเข้าพื้นที่ใกล้เคียงกับสถานที่ติดตั้งโหนด (100 เมตร)');
          } else {
            checkInformation();
          }
        } else {
          checkInformation();
        }
      },
      child: const Text('ส่งข้อมูล'),
    );
  }

  bool validateUsername(String value) {
    if (value.length < 6) {
      return false;
    } else {
      return true;
    }
  }
}
