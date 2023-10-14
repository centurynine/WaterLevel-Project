import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';

import '../pages/nav.dart';
import '../utils/authentication.dart';
class NodeConfigMessage extends StatefulWidget {
  String widgetNodeName;
  NodeConfigMessage({Key? key, required this.widgetNodeName}) : super(key: key);
  @override
  State<NodeConfigMessage> createState() => _NodeConfigMessageState();
}

class _NodeConfigMessageState extends State<NodeConfigMessage> {
  bool switchValueSetting = false;
  String valueMessageTitle = "";
  String valueMessageBody = "";

  final _textFieldMessageTitle = TextEditingController();
  final _textFieldMessageBody = TextEditingController();
  String nodeName = "";
  @override
  void initState() {
     if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } 
    else {
      getAdmin();
      nodeName = widget.widgetNodeName;
    checkConfigNode1();
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

  void checkConfigNode1() async {
    try {
    await FirebaseFirestore.instance
        .collection('node_setting')
        .doc(nodeName)
        .get()
        .then((value) => setState(() {
              valueMessageTitle = value.data()!['message_title'];
              valueMessageBody = value.data()!['message_body'];
            }));} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

void getConfigNode1() async {
  try {
    await FirebaseFirestore.instance
        .collection('node_setting')
        .doc(nodeName)
        .get()
        .then((value) => setState(() {
              valueMessageTitle = value.data()!['message_title'];
              valueMessageBody = value.data()!['message_body'];
            }));} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

void setConfigTitleNode1() async {
  try {
    await FirebaseFirestore.instance
        .collection('node_setting')
        .doc(nodeName)
        .update({
      'message_title': valueMessageTitle,
    });} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

void setConfigBodyNode1() async {
  try {
    await FirebaseFirestore.instance
        .collection('node_setting')
        .doc(nodeName)
        .update({
      'message_body': valueMessageBody,
    });} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }


  Future<void> _displayTextInputTitle(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไข Title Message'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueMessageTitle = value;
                });
              },
              controller: _textFieldMessageTitle,
              decoration: const InputDecoration(hintText: "Water Level"),
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
                    valueMessageTitle = valueMessageTitle;
                    setConfigTitleNode1();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _displayTextInputBody(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไข Body Message'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueMessageBody = value;
                });
              },
              controller: _textFieldMessageBody,
              decoration: const InputDecoration(hintText: "Water Level"),
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
                    valueMessageBody = valueMessageBody;
                    setConfigBodyNode1();
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
              //   Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          // backgroundColor: Colors.transparent,
          // elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              const SizedBox(height: 20),
              SettingsGroup(
                settingsGroupTitle: "การตั้งค่าข้อความแจ้งเตือน",
                settingsGroupTitleStyle: GoogleFonts.kanit(
                  fontSize: 22,
                  color: Colors.black87,
                ),
                items: [
                  SettingsItem(
                    onTap: () {
                      setState(() {
                        _displayTextInputTitle(context);
                      });
                    
                    },
                    icons: Icons.display_settings_outlined,
                    iconStyle: IconStyle(
                      withBackground: true,
                      borderRadius: 50,
                      backgroundColor: Colors.blue[400],
                    ),
                    title: "แก้ไขข้อความ Title Message",
                    subtitle: valueMessageTitle,
                    titleStyle: GoogleFonts.kanit(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    subtitleStyle: GoogleFonts.kanit(
                      fontSize: 14,
                    ),
                  ),
                  SettingsItem(
                    onTap: () {
                      setState(() {
                        _displayTextInputBody(context);
                      });
                    },
                    icons: Icons.display_settings_outlined,
                    iconStyle: IconStyle(
                      withBackground: true,
                      borderRadius: 50,
                      backgroundColor: Colors.blue[400],
                    ),
                    title: "แก้ไขข้อความ Body Message",
                    subtitle: '$valueMessageBody "\distance cm\"',
                    titleStyle: GoogleFonts.kanit(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    subtitleStyle: GoogleFonts.kanit(
                      fontSize: 14,
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
