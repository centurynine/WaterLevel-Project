import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../pages/nav.dart';
import '../utils/authentication.dart';

class UserDetail extends StatefulWidget {
  final DocumentSnapshot docs;
  const UserDetail({Key? key, required this.docs}) : super(key: key);

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  String status = 'User';
  int nodeCount = 0;
  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getAdmin();
      getStatus();
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

  void getStatus() {
    try {
    if (widget.docs['admin'] == 'true') {
      setState(() {
        status = 'Admin';
      });
    } else if (widget.docs['admin'] == 'false') {
      setState(() {
        status = 'User';
      });
    } else {
      setState(() {
        status = 'Unknown';
      });
    }
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> countNode() async {
    try {
    FirebaseFirestore.instance
        .collection('user_notification')
        .get()
        .then((value) {
      setState(() {
        nodeCount = value.docs.length;
      });
    });
  } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }
  

  Future<void> deleteUser() async {
     try {
    FirebaseFirestore.instance.collection('user').doc(widget.docs.id).delete();
    FirebaseFirestore.instance
        .collection('user_option')
        .doc(widget.docs.id)
        .delete();
    FirebaseFirestore.instance
        .collection('user_notification')
        .doc('node$nodeCount')
        .collection(widget.docs['email'])
        .where('email', isEqualTo: widget.docs['email'])
        .get()
        .then((value) {
      for (var element in value.docs) {
        FirebaseFirestore.instance
            .collection('user_notification')
            .doc('node$nodeCount')
            .collection(widget.docs['email'])
            .doc(element.id)
            .delete();
      }
    });
    }catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(' จัดการผู้ใช้',
            style: TextStyle(color: Colors.black87)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          //delete button
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.black87,
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('การลบข้อมูล'),
                      content: const Text(
                          'คุณต้องการลบบัญชีผู้ใช้งานนี้ใช่หรือไม่ ?'),
                      actions: <Widget>[
                        ElevatedButton(
                          child: const Text('ยกเลิก'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        ElevatedButton(
                          child: const Text('ยืนยัน'),
                          onPressed: () {
                            deleteUser();
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  });
            },
          ),
          IconButton(
            icon: const Icon(Icons.miscellaneous_services_sharp),
            color: Colors.black87,
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('สถานะผู้ใช้งาน'),
                      content: const Text('เปลี่ยนสถานะผู้ใช้งาน'),
                      actions: <Widget>[
                        ElevatedButton(
                          child: const Text('Admin'),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('user')
                                .doc(widget.docs.id)
                                .update({'admin': 'true'});
                            setState(() {
                              status = 'Admin';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        ElevatedButton(
                          child: const Text('User'),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('user')
                                .doc(widget.docs.id)
                                .update({'admin': 'false'});
                            setState(() {
                              status = 'User';
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  });
            },
          ),
        ],
      ),
      body: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            Column(
              children: [
                ListTile(
                  title: const Text('ID'),
                  subtitle: Text(widget.docs['id']),
                ),
                ListTile(
                  title: const Text('UID'),
                  subtitle: Text(widget.docs['uid']),
                ),
                ListTile(
                  title: const Text('อีเมลล์'),
                  subtitle: Text(widget.docs['email']),
                ),
                ListTile(
                  title: const Text('ชื่อ'),
                  subtitle: Text(widget.docs['name']),
                ),
                ListTile(
                  title: const Text('เข้าสู่ระบบด้วย'),
                  subtitle: Text(widget.docs['loginwith']),
                ),
                ListTile(
                  title: const Text('วันที่สมัครสมาชิก'),
                  subtitle: Text(widget.docs['created_at']
                      .toDate()
                      .toString()
                      .substring(0, 20)),
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ]),
    );
  }
}
