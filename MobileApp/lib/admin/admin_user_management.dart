import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../main.dart';
import '../pages/nav.dart';
import '../utils/authentication.dart';
import 'admin_problem_detail.dart';
import 'admin_user_detail.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});
  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  int allUser = 0;
  int adminLength = 0;
  String stringallUser = '0';
  String stringAdminLength = '0';
  double percentage = 0.0;
  String name_lowercase = "";
  String name_uppercase = "";
  String name = "";
  Query<Map<String, dynamic>> data = FirebaseFirestore.instance
      .collection('user')
      .orderBy('created_at', descending: true);

  //search users function

  Future<void> countFunction() async {
    try {
      QuerySnapshot querySnapshotNoti = await FirebaseFirestore.instance
          .collection('user')
          .where('admin', isEqualTo: 'true')
          .get();
      setState(() {
        adminLength = querySnapshotNoti.docs.length;
        stringAdminLength = querySnapshotNoti.docs.length.toString();
      });
      QuerySnapshot querySnapshotAllUser =
          await FirebaseFirestore.instance.collection('user').get();
      if (mounted) {
        setState(() {
          allUser = querySnapshotAllUser.docs.length;
          stringallUser = querySnapshotAllUser.docs.length.toString();
        });
      }
      percentage = adminLength / allUser;
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getAdmin();
      countFunction();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 243, 247),
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 243, 247),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Container(
            height: 47,
            width: MediaQuery.of(context).size.width - 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.black87),
                  hintText: 'ค้นหาผู้ใช้',
                  hintStyle: GoogleFonts.kanit(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  contentPadding: EdgeInsets.only(top: 10.0)),
              onChanged: (val) {
                setState(() {
                  name_lowercase = val.toLowerCase();
                  name_uppercase = val.toUpperCase();
                  name = val;
                });
              },
            ),
          ),
        ),
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
              height: 170,
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
              child: allUser != 0  
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
                              'ผู้ใช้ทั้งหมด ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 78, 78, 81),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 0, left: 0),
                            child: Text(
                              stringallUser,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 115, 114, 130),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 20, left: 20),
                            child: Text(
                              'ผู้ใช้ที่เป็นแอดมิน',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 78, 78, 81),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 0, left: 0),
                            child: Text(
                              stringAdminLength,
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
                        percent: percentage,
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
                              padding: const EdgeInsets.fromLTRB(0, 25, 0, 0),
                              child: Text(stringAdminLength,
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
                child: Center(child: const Text('ไม่พบข้อมูลผู้ใช้')),
              )
            ),
            const SizedBox(
              height: 30,
            ),
            StreamBuilder<QuerySnapshot>(
              stream: (name != "")
                  ? FirebaseFirestore.instance
                      .collection('user')
                      .where('email',
                          isGreaterThanOrEqualTo: name,
                          isLessThan: name.substring(0, name.length - 1) +
                              String.fromCharCode(
                                  name.codeUnitAt(name.length - 1) + 1))
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection("user")
                      .orderBy('created_at', descending: true)
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
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: (snapshot.data!).docs.length,
                  itemBuilder: (context, index) {
                    //check length
                    if (snapshot.hasData == false) {
                      return const Text('ไม่มีข้อมูล');
                    }
                    var colorCard = Colors.red;
                    String status = '#สถานะ';
                    if ((snapshot.data!).docs[index]['admin'] == 'true') {
                      status = 'Admin';
                      colorCard = Colors.red;
                    } else if ((snapshot.data!).docs[index]['admin'] ==
                        'false') {
                      status = 'User';
                      colorCard = Colors.green;
                    } else {
                      status = 'Unknow';
                      colorCard = Colors.orange;
                    }

                    if ((snapshot.data!).docs[index]['email'] == null ||
                        (snapshot.data!).docs[index]['name'] == null) {
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
                                        builder: (context) => UserDetail(
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
                                                  ['admin'] ==
                                              'true')
                                            const Icon(
                                              Icons.admin_panel_settings,
                                              color: Colors.white,
                                            ),
                                          if ((snapshot.data!).docs[index]
                                                  ['admin'] ==
                                              'false')
                                            const Icon(
                                              Icons.person_sharp,
                                              color: Colors.white,
                                            ),
                                          Text(
                                            status,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
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
                                                ['email'],
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                'Name: ',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54),
                                                maxLines: 3,
                                              ),
                                              Text(
                                                (snapshot.data!).docs[index]
                                                    ['name'],
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
                                                'ID: ',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54),
                                                maxLines: 3,
                                              ),
                                              Text(
                                                (snapshot.data!)
                                                    .docs[index]['id']
                                                    .toString(),
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
