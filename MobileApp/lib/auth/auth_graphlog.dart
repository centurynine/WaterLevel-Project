import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:collection/collection.dart';

import '../pages/nav.dart';
import '../utils/error_log.dart';

class GraphLog extends StatefulWidget {
  const GraphLog({super.key});

  @override
  State<GraphLog> createState() => _GraphLogState();
}

class _GraphLogState extends State<GraphLog> {
  String dropdownvalue = 'มกราคม';

  int dropdownFirstDay = 1;
  int dropdownLastDay = 31;

  int dropdownFirstHour = 0;
  int dropdownLastHour = 23;
  String nodeSelect = 'node1';
  var selectFirstHour = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
  ];
  var selectLastHour = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
  ];
  String month = '#เดือน';
  String timeDate = '';
  var dropdownNode = 'เลือกโหนด';
   
  var selectMonth = [
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
  int selectDay = 31;
  var selectFirstDay = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
  ];
  var selectLastDay = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
  ];
  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getNode();
    }

    super.initState();
  }

  Map<String, dynamic>? data;
  Map<String, dynamic>? time;

  List<dynamic> dataLog = [];
  List<dynamic> dataTime = [];
  List<_DataLog> dataLogGrap = [];
  List<dynamic> dataTimeShow = [];
  var nodeName = ['เลือกโหนด'];
  var selectedNode = ['เลือกโหนด'];
  var mainName = '';
  var nodeDescription = [''];
  int allNode = 0;
 
