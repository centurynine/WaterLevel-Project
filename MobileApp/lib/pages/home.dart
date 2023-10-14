import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sizer/sizer.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../node/node_googlemap.dart';
import '../utils/error_log.dart';
import '../utils/functions.dart';
import '../utils/storage.dart';
import 'login.dart';
import 'nav.dart';
import 'signup.dart';

String distance = '0';
double distancePercent = 0;
double iconDrawerSize = 30;
FirebaseAuth auth = FirebaseAuth.instance;

String distanceTopic = 'อยู่ในเกณฑ์ปลอดภัย';
String distanceDescription = 'รถทุกประเภทสามารถผ่านได้';
String nodeID = 'node1';
String nodeName = '#ชื่อโหนด';
String nodeDescription = '#รายละเอียด';
String nodeLocalID = 'node1';
Color carColor = Colors.green;
Color sunColor = Colors.yellow;
String day = '#Day';
String time = '#Time';
String year = '#Year';
double lat = 0;
double lng = 0;
LatLng _currentLatLng = LatLng(lat, lng);
bool internetConnection = false;

const String periodNightStartTime = '19:00';
const String periodNightEndTime = '04:59';
const String periodEarlyStartTime = '05:00';
const String periodEarlyEndTime = '07:59';
const String periodMorningStartTime = '08:00';
const String periodMorningEndTime = '18:59';

class Home extends StatefulWidget {
  const Home({super.key, required Container drawer});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  UserStorage user = UserStorage();
  Future<bool> checkInternet() async {
    return await InternetConnectionChecker().hasConnection;
  }

  @override
  void initState() {
    super.initState();
    internet();
    dataReceive();
    if (FirebaseAuth.instance.currentUser != null && user.email == '#Email') {
      getUserInfo();
    }
    countNode();
    searchNodeValue();
  }

  Future<void> getUserInfo() async {
    try {
      String userName = '#Name';
      String userRole = 'false';
      String userEmail = '#Email';
      await FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .get()
          .then((value) => {
                userName = value.data()!['name'],
                userRole = value.data()!['admin'],
                userEmail = value.data()!['email'],
              });
      if (userRole == 'true') {
        user.isAdmin = true;
        user.email = userEmail;
        user.name = userName;
      } else {
        user.isAdmin = false;
        user.email = userEmail;
        user.name = userName;
      }
    } catch (e) {
      sendErrorLog('$e', 'home');
    }
  }

  Future<void> internet() async {
    bool result = await InternetConnectionChecker().hasConnection;
    while (!result) {
      await Future.delayed(const Duration(seconds: 2));
      result = await InternetConnectionChecker().hasConnection;
      if (mounted) {
        setState(() {
          internetConnection = true;
        });
      }
    }
  }

