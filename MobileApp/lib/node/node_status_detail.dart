import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../pages/nav.dart';
import '../utils/authentication.dart';

class NodeStatusDetail extends StatefulWidget {
  DocumentSnapshot docs;
  NodeStatusDetail({Key? key, required this.docs}) : super(key: key);
  @override
  State<NodeStatusDetail> createState() => _NodeStatusDetailState();
}

class _NodeStatusDetailState extends State<NodeStatusDetail> {
  bool switchValueSetting = false;
  String messageDelay = "#MessageDelay";
  String uploadDelay = "#UploadDelay";
  String settingDelay = "#SettingDelay";
  String nodeDescription = "#NodeDescription";
  String valueDate = "#Date";
  String valueTime = "#Time";
  String ledvalueDate = "#Date";
  String ledvalueTime = "#Time";
  var nodeName = "#NodeName";

  String valueMessage = "";
  String valueSystem = "";
  String valueSetting = "";
  String nodeStatus = "OFF";
  String nodeInternet = "OFF";
  String voltage = "0.0";

  String lednodeStatus = "OFF";
  String lednodeInternet = "OFF";
  String ledvoltage = "0.0";
  var ledcolorNodeStatus = Colors.red;
  var ledcolorNodeInternet = Colors.red;
  var colorNodeStatus = Colors.red;
  var colorNodeInternet = Colors.red;
  double voltagePercent = 0.0;
  double ledvoltagePercent = 0.0;
  double outputLedPercent = 0.0;
  double outputLedPercentCircle = 0.0;
  double outputPercent = 0.0;
  double outputPercentCircle = 0.0;
  final _textFieldFingerprint = TextEditingController();
  final _textFieldMessage = TextEditingController();
  final _textFieldSensor = TextEditingController();
  final _textFieldSetting = TextEditingController();
  final _textNodeDescription = TextEditingController();

