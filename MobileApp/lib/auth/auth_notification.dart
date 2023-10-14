import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/nav.dart';
import '../utils/error_log.dart';
import 'auth_notification_detail.dart';

class AuthNotification extends StatefulWidget {
  const AuthNotification({super.key});

  @override
  State<AuthNotification> createState() => _AuthNotificationState();
}

class _AuthNotificationState extends State<AuthNotification> {
  Query<Map<String, dynamic>> data =
      FirebaseFirestore.instance.collection('node').orderBy('mainName');

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
       countNode();
    }
   
    super.initState();
  }

  int allNode = 0;
  Future<void> countNode() async {
    try {
    await FirebaseFirestore.instance
        .collection('node')
        .get()
        .then((value) => setState(() {
              allNode = value.docs.length;
            }));} catch (e) {
      sendErrorLog('$e', 'auth_notification');        
      EasyLoading.showError('เกิดข้อผิดพลาด');
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
            'ตั้งค่าการแจ้งเตือน',
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
        ),
        body: ListView(
          shrinkWrap: true,
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: allNode,
              itemBuilder: (context, index) {
                return StreamBuilder<QuerySnapshot>(
                    stream: data.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          children: [

                              SettingsItem(
                         
                                  onTap: () {
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (_) => AuthNotificationDetail(
                                              docs: snapshot.data!.docs[index],
                                            )));
                              },
                              icons: Icons.area_chart,
                              iconStyle: IconStyle(
                                withBackground: true,
                                borderRadius: 50,
                                backgroundColor: Colors.red[400],
                              ),
                              title: snapshot.data!.docs[index]['name'],
                              subtitle: snapshot.data!.docs[index]['description'],
                              titleStyle: GoogleFonts.kanit(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    });
              },
            ),
          ],
        )
        );
  }
}