  Future<void> dataReceive() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("$nodeID/Distance");
    DatabaseEvent event = await ref.once();
    if (event.snapshot.exists) {
      if (mounted) {
        setState(() {
          distance = event.snapshot.value.toString();
          numDistance = int.parse(distance);
          if (numDistance > 80) {
            numDistance = 80;
            distance = '80';
          }
          distancePercent = (double.parse(distance) * 1.25) / 100;
          distancePercent = double.parse(distancePercent.toStringAsFixed(1));
          if (numDistance >= 0 && numDistance < 10) {
            setState(() {
              carColor = Colors.green;
              distanceTopic = 'อยู่ในเกณฑ์ปลอดภัย';
              distanceDescription = 'รถทุกประเภทสามารถผ่านได้';
            });
          } else if (numDistance >= 11 && numDistance <= 20) {
            setState(() {
              carColor = Colors.yellow;
              distanceTopic = 'อยู่ในเกณฑ์เฝ้าระวัง';
              distanceDescription = 'รถเก๋งเริ่มมีความเสี่ยง';
            });
          } else if (numDistance >= 21 && numDistance <= 40) {
            setState(() {
              carColor = Colors.orange;
              distanceTopic = 'อยู่ในเกณฑ์สุ่มเสี่ยง';
              distanceDescription =
                  'รถกระบะเริ่มมีความเสี่ยง รถเก๋งควรหลีกเลี่ยง';
            });
          } else if (numDistance >= 41 && numDistance <= 60) {
            setState(() {
              carColor = Colors.red;
              distanceTopic = 'อยู่ในเกณฑ์อันตราย';
              distanceDescription = 'รถกระบะควรหลีกเลี่ยง';
            });
          } else if (numDistance >= 61) {
            setState(() {
              carColor = Colors.red[900]!;
              distanceTopic = 'อยู่ในเกณฑ์อันตรายมาก';
              distanceDescription = 'รถทุกชนิดควรหลีกเลี่ยงการขับผ่าน';
            });
          }
        });
      }
    }
  }

  List month = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม'
  ];

  String monthName = '#เดือน';
  int nodeCount = 0;
  List listnodeDescription = [];
  List listName = [];
  List listMainName = [];
  double lat = 0;
  double lng = 0;

  int numDistance = 0;

  Future<void> countNode() async {
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('node')
          .get()
          .catchError((e) {
        sendErrorLog('$e', 'home');
      });
      final List<DocumentSnapshot> documents = result.docs;

      for (int i = 0; i < documents.length; i++) {
        try {
          if (documents[i]['mainName'] == null ||
              documents[i]['name'] == null ||
              documents[i]['description'] == null) {
            documents[i].reference.delete();
          }
        } catch (e) {
          documents[i].reference.delete();
          sendErrorLog('$e', 'home');
        }
      }

      if (mounted) {
        setState(() {
          nodeCount = documents.length;
          listnodeDescription = documents.map((e) => e['description']).toList();
          listMainName = documents.map((e) => e['mainName']).toList();
          listName = documents.map((e) => e['name']).toList();
        });
      }
    } catch (e) {
      sendErrorLog('$e', 'home');
    }
  }

  Future<void> searchNodeValue() async {
    try {
      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeID)
          .get()
          .then((value) {
        if (mounted) {
          setState(() {
            nodeDescription = value['description'];
            lat = value['location']['latitude'].toDouble();
            lng = value['location']['longitude'].toDouble();
            _currentLatLng = LatLng(lat, lng);
            nodeName = value['name'];
          });
        }
      });

      await FirebaseFirestore.instance
          .collection('node_time')
          .doc(nodeID)
          .get()
          .then((value) {
        if (mounted) {
          day = value['currentDate'];
          time = value['currentTime'];
          year = day.substring(0, 4);
          int mon = int.parse(day.substring(5, 7));
          day = '${day.substring(8, 10)} ' + month[mon - 1];
          year = (int.parse(year) + 543).toString();

          setState(() {
            if (int.parse(time.substring(0, 2)) >= 6 &&
                int.parse(time.substring(0, 2)) <= 16) {
              sunColor = Colors.yellow;
            } else {
              sunColor = Colors.grey;
            }
            day = day;
            year = year;
            time = time.substring(0, 5);
          });
        }
      });
    } catch (e) {
      sendErrorLog('$e', 'home');
    }
  }

  void _showDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('เลือกโหนด'),
            content: SizedBox(
              height: 200,
              width: 250,
              child: ListView(
                children: [
                  for (int i = 0; i < nodeCount; i++)
                    ListTile(
                      title: Text(
                          '${listMainName[i].toString().replaceAll('node', 'โหนด ')}  ${listName[i]}'),
                      onTap: () {
                        setState(() {
                          nodeID = listMainName[i];
                        });
                        dataReceive();
                        searchNodeValue();
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          );
        });
  }

  var scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 240, 241, 245),
        drawer: const DrawerWidget(),
        key: scaffoldKey,
        body: Stack(children: <Widget>[
          ListView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            children: [
              const SizedBox(
                height: 15,
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          scaffoldKey.currentState!.openDrawer();
                        },
                        child: const Icon(
                          Icons.grid_view_sharp,
                          size: 30,
                          color: Color.fromARGB(255, 36, 45, 89),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Text("แอปพลิเคชันตรวจวัดระดับน้ำ",
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontStyle: GoogleFonts.roboto().fontStyle,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 46, 66, 110),
                            )),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showDialog();
                        },
                        child: const Icon(
                          Icons.notes_rounded,
                          size: 30,
                          color: Color.fromARGB(255, 36, 45, 89),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FutureBuilder<bool>(
                future: checkInternet(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  } else if (snapshot.hasError) {
                    return Container();
                  } else if (snapshot.data == false) {
                    return Container(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      height: 50,
                      width: 100.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color.fromARGB(255, 213, 87, 87),
                      ),
                      child: Center(
                        child: Text(
                          'ไม่พบการเชื่อมต่ออินเตอร์เน็ต',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontStyle: GoogleFonts.roboto().fontStyle,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              const SizedBox(
                height: 25,
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: fetchWeatherData(lat, lng),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                        child: Text('# °C',
                                            style: TextStyle(
                                              fontSize: 50,
                                              fontStyle: GoogleFonts.roboto()
                                                  .fontStyle,
                                              color: const Color.fromARGB(
                                                  255, 46, 66, 110),
                                            ))),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                            child: Text('',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontStyle:
                                                      GoogleFonts.roboto()
                                                          .fontStyle,
                                                  color: const Color.fromARGB(
                                                      255, 46, 66, 110),
                                                ))),
                                        Container(
                                            child: Text('กำลังโหลด...',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontStyle:
                                                      GoogleFonts.roboto()
                                                          .fontStyle,
                                                  color: const Color.fromARGB(
                                                      255, 46, 66, 110),
                                                ))),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: []),
                                ),
                                Container(
                                  child: Image.asset(
                                    'assets/images/weathers/sun.png',
                                    width: 120,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ],
                    ));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('No data available'));
                  } else {
                    var weatherData = snapshot.data!;
                    var location = weatherData['location']['name'];
                    var temperature = weatherData['current']['temp_c'];
                    var condition = weatherData['current']['condition']['text'];
                    String imageName = 'sun';
                    temperature = temperature.round();
                    location ??= 'Unknown';
                    temperature ??= 'Unknown';
                    condition ??= 'Unknown';
                    if (location == 'Error' || condition == 'Error') {
                      location = 'Unknown';
                      condition = 'Unknown';
                    }
                    if (condition.contains('Sun')) {
                      imageName = 'sun';
                    } else if (condition.contains('Cloud') ||
                        condition.contains('cloud')) {
                      imageName = 'cloudy';
                    } else if (condition.contains('Cloudy') ||
                        condition.contains('cloudy')) {
                      imageName = 'cloudy';
                    } else if (condition.contains('Mist') ||
                        condition.contains('mist')) {
                      imageName = 'mist';
                    } else if (condition.contains('Rain') ||
                        condition.contains('rain')) {
                      imageName = 'rain';
                    } else if (condition.contains('Snow') ||
                        condition.contains('snow')) {
                      imageName = 'snow';
                    } else if (condition.contains('Sleet') ||
                        condition.contains('sleet')) {
                      imageName = 'sleet';
                    } else if (condition.contains('Thunder') ||
                        condition.contains('thunder')) {
                      imageName = 'thunder';
                    } else if (condition.contains('Snow') ||
                        condition.contains('snow')) {
                      imageName = 'snow';
                    } else if (condition.contains('Blizzard') ||
                        condition.contains('blizzard')) {
                      imageName = 'snow';
                    } else if (condition.contains('Fog') ||
                        condition.contains('fog')) {
                      imageName = 'fog';
                    } else if (condition.contains('Freezing Fog') ||
                        condition.contains('freezing fog')) {
                      imageName = 'fog';
                    } else if (condition.contains('Freezing Rain') ||
                        condition.contains('freezing rain')) {
                      imageName = 'freezing_rain';
                    } else if (condition.contains('Heavy Rain') ||
                        condition.contains('heavy rain')) {
                      imageName = 'heavy_rain';
                    } else if (condition.contains('Heavy Snow') ||
                        condition.contains('heavy snow')) {
                      imageName = 'snow';
                    } else {
                      imageName = 'sun';
                    }
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                        child: Text('$temperature °C',
                                            style: TextStyle(
                                              fontSize: 50,
                                              fontStyle: GoogleFonts.roboto()
                                                  .fontStyle,
                                              color: const Color.fromARGB(
                                                  255, 46, 66, 110),
                                            ))),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(location.toString(),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontStyle: GoogleFonts.roboto()
                                                  .fontStyle,
                                              color: const Color.fromARGB(
                                                  255, 46, 66, 110),
                                            )),
                                        Text(condition.toString(),
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontStyle: GoogleFonts.roboto()
                                                  .fontStyle,
                                              color: const Color.fromARGB(
                                                  255, 46, 66, 110),
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: []),
                                ),
                                Container(
                                  child: Image.asset(
                                    'assets/images/weathers/$imageName.png',
                                    width: 120,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 90.w,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.7),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(15),
                          color: const Color.fromARGB(255, 38, 46, 91),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Text("ระดับน้ำ ",
                                  style: TextStyle(
                                    fontSize: 35,
                                    fontStyle: GoogleFonts.roboto().fontStyle,
                                    color: const Color.fromARGB(
                                        255, 221, 223, 234),
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                    textAlign: TextAlign.center,
                                    nodeDescription,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontStyle: GoogleFonts.roboto().fontStyle,
                                      color: const Color.fromARGB(
                                          255, 221, 223, 234),
                                    )),
                              ),
                            ),
                            CircularPercentIndicator(
                              radius: 50.0,
                              lineWidth: 9.0,
                              percent: distancePercent,
                              widgetIndicator: Center(
                                  child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color:
                                      const Color.fromARGB(255, 255, 242, 255),
                                ),
                              )),
                              animation: true,
                              animationDuration: 1000,
                              animateFromLastPercent: true,
                              circularStrokeCap: CircularStrokeCap.round,
                              curve: Curves.easeInOut,
                              center: Column(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 15, 0, 0),
                                    child: Text(distance,
                                        style: GoogleFonts.kanit(
                                          color: const Color.fromARGB(
                                              255, 233, 233, 243),
                                          fontSize: 26,
                                        )),
                                  ),
                                  Text("ซม.",
                                      style: GoogleFonts.kanit(
                                        color: const Color.fromARGB(
                                            255, 233, 233, 243),
                                        fontSize: 17,
                                      )),
                                ],
                              ),
                              progressColor:
                                  const Color.fromARGB(255, 255, 28, 146),
                              backgroundColor:
                                  const Color.fromARGB(255, 60, 67, 108),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("วันเวลาที่วัดล่าสุด",
                                          style: TextStyle(
                                              fontSize: 14.sp,
                                              fontStyle: GoogleFonts.roboto()
                                                  .fontStyle,
                                              color: Colors.lightBlueAccent)),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Text('$day $year',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontStyle:
                                                      GoogleFonts.roboto()
                                                          .fontStyle,
                                                  color: Colors.white)),
                                          Text('$time น.',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontStyle:
                                                      GoogleFonts.roboto()
                                                          .fontStyle,
                                                  color: Colors.white)),
                                        ],
                                      ),
                                      //day or night animation added
                                      Column(
                                        children: [
                                          Container(
                                              margin:
                                                  EdgeInsets.only(left: 1.h),
                                              child: (time.compareTo(
                                                              periodNightStartTime) >=
                                                          0 ||
                                                      time.compareTo(
                                                              periodNightEndTime) <=
                                                          0)
                                                  ? Icon(
                                                      Icons.mode_night_sharp,
                                                      //fill color of the icon

                                                      size: 22.sp,
                                                      color: Colors.amber,
                                                    )
                                                  : (time.compareTo(periodEarlyStartTime) >=
                                                              0 &&
                                                          time.compareTo(
                                                                  periodEarlyEndTime) <=
                                                              0)
                                                      ? Icon(
                                                          Icons
                                                              .wb_twilight_sharp,
                                                          size: 22.sp,
                                                          color: Colors.amber,
                                                        )
                                                      : (time.compareTo(
                                                                      periodMorningStartTime) >=
                                                                  0 &&
                                                              time.compareTo(
                                                                      periodMorningEndTime) <=
                                                                  0)
                                                          ? Icon(
                                                              Icons
                                                                  .wb_sunny_sharp,
                                                              size: 22.sp,
                                                              color:
                                                                  Colors.amber,
                                                            )
                                                          : const Icon(Icons
                                                              .question_mark)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                          height: 180,
                          width: 170,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 3,
                                blurRadius: 9,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(15),
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        60, 10, 0, 10),
                                    child: Text("ข้อมูล",
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontStyle:
                                              GoogleFonts.roboto().fontStyle,
                                          color: const Color.fromARGB(
                                              255, 36, 36, 36),
                                        )),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.car_crash_rounded,
                                size: 40,
                                //half of the color size of the parent
                                color: carColor,
                              ),
                              Text(distanceTopic,
                                  style: GoogleFonts.kanit(
                                    color:
                                        const Color.fromARGB(255, 36, 36, 36),
                                    fontSize: 17,
                                  )),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                                child: Text(distanceDescription,
                                    overflow: TextOverflow.clip,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.kanit(
                                      color:
                                          const Color.fromARGB(255, 36, 36, 36),
                                      fontSize: 15,
                                    )),
                              ),
                            ],
                          )),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                          height: 180,
                          width: 170,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 3,
                                blurRadius: 9,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(15),
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        17, 15, 0, 10),
                                    child: Container(
                                      child: Image.asset(
                                        'assets/images/mask.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                  Text("ตำแหน่งที่ตั้ง",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontStyle:
                                            GoogleFonts.roboto().fontStyle,
                                        color: const Color.fromARGB(
                                            255, 36, 36, 36),
                                      )),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                child: Text(
                                    nodeDescription.length > 30
                                        ? '${nodeDescription.substring(0, 30)}...'
                                        : nodeDescription,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontStyle: GoogleFonts.roboto().fontStyle,
                                      color:
                                          const Color.fromARGB(255, 36, 36, 36),
                                    )),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(255, 56, 128, 255),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => NodeMap(
                                                location: LatLng(lat, lng),
                                                nodeName: nodeName,
                                              )),
                                    );
                                  },
                                  child: const Text('ดูแผนที่'),
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                ],
              ),
              FirebaseAuth.instance.currentUser == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: 50.0,
                        child: ListView(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            children: [
                              const SizedBox(
                                width: 20,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const Login()),
                                  );
                                },
                                child: Container(
                                  width: 145,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: const Color.fromARGB(
                                          255, 238, 225, 233)),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 3.0, right: 8.0),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            color: const Color.fromARGB(
                                                255, 244, 123, 160),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                          ),
                                        ),
                                      ),
                                      Text('เข้าสู่ระบบ',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontStyle:
                                                GoogleFonts.roboto().fontStyle,
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 46, 66, 110),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const Signup()),
                                  );
                                },
                                child: Container(
                                  width: 185,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: const Color.fromARGB(
                                          255, 223, 222, 241)),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 3.0, right: 8.0),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: const Color.fromARGB(
                                                  255, 119, 55, 204)),
                                          child: const Icon(
                                              Icons.app_registration_rounded,
                                              size: 30,
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255)),
                                        ),
                                      ),
                                      Text('สร้างบัญชีผู้ใช้',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontStyle:
                                                GoogleFonts.roboto().fontStyle,
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 46, 66, 110),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                      ),
                    )
                  : Container(),
              const SizedBox(
                height: 50,
              )
            ],
          ),
        ]));
  }
}