  final timenow = DateTime.now().toUtc().add(const Duration(hours: 7));
  final ledtimenow = DateTime.now().toUtc().add(const Duration(hours: 7));

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      setState(() {
        nodeName = widget.docs['mainName'];
      });
      getAdmin();
      checkConfigNodeDescription();
      getStatus();
      getDate();
      getledDate();
      getledStatus();
    }
    super.initState();
  }

  Future getAdmin() async {
    try {
      bool isAdmin = await adminCheck();
      if (isAdmin == true) {
        return true;
      } else {
        Navigator.pushNamed(context, '/');
      }
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
    return false;
  }

  Future<void> checkConfigNodeDescription() async {
    try {
      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeName)
          .get()
          .then((value) => setState(() {
                nodeDescription = value.data()!['description'];
              }));
      ;
    } catch (e) {
      EasyLoading.showError(e.toString());
      setState(() {
        nodeDescription = 'Error';
      });
    }
  }

  Future<void> getStatus() async {
    try {
      String status = "OFF";
      double voltagePercentText = 0.0;

      await FirebaseFirestore.instance
          .collection('node')
          .doc(widget.docs.id)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          setState(() {
            voltage = documentSnapshot['voltage'];
            status = documentSnapshot['status'];
            //convert voltage to percent max 1.0 at 12.6
            voltagePercent = double.parse(voltage) / 13.1;
            voltagePercentText = double.parse(voltage);
            voltage = double.parse(voltage).toStringAsFixed(1);
            if (voltagePercentText <= 10.7) {
              outputPercent = 0.0;
            } else if (voltagePercentText >= 13.1) {
              outputPercent = 1.0;
            } else {
              outputPercent = (voltagePercentText - 10.7) / (13.1 - 10.7);
            }
            outputPercent = outputPercent * 100;
            outputPercent = double.parse(outputPercent.toStringAsFixed(2));
            outputPercentCircle = outputPercent / 100;
            outputPercentCircle =
                double.parse(outputPercentCircle.toStringAsFixed(1));

            if (voltagePercent > 1.0) {
              voltagePercent = 1.0;
            }
            if (status == "on") {
              nodeStatus = "ON";
              colorNodeStatus = Colors.green;
            } else {
              nodeStatus = "OFF";
              colorNodeStatus = Colors.red;
            }
          });
        }
      });
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> getledStatus() async {
    try {
      String ledstatus = "OFF";
      double voltagePercentText = 0.0;
      await FirebaseFirestore.instance
          .collection('node')
          .doc(widget.docs.id)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          setState(() {
            ledvoltage = documentSnapshot['led_voltage'];
            ledstatus = documentSnapshot['led_status'];
            //convert voltage to percent max 1.0 at 12.6
            ledvoltagePercent = double.parse(ledvoltage) / 13.1;
            voltagePercentText = double.parse(ledvoltage);
            ledvoltage = double.parse(ledvoltage).toStringAsFixed(1);
            if (voltagePercentText <= 10.7) {
              outputLedPercent = 0.0;
            } else if (voltagePercentText >= 13.1) {
              outputLedPercent = 1.0;
            } else {
              outputLedPercent = (voltagePercentText - 10.7) / (13.1 - 10.7);
            }
            outputLedPercent = outputLedPercent * 100;
            outputLedPercent =
                double.parse(outputLedPercent.toStringAsFixed(2));
            outputLedPercentCircle = outputLedPercent / 100;
            outputLedPercentCircle =
                double.parse(outputLedPercentCircle.toStringAsFixed(1));

            if (ledvoltagePercent > 1.0) {
              ledvoltagePercent = 1.0;
            }
            if (ledstatus == "on") {
              lednodeStatus = "ON";
              ledcolorNodeStatus = Colors.green;
            } else {
              lednodeStatus = "OFF";
              ledcolorNodeStatus = Colors.red;
            }
          });
        }
      });
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  Future<void> getDate() async {
    try {
      String valueTimeDate = "";
      await FirebaseFirestore.instance
          .collection('node_time')
          .doc(widget.docs['mainName'])
          .get()
          .then((value) {
        if (mounted) {
          setState(() {
            valueTime = value['currentTime'];
            valueDate = value['currentDate'];
            valueTimeDate = value['currentDate'] + " " + value['currentTime'];
            DateTime timeNow =
                DateTime.now().toUtc().add(const Duration(hours: 7));
            DateTime timeNode = DateTime.parse(valueTimeDate)
                .toUtc()
                .add(const Duration(hours: 7));
            int difference = timeNow.difference(timeNode).inMinutes;
            if (difference <= 5 && difference >= -5) {
              nodeInternet = "ON";
              colorNodeInternet = Colors.green;
            } else {
              nodeInternet = "OFF";
              colorNodeInternet = Colors.red;
            }
          });
        }
      });
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> getledDate() async {
    try {
      String valueTimeDate = "";
      await FirebaseFirestore.instance
          .collection('node_time')
          .doc(widget.docs['mainName'])
          .get()
          .then((value) {
        if (mounted) {
          setState(() {
            ledvalueTime = value['ledCurrentTime'];
            ledvalueDate = value['ledCurrentDate'];
            valueTimeDate =
                value['ledCurrentDate'] + " " + value['ledCurrentTime'];
            DateTime timeNow =
                DateTime.now().toUtc().add(const Duration(hours: 7));
            DateTime timeNode = DateTime.parse(valueTimeDate)
                .toUtc()
                .add(const Duration(hours: 7));
            int difference = timeNow.difference(timeNode).inMinutes;
            if (difference <= 5 && difference >= -5) {
              lednodeInternet = "ON";
              ledcolorNodeInternet = Colors.green;
            } else {
              lednodeInternet = "OFF";
              ledcolorNodeInternet = Colors.red;
            }
          });
        }
      });
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'สถานะการใช้งาน',
          style: GoogleFonts.kanit(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            //   Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _inputDialogNodeDescription(context);
              },
              child: Text('  Node : $nodeDescription',
                  style: GoogleFonts.kanit(
                    color: Colors.black87,
                    fontSize: 20,
                  )),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Sensor MainName: ',
                              style: GoogleFonts.kanit(
                                color: Colors.black87,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                          Text(widget.docs.id,
                              style: GoogleFonts.kanit(
                                color: Colors.green,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'วันที่อัพเดทสถานะล่าสุด : ',
                            style: GoogleFonts.kanit(
                              color: Colors.black87,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            valueDate,
                            style: GoogleFonts.kanit(
                              color: Colors.green,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('เวลาที่อัพเดทสถานะล่าสุด : ',
                              style: GoogleFonts.kanit(
                                color: Colors.black87,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                          Text(valueTime,
                              style: GoogleFonts.kanit(
                                color: Colors.green,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('แรงดันไฟฟ้า',
                              style: GoogleFonts.kanit(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              )),
                          CircularPercentIndicator(
                            radius: 45.0,
                            lineWidth: 11.0,
                            percent: voltagePercent,
                            center: Text("$voltage V",
                                style: GoogleFonts.kanit(
                                  color: Colors.black87,
                                  fontSize: 15,
                                )),
                            progressColor: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('แบตเตอรี่   ',
                              style: GoogleFonts.kanit(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              )),
                          CircularPercentIndicator(
                            radius: 45.0,
                            lineWidth: 11.0,
                            percent: outputPercentCircle,
                            center: Text("$outputPercent %",
                                style: GoogleFonts.kanit(
                                  color: Colors.black87,
                                  fontSize: 15,
                                )),
                            progressColor: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('สถานะ : ',
                              style: GoogleFonts.kanit(
                                color: Colors.black87,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                          Text(nodeStatus,
                              style: GoogleFonts.kanit(
                                color: colorNodeStatus,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                          Text('การเชื่อมต่อเครือข่าย : ',
                              style: GoogleFonts.kanit(
                                color: Colors.black87,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                          Text(nodeInternet,
                              style: GoogleFonts.kanit(
                                color: colorNodeInternet,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Led MainName: ',
                                  style: GoogleFonts.kanit(
                                    color: Colors.black87,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                              Text(widget.docs.id,
                                  style: GoogleFonts.kanit(
                                    color: Colors.green,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'วันที่อัพเดทสถานะล่าสุด : ',
                                style: GoogleFonts.kanit(
                                  color: Colors.black87,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                ledvalueDate,
                                style: GoogleFonts.kanit(
                                  color: Colors.green,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('เวลาที่อัพเดทสถานะล่าสุด : ',
                                  style: GoogleFonts.kanit(
                                    color: Colors.black87,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                              Text(ledvalueTime,
                                  style: GoogleFonts.kanit(
                                    color: Colors.green,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('แรงดันไฟฟ้า',
                                  style: GoogleFonts.kanit(
                                    color: Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  )),
                              CircularPercentIndicator(
                                radius: 45.0,
                                lineWidth: 11.0,
                                percent: ledvoltagePercent,
                                center: Text("$ledvoltage V",
                                    style: GoogleFonts.kanit(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    )),
                                progressColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('แบตเตอรี่   ',
                                  style: GoogleFonts.kanit(
                                    color: Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  )),
                              CircularPercentIndicator(
                                radius: 45.0,
                                lineWidth: 11.0,
                                percent: outputLedPercentCircle,
                                center: Text("$outputLedPercent %",
                                    style: GoogleFonts.kanit(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    )),
                                progressColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('สถานะ : ',
                                  style: GoogleFonts.kanit(
                                    color: Colors.black87,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                              Text(lednodeStatus,
                                  style: GoogleFonts.kanit(
                                    color: ledcolorNodeStatus,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                              Text('การเชื่อมต่อเครือข่าย : ',
                                  style: GoogleFonts.kanit(
                                    color: Colors.black87,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                              Text(lednodeInternet,
                                  style: GoogleFonts.kanit(
                                    color: ledcolorNodeInternet,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _inputDialogNodeDescription(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไขรายละเอียด Node'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  nodeDescription = value;
                });
              },
              controller: _textNodeDescription,
              decoration: InputDecoration(hintText: nodeDescription),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('ยกเลิก'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              ElevatedButton(
                child: const Text('ตกลง'),
                onPressed: () {
                  setState(() {
                    setNodeDescription(nodeDescription);
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> setNodeDescription(String vaule) async {
    await FirebaseFirestore.instance
        .collection('node')
        .doc(nodeName)
        .update({'description': vaule});
  }
}
