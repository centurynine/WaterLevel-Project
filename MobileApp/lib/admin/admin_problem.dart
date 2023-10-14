import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../main.dart';
import '../pages/nav.dart';
import '../utils/authentication.dart';
import 'admin_problem_detail.dart';

class Problem extends StatefulWidget {
  const Problem({super.key});
  @override
  State<Problem> createState() => _ProblemState();
}

class _ProblemState extends State<Problem> {
  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    }
    getAdmin();
    super.initState();
  }

  String filterName = "all";

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

  Query<Map<String, dynamic>> data = FirebaseFirestore.instance
      .collection('user_report')
      .orderBy('date', descending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            const Text(' รายงานปัญหา', style: TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded),
            color: const Color.fromARGB(221, 20, 19, 19),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('กรองสถานะ'),
                      content: const Text('กรุณาเลือกสถานะที่ต้องการ'),
                      actions: <Widget>[
                        Center(
                          child: Column(
                            children: [
                              ElevatedButton(
                                child: const Text('ยังไม่แก้ไข'),
                                onPressed: () {
                                  setState(() {
                                    filterName = "false";
                                  });
                                },
                              ),
                              ElevatedButton(
                                child: const Text('กำลังแก้ไข'),
                                onPressed: () {
                                  setState(() {
                                    filterName = "process";
                                  });
                                },
                              ),
                              ElevatedButton(
                                child: const Text('แก้ไขแล้ว'),
                                onPressed: () {
                                  setState(() {
                                    filterName = "true";
                                  });
                                },
                              ),
                              ElevatedButton(
                                child: const Text('ทั้งหมด'),
                                onPressed: () {
                                  setState(() {
                                    filterName = "all";
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (filterName == "all")
            ? FirebaseFirestore.instance
                .collection("user_report")
                .orderBy('date', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('user_report')
                .where('solve', isEqualTo: filterName)
                .snapshots(),
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
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
            ),
            itemCount: (snapshot.data!).docs.length,
            itemBuilder: (context, index) {
              //check length
              if (snapshot.hasData == false) {
                return const Text('ไม่มีข้อมูล');
              }
              var colorCard = Colors.red;
              String status = '#สถานะ';
              if ((snapshot.data!).docs[index]['solve'] == 'true') {
                status = 'แก้ไขแล้ว';
                colorCard = Colors.green;
              } else if ((snapshot.data!).docs[index]['solve'] == 'false') {
                status = 'ยังไม่แก้ไข';
                colorCard = Colors.red;
              } else {
                status = 'กำลังดำเนินการ';
                colorCard = Colors.orange;
              }

              if ((snapshot.data!).docs[index]['topic'] == null ||
                  (snapshot.data!).docs[index]['descript'] == null) {
                return const Text('');
              } else {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProblemDetail(
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
                                  builder: (context) => ProblemDetail(
                                        docs: (snapshot.data!).docs[index],
                                      )));
                        },
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: colorCard,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if ((snapshot.data!).docs[index]['solve'] ==
                                        'true')
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                    if ((snapshot.data!).docs[index]['solve'] ==
                                        'false')
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.white,
                                      ),
                                    if ((snapshot.data!).docs[index]['solve'] ==
                                        'process')
                                      const Icon(
                                        Icons.pending_actions,
                                        color: Colors.white,
                                      ),
                                    Text(
                                      status,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      (snapshot.data!)
                                          .docs[index]['date']
                                          .toDate()
                                          .toString()
                                          .substring(0, 10),
                                      style:
                                          const TextStyle(color: Colors.white),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (snapshot.data!).docs[index]['topic'],
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      (snapshot.data!).docs[index]['descript'],
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.black54),
                                      maxLines: 3,
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
    );
  }
}
