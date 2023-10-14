import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/nav.dart';
import '../utils/error_log.dart';
class AuthNotificationDetail extends StatefulWidget {
  DocumentSnapshot docs;
  AuthNotificationDetail({Key? key, required this.docs}) : super(key: key);

  @override
  State<AuthNotificationDetail> createState() => _AuthNotificationDetailState();
}

class _AuthNotificationDetailState extends State<AuthNotificationDetail> {
  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
     checkFCMTokenFirebaseAvailable();
     countNotification();
    }

    super.initState();
    
  }

  List nodeName = [''];
  List nodeDescription = [''];
  var allNotification;
  int countAllNotification = 0;
  List levelWater = [];
  bool finished = false;
  bool switchNotification = false;

  List<dynamic> nodeAllNoti = [];
 


  void _showDialog(String text) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Center(child: Text('Error')),
            content: SizedBox(
              height: 150,
              width: 250,
              child: ListView(
                
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                        ),
                      ),
                                        const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('ตกลง'),
                  
                  )
                    ],
                  ),
 
                ],
              ),
            ),
          );
        });
  }

  Future<void> checkFCMTokenFirebaseAvailable() async{
    try {
    await FirebaseFirestore.instance
        .collection('user_notification')
        .doc(widget.docs['mainName'])
        .collection('${FirebaseAuth.instance.currentUser!.email}')
        .doc('options')
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        checkFCMTokenisSame();
      } else {
        createFCMTokenFirebase();
      }
    });} catch (e) {
      sendErrorLog('$e', 'auth_notification_detail');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> createFCMTokenFirebase() async{
    try {
    String? token = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance
        .collection('user_notification')
        .doc(widget.docs['mainName'])
        .collection('${FirebaseAuth.instance.currentUser!.email}')
        .doc('options')
        .set({
          'token': token,
        });
    } 
    catch (e) {
      sendErrorLog('$e', 'auth_notification_detail');
      EasyLoading.showError('Error');
    }
  }

    Future<void> updateFCMTokenFirebase() async{
      try {
    String? token = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance
        .collection('user_notification')
        .doc(widget.docs['mainName'])
        .collection('${FirebaseAuth.instance.currentUser!.email}')
        .doc('options')
        .update({
          'token': token,
        });
      }
      catch (e) {
        sendErrorLog('$e', 'auth_notification_detail');
        EasyLoading.showError(e.toString());
      }
  }

  Future<void> checkFCMTokenisSame() async{
    try {
    String? token = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance
        .collection('user_notification')
        .doc(widget.docs['mainName'])
        .collection('${FirebaseAuth.instance.currentUser!.email}')
        .doc('options')
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        if(documentSnapshot['token'] == token){
        }else{
          _showDialog('พบการเปลี่ยนแปลงของอุปกรณ์ กรุณารีเซ็ทการตั้งค่าการแจ้งเตือนใหม่');
        }
      } else {
      }
    });} catch (e) {
      sendErrorLog('$e', 'auth_notification_detail');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> countNotification() async {
    try {
      await FirebaseFirestore.instance
          .collection('node_notification')
          .get()
          .then((QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          allNotification = doc.data();
        }
        levelWater = allNotification.values.toList();
        levelWater.removeWhere((element) => true == element is bool);
        levelWater.sort((a, b) => a.compareTo(b));
        setState(() {
          levelWater = levelWater;
          countAllNotification = allNotification.length;
        });
        allNotification = allNotification.length - 1;
      });
      checkUserNotification();
    } catch (e) {
      sendErrorLog('$e', 'auth_notification_detail');
      EasyLoading.showError("เกิดข้อผิดพลาด");
    }
  }

  Future<void> checkUserNotification() async {
    try {
      await FirebaseFirestore.instance
          .collection('user_notification')
          .doc(widget.docs['mainName'])
          .collection('${FirebaseAuth.instance.currentUser!.email}')
          .doc('notification')
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          setState(() {
            switchNotification = documentSnapshot['notification'];
          });

          for (var i = 1; i <= allNotification; i++) {
            if (documentSnapshot['id$i'] == null) {
              setState(() {
                nodeAllNoti.add(false);
              });
            } else {
              setState(() {
                nodeAllNoti.add(documentSnapshot['id$i']);
              });
            }
          }
          setState(() {
            finished = true;
          });
        } else {
          createUserNotification();
        }
      });
    } catch (e) {
      EasyLoading.showError('กำลังสร้างข้อมูล');
      createUserNotification();
    }
  }

  Future<void> updateNodeAllNoti(bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_notification')
          .doc(widget.docs['mainName'])
          .collection('${FirebaseAuth.instance.currentUser!.email}')
          .doc('notification')
          .update({
        'notification': value,
        for (int i = 1; i <= allNotification; i++) 'id$i': false,
      });
      if (value == false) {
        setState(() {
          nodeAllNoti = [for (int i = 1; i <= allNotification; i++) false];
        });
        for (int i = 1; i <= allNotification; i++) {
          await FirebaseMessaging.instance
              .unsubscribeFromTopic('${widget.docs['mainName']}_id$i');
        }
      }
    } catch (e) {
      sendErrorLog('$e', 'auth_notification_detail');
      EasyLoading.showError("เกิดข้อผิดพลาด");
    }
  }
 
  Future<void> updateNodeSomeNoti(bool value, String id) async {
    try {
       await FirebaseFirestore.instance
          .collection('user_notification')
          .doc(widget.docs['mainName'])
          .update({
        'updated_at': DateTime.now().toUtc().add(const Duration(hours: 7)),
        });
      await FirebaseFirestore.instance
          .collection('user_notification')
          .doc(widget.docs['mainName'])
          .collection('${FirebaseAuth.instance.currentUser!.email}')
          .doc('notification')
          .update({
        'id$id': value,
      });
      if (value == true) {
        EasyLoading.showSuccess('เปิดการแจ้งเตือนระดับน้ำ $id');
        await FirebaseMessaging.instance
            .subscribeToTopic('${widget.docs['mainName']}_id$id');
      } else {
        EasyLoading.showInfo('ปิดการแจ้งเตือนระดับน้ำ $id');
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('${widget.docs['mainName']}_id$id');
      }
      updateFCMTokenFirebase();
    } catch (e) {
      sendErrorLog('$e', 'auth_notification_detail');
      EasyLoading.showError("เกิดข้อผิดพลาด");
    }
  }

  Future<void> createUserNotification() async {
    try {
       await FirebaseFirestore.instance
          .collection('user_notification')
          .doc(widget.docs['mainName'])
          .set({
        'created_at': DateTime.now().toUtc().add(const Duration(hours: 7)),
        'updated_at': DateTime.now().toUtc().add(const Duration(hours: 7)),
        });
      await FirebaseFirestore.instance
          .collection('user_notification')
          .doc(widget.docs['mainName'])
          .collection('${FirebaseAuth.instance.currentUser!.email}')
          .doc('notification')
          .set({
        'notification': false,
        for (int i = 1; i <= allNotification; i++) 'id$i': false,
      });
      checkUserNotification();
    } catch (e) {
      sendErrorLog('$e', 'auth_notification_detail');
      EasyLoading.showError("เกิดข้อผิดพลาด");
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
          'ตั้งค่า',
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
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          finished != true
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    SettingsGroup(
                      settingsGroupTitle: "  ระบบการแจ้งเตือน",
                      settingsGroupTitleStyle: GoogleFonts.kanit(
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                      items: [
                        SettingsItem(
                          title: 'รับการแจ้งเตือนจาก ${widget.docs['name']}',
                          onTap: () {},
                          icons: switchNotification == true
                              ? Icons.notifications_active
                              : Icons.notifications,
                          trailing: Switch.adaptive(
                            value: switchNotification,
                            onChanged: (value) {
                              setState(() {
                                switchNotification = value;
                              });
                              if (switchNotification == true) {
                                EasyLoading.showSuccess('เปิดการแจ้งเตือน');
                                updateNodeAllNoti(switchNotification);
                              } else {
                                EasyLoading.showInfo('ปิดการแจ้งเตือน');
                                updateNodeAllNoti(switchNotification);
                              }
                            },
                            activeTrackColor: Colors.lightGreenAccent,
                            activeColor: Colors.green,
                          ),
                        ),
                        for (var i = 0; i <= countAllNotification - 2; i++)
                          SettingsItem(
                            title: 'ระดับน้ำ ${i + 1}',
                            onTap: () {},
                            icons: Icons.waterfall_chart,
                            subtitle:
                                'ทุกการเปลี่ยนแปลง ${levelWater[i].toString()} cm',
                            trailing: switchNotification == true
                                ? Switch.adaptive(
                                    value: nodeAllNoti[i],
                                    onChanged: (value) {
                                      setState(() {
                                        nodeAllNoti[i] = value;
                                      });
                                      String nodeid = (i + 1).toString();

                                      if (nodeAllNoti[i] == true) {
                                        EasyLoading.showSuccess(
                                            'เปิดการแจ้งเตือนระดับน้ำ ${i + 1}');
                                        updateNodeSomeNoti(
                                            nodeAllNoti[i], nodeid);
                                      } else {
                                        EasyLoading.showInfo(
                                            'ปิดการแจ้งเตือนระดับน้ำ ${i + 1}');
                                        updateNodeSomeNoti(
                                            nodeAllNoti[i], nodeid);
                                      }
                                    },
                                  )
                                : const Icon(Icons.lock),
                          ),
                      ],
                    )
                  ],
                )
        ],
      ),
    );
  }
}