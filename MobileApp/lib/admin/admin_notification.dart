import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/nav.dart';
import '../utils/authentication.dart';

class NotificationSetting extends StatefulWidget {
  const NotificationSetting({super.key});

  @override
  State<NotificationSetting> createState() => _NotificationSettingState();
}

class _NotificationSettingState extends State<NotificationSetting> {
  bool switchValueSetting = false;
  String valueMessageTitle = "";
  String valueMessageBody = "";
  String nodeName = "";
  var allNotification;
  var allNotificationUse;
  int countAllNotification = 0;
  String newSetNotification = '0';
  int localLevel = 5;
  int allNode = 0;
  final _textNotification = TextEditingController();
  var _textSetNotification = TextEditingController();
  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getAdmin();
      countNotification();
      checkStatus();
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

  var levelWater = [];
  List listLevelWater = [0];

  Future<void> countNode() async {
    await FirebaseFirestore.instance
        .collection('node_notification')
        .get()
        .then((value) => setState(() {
              allNode = value.docs.length - 1;
            }));
  }

  Future<void> checkStatus() async {
    await FirebaseFirestore.instance
        .collection('node_notification')
        .doc('water_notification')
        .get()
        .then((value) => setState(() {
              switchValueSetting = value.data()!['notification'];
            }));
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
      allNotificationUse = allNotification;
    } catch (e) {
      EasyLoading.showError('ไม่สามารถโหลดข้อมูลได้$e');
    }
  }

  Future updateCountNotification(String value) async {
    int count = int.parse(value);
    try {
      await FirebaseFirestore.instance
          .collection('node_notification')
          .doc('water_notification')
          .update({
        for (int i = 1; i <= countAllNotification; i++)
          'id$i': FieldValue.delete(),
      });
      _textNotification.clear();
      await FirebaseFirestore.instance
          .collection('node_notification')
          .doc('water_notification')
          .update({
        for (var level = 5, i = 1; i <= count; i++, level = level + 5)
          'id$i': level,
      });
      EasyLoading.showSuccess('บันทึกข้อมูลสำเร็จ');
      countNotification();
    } catch (e) {
      EasyLoading.showError('$e');
    }
  }

  Future<void> resetAllDistance() async {
    try {
      QuerySnapshot<Map<String, dynamic>> countNode =
          await FirebaseFirestore.instance.collection('node').get();
      for (int i = 1; i <= countNode.size; i++) {
        try {
          await FirebaseFirestore.instance
              .collection('node_notification')
              .doc('node$i')
              .update({
            for (int i = 1; i <= allNotificationUse; i++) 'id$i': 0,
          });
          EasyLoading.showSuccess('กำลังรีเซ็ท...');
        } catch (e) {
          EasyLoading.showError('เกิดข้อผิดพลาด');
        }
      }
      EasyLoading.showSuccess('รีเซ็ทการแจ้งเตือนสำเร็จ');
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  Future<void> updateNotification() async {
    try {
      FirebaseFirestore.instance
          .collection('node_notification')
          .doc('water_notification')
          .update({
        'notification': switchValueSetting,
      });
      EasyLoading.showSuccess('เปิดการแจ้งเตือนสำเร็จ');
    } catch (e) {
      EasyLoading.showError('ไม่สามารถเปิดการแจ้งเตือนได้: $e');
    }
  }

  Future<void> _inputDialogAllNoti(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('ตั้งค่าจำนวนการแจ้งเตือน'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  newSetNotification = value;
                });
              },
              controller: _textNotification,
              decoration:
                  const InputDecoration(hintText: 'จำนวนการแจ้งเตือนทั้งหมด'),
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
                    updateCountNotification(newSetNotification);
                    EasyLoading.show(status: 'กำลังโหลด...');
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> resetDistanceButton(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('รีเซ็ทการแจ้งเตือนก่อนหน้าทั้งหมด'),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('ยกเลิก'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              ElevatedButton(
                child: const Text('ตกลง'),
                onPressed: () {
                  resetAllDistance();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> updateWaterLevel(int id, int level) async {
    bool check = false;
    try {
      await FirebaseFirestore.instance
          .collection('node_notification')
          .doc('water_notification')
          .get()
          .then((value) => setState(() {
                for (int i = 1; i <= countAllNotification; i++) {
                  if (value.data()!['id$i'] == level) {
                    EasyLoading.showError('ระดับน้ำ $level cm มีอยู่แล้ว');
                    check = true;
                    return;
                  } else {
                    check = false;
                  }
                }

                if (value.data()!['id$id'] != null) {
                  if (value.data()!['id$id'] == level) {
                    EasyLoading.showError('ระดับน้ำ $level cm มีอยู่แล้ว');
                    check = true;
                  }
                }
              }));
      if (check) return;
      await FirebaseFirestore.instance
          .collection('node_notification')
          .doc('water_notification')
          .update({
        'id$id': level,
      });
      EasyLoading.dismiss();
      EasyLoading.showSuccess('บันทึกข้อมูลสำเร็จ');
      countNotification();
    } catch (e) {
      EasyLoading.showError('ไม่สามารถบันทึกข้อมูลได้: $e');
    }
  }

  Future<void> _inputDialogWaterLevel(
      BuildContext context, int id, int noti) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('ตั้งค่า ระดับน้ำ $id'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  try {
                    localLevel = value.isEmpty ? 5 : int.parse(value);
                    _textSetNotification = TextEditingController(text: value);
                  } catch (e) {
                    EasyLoading.showError('กรุณากรอกตัวเลขเท่านั้น');
                  }
                });
              },
              controller: _textSetNotification,
              decoration: const InputDecoration(hintText: 'ระดับน้ำ (cm)'),
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
                    updateWaterLevel(id, localLevel);
                    Navigator.pop(context);
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
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          Column(
            children: [
              SettingsGroup(
                settingsGroupTitle: "  ระบบการแจ้งเตือน",
                settingsGroupTitleStyle: GoogleFonts.kanit(
                  fontSize: 22,
                  color: Colors.black87,
                ),
                items: [
                  SettingsItem(
                    title: 'เปิดการส่งการแจ้งเตือนไปยังผู้ใช้',
                    onTap: () {},
                    icons: Icons.settings,
                    trailing: Switch.adaptive(
                      value: switchValueSetting,
                      onChanged: (value) {
                        setState(() {
                          switchValueSetting = value;
                          updateNotification();
                        });
                        if (switchValueSetting == true) {
                          EasyLoading.showSuccess('เปิดใช้งาน $nodeName');
                        } else {
                          EasyLoading.showInfo('ปิดใช้งาน $nodeName');
                        }
                      },
                      activeTrackColor: Colors.redAccent,
                      activeColor: Colors.red[200],
                    ),
                  ),
                  SettingsItem(
                    title: 'รีเซ็ทการแจ้งเตือนก่อนหน้าทั้งหมด',
                    onTap: () {
                      resetDistanceButton(context);
                    },
                    icons: Icons.settings,
                  ),
                  SettingsItem(
                    title: 'ตั้งค่าจำนวนตัวเลือกการแจ้งเตือน',
                    onTap: () {
                      _inputDialogAllNoti(context);
                    },
                    icons: Icons.settings,
                    subtitle: allNotification.toString(),
                  ),
                  for (var i = 0; i <= countAllNotification - 2; i++)
                    SettingsItem(
                      title: 'ระดับน้ำ ${i + 1}',
                      onTap: () {
                        _inputDialogWaterLevel(context, i + 1, levelWater[i]);
                      },
                      icons: Icons.waterfall_chart,
                      subtitle: levelWater[i].toString(),
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
