import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';

import '../pages/nav.dart';
import '../utils/authentication.dart';

class NodeConfigLocation extends StatefulWidget {
  String widgetNodeName;
  NodeConfigLocation({Key? key, required this.widgetNodeName})
      : super(key: key);
  @override
  State<NodeConfigLocation> createState() => _NodeConfigLocationState();
}

class _NodeConfigLocationState extends State<NodeConfigLocation> {
  bool switchValueSetting = false;
  double lat = 0;
  double lng = 0;

  final _textFieldLat = TextEditingController();
  final _textFieldLng = TextEditingController();
  String nodeName = "";
  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getAdmin();
      nodeName = widget.widgetNodeName;
      checkConfigLocation();
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

  void checkConfigLocation() async {
    try {
    await FirebaseFirestore.instance
        .collection('node')
        .doc(nodeName)
        .get()
        .then((value) => setState(() {
              lat = value.data()!['location']['latitude'];
              lng = value.data()!['location']['longitude'];
            }));} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  void setConfigLat() async {
    try {
    await FirebaseFirestore.instance.collection('node').doc(nodeName).update({
      'location': {
        'latitude': lat,
        'longitude': lng,
      },
    });} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  void setConfigLng() async {
    try {
    await FirebaseFirestore.instance.collection('node').doc(nodeName).update({
      'location': {
        'latitude': lat,
        'longitude': lng,
      },
    });} catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> _displayTextInputTitle(BuildContext context) async {
    _textFieldLat.text = lat.toString();
    String latString = lat.toString();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไข Latitude'),
            content: TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  latString = value;
                });
              },
              controller: _textFieldLat,
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
                    lat = double.parse(latString);
                    setConfigLat();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _displayTextInputBody(BuildContext context) async {
    _textFieldLng.text = lng.toString();
    String lngString = lng.toString();
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไข Longitude'),
            content: TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  lngString = value;
                });
              },
              controller: _textFieldLng,
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
                    lng = double.parse(lngString);
                    setConfigLng();
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
              settingsGroupTitle: "การตั้งค่าต่ำแหน่งโหนด $nodeName",
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
                  title: "แก้ไข Latitude",
                  subtitle: lat.toString(),
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
                  title: "แก้ไข Longitude",
                  subtitle: lng.toString(),
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