Future<void> getNode() async {
  try {
    final result = await FirebaseFirestore.instance.collection('node').get();

    for (int i = 0; i < result.docs.length; i++) {
      try {
        if ( result.docs[i].data()['name'] != null || result.docs[i].data()['mainName'] != null || result.docs[i].data()['description'] != null)
        {  
        print(nodeName);
        nodeName.add(result.docs[i].data()['name']);
        selectedNode.add(result.docs[i].data()['mainName']);
        nodeDescription.add(result.docs[i].data()['description']);
        }
       
        else {
        nodeName.add("Node");
        selectedNode.add("node1");
        nodeDescription.add("Node");
        }
      } catch (e) {
        sendErrorLog('$e', 'auth_graphlog');
        selectedNode.add("node${i+1}");
        EasyLoading.showError('ตรวจพบข้อผิดพลาดในโหนด ${i+1}');
         
      }
    }
      setState(() {
        nodeName = nodeName;
        selectedNode = selectedNode;
      });
    } catch (e) {
      sendErrorLog('$e', 'auth_graphlog');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }


  Future<void> searchData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('node_log_$mainName')
          .get();
      List allData = querySnapshot.docs.map((doc) => doc.data()).toList();
      for (int i = 0; i < allData.length; i++) {}
      for (var element in allData) {
        for (int i = dropdownFirstDay; i <= dropdownLastDay; i++) {
          String timeDateSearch = '${timeDate}_${i.toString().padLeft(2, '0')}';
          String timeDateGraph = '${i.toString().padLeft(2, '0')} ';
          if (element[timeDateSearch] != null) {
            for (int i = dropdownFirstHour; i <= dropdownLastHour; i++) {
              String timeSearch = i.toString().padLeft(2, '0');
              if (element[timeDateSearch]['H_$timeSearch'] != null) {
                String vauleTime = 'วันที่ $timeDateGraph $timeSearch:00';
                int valueDistance = int.parse(element[timeDateSearch]['H_$timeSearch']);
                dataLog.add(_DataLog(vauleTime, valueDistance));
              } else {}
            }
          } else {}
        }
        updaeGraph();
      }
    } catch (e) {
      sendErrorLog('$e', 'auth_graphlog');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }

    EasyLoading.dismiss();
  }

  Future<void> updaeGraph() async {
    try {
      setState(() {
        dataLog.sort((a, b) => a.time.compareTo(b.time));
        dataLogGrap = dataLog.cast<_DataLog>();
      });
      if (dataLogGrap.isEmpty) {
        EasyLoading.showError('ไม่พบข้อมูล');
      } else {
        EasyLoading.showSuccess('โหลดข้อมูลเรียบร้อย');
      }
    } catch (e) {
      sendErrorLog('$e', 'auth_graphlog');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

 
  DropdownButton<String> topicNode() {
    return DropdownButton(
      alignment: Alignment.center,
      underline: const SizedBox(),
      value: dropdownNode,
      icon: const Icon(Icons.keyboard_arrow_down),
      items: nodeName.map((String nodeName) {
        return DropdownMenuItem(
          value: nodeName,
          child: Text(nodeName),
        );
      }).toList(),
      onChanged: (String? newValue) {
        for (int i = 0; i < nodeName.length; i++) {
          if (nodeName[i] == newValue) {
            setState(() {
              mainName = selectedNode[i];
            });
          }
        }
        if (dropdownNode != newValue) {
          EasyLoading.show(status: 'กำลังโหลด...');
          dataLog.clear();
          setState(() {
            dropdownNode = newValue!;
           
          });
          searchData();
        }
      },
    );
  }

  DropdownButton<String> topicMonth() {
    return DropdownButton(
      underline: const SizedBox(),
      value: dropdownvalue,
      icon: const Icon(Icons.keyboard_arrow_down),
      items: selectMonth.map((String selectMonth) {
        return DropdownMenuItem(
          value: selectMonth,
          child: Text(selectMonth),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (dropdownvalue != newValue) {
          EasyLoading.show(status: 'กำลังโหลด...');
          dataLog.clear();
          setState(() {
            month = newValue!;
          });
          if (newValue == 'มกราคม') {
            setState(() {
              timeDate = 'D_2023_01';
            });
            searchData();
          } else if (newValue == 'กุมภาพันธ์') {
            setState(() {
              timeDate = 'D_2023_02';
            });
            searchData();
          } else if (newValue == 'มีนาคม') {
            setState(() {
              timeDate = 'D_2023_03';
            });
            searchData();
          } else if (newValue == 'เมษายน') {
            setState(() {
              timeDate = 'D_2023_04';
            });
            searchData();
          } else if (newValue == 'พฤษภาคม') {
            setState(() {
              timeDate = 'D_2023_05';
            });
            searchData();
          } else if (newValue == 'มิถุนายน') {
            setState(() {
              timeDate = 'D_2023_06';
            });
            searchData();
          } else if (newValue == 'กรกฎาคม') {
            setState(() {
              timeDate = 'D_2023_07';
            });
            searchData();
          } else if (newValue == 'สิงหาคม') {
            setState(() {
              timeDate = 'D_2023_08';
            });
            searchData();
          } else if (newValue == 'กันยายน') {
            setState(() {
              timeDate = 'D_2023_09';
            });
            searchData();
          } else if (newValue == 'ตุลาคม') {
            setState(() {
              timeDate = 'D_2023_10';
            });
            searchData();
          } else if (newValue == 'พฤศจิกายน') {
            setState(() {
              timeDate = 'D_2023_11';
            });
            searchData();
          } else if (newValue == 'ธันวาคม') {
            setState(() {
              timeDate = 'D_2023_12';
            });
            searchData();
          }
          setState(() {
            dropdownvalue = newValue!;
          });
        }
      },
    );
  }

  DropdownButton<int> topicFirstDay() {
    return DropdownButton(
      value: dropdownFirstDay,
      icon: const Icon(Icons.keyboard_arrow_down),
      items: selectFirstDay.map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (dropdownFirstDay != newValue) {
          dataLog.clear();
          setState(() {
            dropdownFirstDay = newValue!;
          });
          searchData();
        }
      },
    );
  }

  DropdownButton<int> topicLastDay() {
    return DropdownButton(
      value: dropdownLastDay,
      icon: const Icon(Icons.keyboard_arrow_down),
      items: selectLastDay.map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (dropdownLastDay != newValue) {
          dataLog.clear();
          setState(() {
            dropdownLastDay = newValue!;
          });
          searchData();
        }
      },
    );
  }

  DropdownButton<int> topicFirstHour() {
    return DropdownButton(
      value: dropdownFirstHour,
      icon: const Icon(Icons.keyboard_arrow_down),
      items: selectFirstHour.map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (dropdownFirstHour != newValue) {
          dataLog.clear();
          setState(() {
            dropdownFirstHour = newValue!;
          });

          searchData();
        }
      },
    );
  }

  DropdownButton<int> topicLastHour() {
    return DropdownButton(
      value: dropdownLastHour,
      icon: const Icon(Icons.keyboard_arrow_down),
      items: selectLastHour.map((int value) {
        return DropdownMenuItem<int>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
      onChanged: (int? newValue) {
        if (dropdownLastHour != newValue) {
          dataLog.clear();
          setState(() {
            dropdownLastHour = newValue!;
          });

          searchData();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'กราฟระดับน้ำ',
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
            Navigator.pop(context);
          },
        ),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                          margin: const EdgeInsets.only(top: 180),
                          child: RotationTransition(
                            turns: const AlwaysStoppedAnimation(270 / 360),
                            child: Text("ระดับน้ำ",
                                style: GoogleFonts.kanit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                )),
                          )),
                      Container(
                        margin: const EdgeInsets.only(left: 25),
                        width: 90.w,
                        height: 370,
                        child: SfCartesianChart(
                            plotAreaBorderWidth: 2,
                            trackballBehavior: TrackballBehavior(
                                enable: true,
                                activationMode: ActivationMode.singleTap,
                                tooltipSettings: InteractiveTooltip(
                                    enable: true,
                                    color: Colors.white,
                                    textStyle: GoogleFonts.kanit(
                                      fontSize: 15,
                                    ))),
                            enableAxisAnimation: true,
                            zoomPanBehavior: ZoomPanBehavior(
                                enablePinching: true,
                                enablePanning: true,
                                enableDoubleTapZooming: true,
                                enableSelectionZooming: true,
                                enableMouseWheelZooming: true),
                            primaryXAxis: CategoryAxis(),
                            title: ChartTitle(
                                text: 'ปริมาณระดับน้ำเดือน $month 2566',
                                textStyle: GoogleFonts.kanit(
                                  fontSize: 17,
                                )),
                            legend: Legend(isVisible: false),
                            tooltipBehavior: TooltipBehavior(
                              enable: true,
                              header: 'ปริมาณระดับน้ำ',
                              format: 'point.x point.y cm',
                              textStyle: GoogleFonts.kanit(
                                fontSize: 12,
                              ),
                              duration: 4000,
                              elevation: 10,
                            ),
                            series: <ChartSeries<_DataLog, String>>[
                              LineSeries<_DataLog, String>(
                                markerSettings: const MarkerSettings(
                                  isVisible: true,
                                  shape: DataMarkerType.circle,
                                  borderWidth: 2,
                                  borderColor:
                                      Color.fromARGB(179, 228, 228, 228),
                                  color: Colors.blue,
                                ),
                                xAxisName: 'Time',
                                yAxisName: 'Value',
                                dataSource: dataLogGrap,
                                xValueMapper: (_DataLog data, _) =>
                                    '   ${data.time} น.',
                                yValueMapper: (_DataLog data, _) => data.value,
                                name: 'Node 1',
                                dataLabelSettings: DataLabelSettings(
                                  textStyle: GoogleFonts.kanit(
                                    fontSize: 12,
                                  ),
                                  isVisible: true,
                                ),
                                color: Colors.blue,
                                width: 2,
                              ),
                            ]),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 360, left: 200),
                        child: Text('วัน/เวลา',
                            style: GoogleFonts.kanit(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            height: 400,
            margin: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text('เลือกโหนด',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                          )),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          margin:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Center(child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: topicNode(),
                          ))),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text('เลือกเดือน',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                          )),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          margin:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Center(child: topicMonth())),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text('เลือกวันที่',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                          )),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          margin:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Center(child: topicFirstDay())),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text('ถึง',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          margin:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Center(child: topicLastDay())),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text('เลือกชั่วโมง',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                          )),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          margin:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Center(child: topicFirstHour())),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text('ถึง',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(
                                    0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          margin:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Center(child: topicLastHour())),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          )
        ],
      ),
    );
  }
}

class _DataLog {
  _DataLog(this.time, this.value);
  final String time;
  final int value;
}
