import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:waterlevel/auth/auth_changename.dart';
import 'package:waterlevel/pages/home.dart';

import '../main.dart';
import '../pages/nav.dart';
import '../utils/error_log.dart';
import '../utils/storage.dart';
import 'auth_changepassword.dart';
import 'auth_forgotpassword.dart';
import 'auth_notification.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});
  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool isFB = false;
  bool switchNotification = false;
  String admin = 'false';
  String? name = '#Name';
  String? loginWith;
  String? email;
  UserStorage user = UserStorage();

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      email = FirebaseAuth.instance.currentUser!.email!;
      name = user.name;
      admin = user.isAdmin.toString();
      checkInfo();
      checkAdminNotification();
    }
    super.initState();
  }

  Future<void> checkInfo() async {
    String isAdminString = 'false';
    try {
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: FirebaseAuth.instance.currentUser!.email)
          .get()
          .then((value) => value.docs.forEach((element) {
                setState(() {
                  name = element.data()['name'];
                  loginWith = element.data()['loginwith'];
                  isAdminString = element.data()['admin'];
                });
              }));
    } else {
      Navigator.pushNamed(context, '/login');
    }
    } catch (e) {
       EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> checkAdminNotification() async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: FirebaseAuth.instance.currentUser!.email)
          .get()
          .then((value) => value.docs.forEach((element) {
                setState(() {
                  switchNotification = element.data()['adminNotification'];
                });
              }));
    } catch (e) {
      await FirebaseFirestore.instance
          .collection('user')
          .where('email', isEqualTo: FirebaseAuth.instance.currentUser!.email)
          .get()
          .then((value) => value.docs.forEach((element) {
                FirebaseFirestore.instance
                    .collection('user')
                    .doc(element.id)
                    .update({
                  'adminNotification': false,
                });
              }));
    }
  }

  Future<void> updateAdminNotification(bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .update({
        'adminNotification': value,
      });
      if (value == true) {
        await FirebaseMessaging.instance.subscribeToTopic('admin');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('admin');
      }
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  Future<void> deleteUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          await user.delete();
          EasyLoading.showSuccess('ลบบัญชีเรียบร้อยแล้ว');
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const MyApp()));
          await FirebaseFirestore.instance
              .collection('user')
              .where('email',
                  isEqualTo: FirebaseAuth.instance.currentUser!.email)
              .get()
              .then((value) => value.docs.forEach((element) {
                    FirebaseFirestore.instance
                        .collection('user')
                        .doc(element.id)
                        .delete();
                  }));
        } else {
          EasyLoading.showError('กรุณายืนยันอีเมลก่อนลบบัญชี');
        }
      }
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

// ฟังก์ชันส่งอีเมลยืนยันก่อนลบบัญชีผู้ใช้
  Future<void> sendEmailVerificationBeforeDelete(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // แสดง Dialog ยืนยันการลบ
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ยืนยันการลบบัญชี'),
              content: const Text('กดยืนยันเพื่อทำการลบบัญชี'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด Dialog
                  },
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด Dialog
                    deleteUser(); // เรียกฟังก์ชัน onConfirm เมื่อผู้ใช้ยืนยัน
                  },
                  child: const Text('ยืนยัน'),
                ),
              ],
            );
          },
        );
      } else {
       EasyLoading.showError('ไม่พบผู้ใช้');
      }
    } catch (e) {
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
        // backgroundColor: Colors.transparent,
        // elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 20),
            SettingsGroup(
              settingsGroupTitle: "การตั้งค่า",
              settingsGroupTitleStyle: GoogleFonts.kanit(
                fontSize: 22,
                color: Colors.black87,
              ),
              items: [
                SettingsItem(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const ForgotPassword()));
                  },
                  icons: Icons.password,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "ลืมรหัสผ่าน",
                  titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SettingsItem(
                  onTap: () {
                    Navigator.push(context,
                        CupertinoPageRoute(builder: (_) => const ChangeName()));
                  },
                  icons: Icons.font_download_rounded,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "เปลี่ยนชื่อ",
                  titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SettingsItem(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const ChangePassword()));
                  },
                  icons: Icons.lock,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "เปลี่ยนรหัสผ่าน",
                  titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SettingsItem(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const AuthNotification()));
                  },
                  icons: Icons.notification_important_rounded,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "ตั้งค่าการแจ้งเตือน",
                  titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                if (admin == 'true')
                  SettingsItem(
                    title: 'การแจ้งเตือนแอดมิน',
                     titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                    onTap: () {},
                    icons: Icons.admin_panel_settings_rounded,
                    iconStyle: IconStyle(
                      withBackground: true,
                      borderRadius: 50,
                      backgroundColor: Colors.red[400],
                    ),
                    trailing: Switch.adaptive(
                      value: switchNotification,
                      onChanged: (value) {
                        updateAdminNotification(value);
                        setState(() {
                          switchNotification = value;
                        });
                      },
                    ),
                  ),
                SettingsItem(
                  onTap: () {
                    sendEmailVerificationBeforeDelete(context);
                  },
                  icons: Icons.delete,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "ลบบัญชี",
                  subtitle: "",
                  titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
