import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:waterlevel/pages/about.dart';
import '../admin/admin_notification.dart';
import '../admin/admin_problem.dart';
import '../admin/admin_user_management.dart';
import '../auth/auth_graphlog.dart';
import '../auth/auth_report.dart';
import '../auth/auth_setting.dart';
import '../main.dart';
import '../node/node_management.dart';
import '../node/node_status.dart';
import '../utils/error_log.dart';
import '../utils/storage.dart';
import 'login.dart';
import 'signup.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  String? name = '#Name';
  String? userEmail = 'กรุณาเข้าสู่ระบบ';
  String? admin = 'false';
  UserStorage user = UserStorage();
  @override
  void initState() {
  
    checkNameWhoCreated();
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      userEmail = FirebaseAuth.instance.currentUser?.email;
    }
  }

  void checkNameWhoCreated() async {
    try {
    if (FirebaseAuth.instance.currentUser != null) {
      name = user.name;
      admin = user.isAdmin.toString();
    }} catch (e) {
      sendErrorLog('$e', 'login');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }
  Color getDrawerHeaderColor() {
      return FirebaseAuth.instance.currentUser != null
          ? admin == 'true'
              ? const Color.fromARGB(255, 255,105,97)
              : const Color.fromARGB(255, 53,157,255)
          : const Color.fromARGB(255, 53,157,255);
  }

  @override
  Widget build(BuildContext context) {
    Color headerColor = getDrawerHeaderColor();
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(70),
        
                topRight: Radius.circular(20),
        
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width / 1.3,
      // color: Colors.white,
      child: ListView(
       
        children: <Widget>[
           const SizedBox(
            height: 10,
           ),
          Container(
 
            margin: const EdgeInsets.only(top: 10, bottom: 0, left: 20, right: 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                topLeft: Radius.circular(20),

              ),
              color: headerColor,
              boxShadow: const <BoxShadow>[],
            ),
            child: Column(
              children: <Widget>[
                Container(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 100,
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        child: Image.asset(
                          'assets/images/user.png',
                          width: 50,
                          height: 50,
                        ),
                      ),
                      FirebaseAuth.instance.currentUser != null
                          ? Column(
                              children: <Widget>[
                                Container(
                                  child: Center(
                                    child: Text(
                                      (admin == 'true')
                                      ? name.toString() + ' (Admin)'
                                      : name.toString() + ' (User)',
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color:
                                            const Color.fromARGB(221, 255, 255, 255),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  child: Center(
                                    child: Text(
                                      userEmail.toString().length > 28
                                          ? '${userEmail
                                                  .toString()
                                                  .substring(0, 20)}...'
                                          : userEmail.toString(),
                                      overflow: TextOverflow.fade,
                                      //  userEmail.toString().substring(0, userEmail.toString().indexOf('@')),
                                      style: GoogleFonts.kanit(
                                        fontSize: 14,
                                        color:
                                            const Color.fromARGB(221, 255, 255, 255),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.only(left: 10),
                                    child: Text(
                                      'กรุณาเข้าสู่ระบบ' + ' (Guest)',
                                      style: GoogleFonts.kanit(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                    ],
                  ),
                ),
              ],
            ),
          ),
          FirebaseAuth.instance.currentUser != null
              ? Column(
                  children: [
                    ListTile(
                      title: Text('หน้าแรก',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/home.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.pushReplacement(context,
                            CupertinoPageRoute(builder: (_) => const MyApp()));
                      },
                    ),
                    ListTile(
                      title: Text('ตั้งค่า',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/setting.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const Setting()));
                      },
                    ),
                    ListTile(
                      title: Text('แจ้งปัญหา',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/help.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(context,
                            CupertinoPageRoute(builder: (_) => const Report()));
                      },
                    ),
                    ListTile(
                      title: Text('กราฟระดับน้ำ',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/bar-chart.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const GraphLog()));
                      },
                    ),
                      ListTile(
                      title: Text('ผู้จัดทำ',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/information.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const About()));
                      },
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      child: ListTile(
                        title: Text(
                          'เข้าสู่ระบบ',
                          style: GoogleFonts.kanit(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        leading: Image.asset(
                          'assets/images/contact-book.png',
                          width: 25,
                          height: 25,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()));
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        'สมัครสมาชิก',
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      leading: Image.asset(
                        'assets/images/send-mail.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Signup()));
                      },
                    ),
                  ],
                ),
          admin == 'true'
              ? Column(
                  children: [
                    ListTile(
                      title: Text('ตั้งค่าระบบการแจ้งเตือน',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/setting.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const NotificationSetting()));
                      },
                    ),
                    ListTile(
                      title: Text('รายงานปัญหา',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/web-page.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const Problem()));
                      },
                    ),
                    ListTile(
                      title: Text('สถานะโหนด',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/wifi-signal.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const NodeStatus()));
                      },
                    ),
                    ListTile(
                      title: Text('จัดการผู้ใช้งาน',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/chat.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const UserManagement()));
                      },
                    ),
                    ListTile(
                      title: Text('จัดการโหนด',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/images/router.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (_) => const NodeManagement()));
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink(),
              FirebaseAuth.instance.currentUser != null
              ?  ListTile(
                      title: Text('ออกจากระบบ',
                          style: GoogleFonts.kanit(
                              fontSize: 14, color: Colors.black)),
                      leading: Image.asset(
                        'assets/logout.png',
                        width: 25,
                        height: 25,
                      ),
                      onTap: () {
                        _signOut();
 
                      },
                    )
              : Container(),
              const SizedBox(
                height: 20,
              ),
             
        ],
        
      ),
    );
  }

  Future<void> _signOut() async {
    EasyLoading.showInfo('ออกจากระบบ');
    await FirebaseAuth.instance.signOut();
    user.email = "#Email";
    user.name = "#Name";
    user.isAdmin = false;
    Navigator.pop(context);
    _doOpenPage();
  }

  void _doOpenPage() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
    Future.delayed(const Duration(milliseconds: 2000), () {
      EasyLoading.dismiss();
    });
  }
}