import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../pages/nav.dart';
import '../utils/authentication.dart';
import 'node_status_detail.dart';

class NodeStatus extends StatefulWidget {
  const NodeStatus({super.key});
  @override
  State<NodeStatus> createState() => _NodeStatusState();
}

class _NodeStatusState extends State<NodeStatus> {
  Query<Map<String, dynamic>> data = FirebaseFirestore.instance
      .collection('node')
      .orderBy('created_at', descending: true);

  final _textNodeName = TextEditingController();
  String newNodeName = '';
  String newNodeID = '';
  int allNode = 0;
  int openNode = 0;
  double percent = 0;
  @override
  void initState() {
    
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getAdmin();
      countNode();
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

  Future<void> countNode() async {
    try {
    await FirebaseFirestore.instance
        .collection('node')
        .get()
        .then((value) => setState(() {
              allNode = value.docs.length;
            }));
    await FirebaseFirestore.instance
        .collection('node')
        .where('status', isEqualTo: 'on')
        .get()
        .then((value) => setState(() {
              openNode = value.docs.length;
            }));
    setState(() {
      newNodeID = 'node${(allNode + 1).toString()}';
      percent = openNode / allNode;
    });} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> checkNode() async {
    try {
    await FirebaseFirestore.instance
        .collection('node')
        .doc(newNodeName)
        .get()
        .then((value) {
      if (value.exists) {
        EasyLoading.showError('ชื่อโหนดนี้มีอยู่แล้ว');
      } else {
        createNode();
      }
    });} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> createNode() async {
    try {
      await FirebaseFirestore.instance.collection('node').doc(newNodeID).set({
        'name': newNodeID,
        'description': 'รายละเอียดโหนด',
        'status': 'off',
        'location': {
          'latitude': 0,
          'longitude': 0,
        },
        'created_at': DateTime.now().toUtc().add(const Duration(hours: 7)),
        'updated_at': DateTime.now().toUtc().add(const Duration(hours: 7)),
      });
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(newNodeID)
          .set({
        'message_title': 'แจ้งเตือนระดับน้ำ',
        'message_body': 'ระดับน้ำ',
        'message_delay': '50000',
        'restart': false,
        'setting': false,
        'setting_delay': '400000',
        'system_delay': '15000',
      });
      EasyLoading.dismiss();
      EasyLoading.showSuccess('เพิ่มโหนดสำเร็จ');
    } catch (e) {
      EasyLoading.showError('เพิ่มโหนดไม่สำเร็จ: $e');
    }
  }

  Future<void> _inputDialogNodeName(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('เพิ่ม Node :$newNodeID'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  newNodeName = value;
                });
              },
              controller: _textNodeName,
              decoration: const InputDecoration(hintText: 'รายละเอียดโหนด'),
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
                    EasyLoading.show(status: 'กำลังเพิ่มโหนด...');
                    Navigator.pop(context);
                    checkNode();
                  });
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 243, 247),
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 243, 247),
        title: const Text(' สถานะของโหนด',
            style: TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add),
        //     color: Colors.black87,
        //     onPressed: () {
        //       _inputDialogNodeName(context);
        //     },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            // make container scrollable with listview

            Container(
              height: 155,
              width: 330,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 253, 253, 253),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(50),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 3,
                    offset: const Offset(0, 2), // changes position of shadow
                  ),
                ],
              ),
              child: allNode != 0
               ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 20, left: 20),
                            child: Text(
                              'โหนดทั้งหมด',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 78, 78, 81),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 0, left: 0),
                            child: Text(
                              allNode.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 115, 114, 130),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 20, left: 20),
                            child: Text(
                              'เปิดใช้งาน',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 78, 78, 81),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 0, left: 0),
                            child: Text(
                              openNode.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 115, 114, 130),
                              ),
                            ),
                          ),
                        ],
                      ),
                      CircularPercentIndicator(
                        radius: 50.0,
                        lineWidth: 9.0,
                        percent: percent,
                        widgetIndicator: Center(
                            child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: const Color.fromARGB(255, 245, 247, 253),
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
                              padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                              child: Text(allNode.toString(),
                                  style: GoogleFonts.kanit(
                                    color: const Color.fromARGB(
                                        255, 107, 108, 190),
                                    fontSize: 30,
                                  )),
                            ),
                          ],
                        ),
                        progressColor: const Color.fromARGB(255, 78, 87, 216),
                        backgroundColor:
                            const Color.fromARGB(255, 223, 227, 246),
                      ),
                    ],
                  )
                ],
              )
              : Container(
                child: Center(child: const Text('ไม่พบข้อมูลโหนด')),
              )
            ),
            const SizedBox(
              height: 20,
            ),
            StreamBuilder<QuerySnapshot>(
              stream: data.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (snapshot.data!).docs.length,
                  itemBuilder: (context, index) {
                    //check length
                    if (snapshot.hasData == false) {
                      return const Text('ไม่มีข้อมูล');
                    }
                    var colorCard = Colors.red;
                    String status = '#สถานะ';
                    if ((snapshot.data!).docs[index]['status'] == 'off') {
                      status = 'Off';
                      colorCard = Colors.red;
                    } else if ((snapshot.data!).docs[index]['status'] == 'on') {
                      status = 'On';
                      colorCard = Colors.green;
                    } else {
                      status = 'Unknow';
                      colorCard = Colors.orange;
                    }

                    if ((snapshot.data!).docs[index]['status'] == null ||
                        (snapshot.data!).docs[index]['name'] == null) {
                      return const Text('');
                    } else {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NodeStatusDetail(
                                        docs: (snapshot.data!).docs[index],
                                      )));
                        },
                        child: Card(
                          shadowColor: Colors.black,
                          elevation: 2,
                          margin: const EdgeInsets.all(5),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            height: 130,
                            padding: const EdgeInsets.all(0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NodeStatusDetail(
                                              docs:
                                                  (snapshot.data!).docs[index],
                                            )));
                              },
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      color: colorCard,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if ((snapshot.data!).docs[index]
                                                  ['status'] ==
                                              'ปิดใช้งาน')
                                            const Icon(
                                              Icons.disabled_by_default,
                                              color: Colors.white,
                                            ),
                                          if ((snapshot.data!).docs[index]
                                                  ['status'] ==
                                              'เปิดใช้งาน')
                                            const Icon(
                                              Icons.bolt,
                                              color: Colors.white,
                                            ),
                                          Text(
                                            status,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (snapshot.data!).docs[index]
                                                ['mainName'],
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                (snapshot.data!)
                                                    .docs[index]['name'].length > 30
                                                    ? '${(snapshot.data!)
                                                    .docs[index]['name'].toString().substring(0, 30)}...'
                                                    :
                                                (snapshot.data!)
                                                    .docs[index]['name']
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54),
                                                maxLines: 3,
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                (snapshot.data!)
                                                    .docs[index]['description'].length > 30
                                                    ? '${(snapshot.data!)
                                                    .docs[index]['description'].toString().substring(0, 30)}...'
                                                    :
                                                (snapshot.data!)
                                                    .docs[index]['description']
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54),
                                                maxLines: 3,
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'สร้างเมื่อ: ',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54),
                                                maxLines: 3,
                                              ),
                                              Text(
                                                (snapshot.data!)
                                                    .docs[index]['created_at']
                                                    .toDate()
                                                    .toString()
                                                    .substring(0, 19),
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54),
                                                maxLines: 3,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}