import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:waterlevel/utils/authentication.dart';

import '../pages/nav.dart';
import 'node_config_location.dart';
import 'node_config_message.dart';
import 'node_management.dart';

class NodeConfig extends StatefulWidget {
  DocumentSnapshot docs;
  NodeConfig({Key? key, required this.docs}) : super(key: key);
  @override
  State<NodeConfig> createState() => _NodeConfigState();
}

class _NodeConfigState extends State<NodeConfig> {
  bool switchValueSetting = false;
  bool switchGps = false;
  bool switchLed = false;
  String messageDelay = "#MessageDelay";
  String uploadDelay = "#UploadDelay";
  String settingDelay = "#SettingDelay";
  var nodeName = "#NodeName";
  String changeName = "nodex";
  String nodeDescription = "#NodeDescription";
  String valueStatus = "false";
  String valueMessage = "";
  String valueSystem = "";
  String valueSetting = "";
  bool switchNodeStatus = false;
  double lat = 0;
  double long = 0;

  final _textFieldMessage = TextEditingController();
  final _textFieldSensor = TextEditingController();
  final _textFieldSetting = TextEditingController();
  final _textNodeName = TextEditingController();
  final _textNodeDescription = TextEditingController();
  final _textNodeRemove = TextEditingController();

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      getAdmin();
      setState(() {
        try {
          nodeName = widget.docs['mainName'];
          changeName = widget.docs['name'];
        } catch (e) {
          nodeName = "Error";
          changeName = "Error";
        }
      });

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

  Future checkConfigNode1() async {
    try {
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(nodeName)
          .get()
          .then((value) => setState(() {
                switchValueSetting = value.data()!['setting'];
                switchGps = value.data()!['gps'];
                valueMessage = value.data()!['message_delay'];
                valueSetting = value.data()!['setting_delay'];
                valueSystem = value.data()!['system_delay'];
              }));

      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeName)
          .get()
          .then((value) => setState(() {
                valueStatus = value.data()!['status'];
                nodeDescription = value.data()!['description'];
                lat = value.data()!['location']['latitude'].toDouble();
                long = value.data()!['location']['longitude'].toDouble();
                if (value.data()!['led_status'] == 'on') {
                  switchLed = true;
                } else {
                  switchLed = false;
                }
              }));

      if (valueStatus == "on") {
        setState(() {
          switchNodeStatus = true;
        });
      } else {
        setState(() {
          switchNodeStatus = false;
        });
      }
    } catch (e) {
      EasyLoading.showError(e.toString());
      if (mounted) {
        setState(() {
          switchValueSetting = false;
          switchGps = false;
          valueMessage = 'Error';
          valueSetting = 'Error';
          valueSystem = 'Error';
          valueStatus = 'Error';
          nodeDescription = 'Error';
        });
      }
    }
  }

  Future<void> setNodeStatus(String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeName)
          .update({'status': value});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setGps(bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(nodeName)
          .update({'gps': value});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setLed(String value) async {
    try {
      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeName)
          .update({'led_status': value});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setNodeLocation(double lat, double long) async {
    try {
      await FirebaseFirestore.instance.collection('node').doc(nodeName).update(
        {
          'location': {
            'latitude': lat,
            'longitude': long,
          }
        },
      );
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setRestart() async {
    try {
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(nodeName)
          .update({'restart': true});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setMessageDelay() async {
    try {
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(nodeName)
          .update({'message_delay': valueMessage});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setSystemDelay() async {
    try {
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(nodeName)
          .update({'system_delay': valueSystem});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setSettingDelay() async {
    try {
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(nodeName)
          .update({'setting_delay': valueSetting});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setNodeDescription(String vaule) async {
    try {
      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeName)
          .update({'description': vaule});
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  Future<void> setNodeName(String vaule) async {
    try {
      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeName)
          .update({'name': vaule});
      EasyLoading.showSuccess('แก้ไขชื่อแสดงผลแล้ว');
    } catch (e) {
      EasyLoading.showError('เกิดข้อผิดพลาด ' + e.toString());
    }
  }

  Future<void> _inputDialogNodeName(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไขชื่อแสดงผล Node'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  changeName = value;
                });
              },
              controller: _textNodeName,
              decoration: InputDecoration(hintText: changeName),
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
                    setNodeName(changeName);
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> removeNode() async {
    try {
      await FirebaseFirestore.instance
          .collection('node')
          .doc(nodeName)
          .delete();
      await FirebaseFirestore.instance
          .collection('node_setting')
          .doc(nodeName)
          .delete();
      await FirebaseFirestore.instance
          .collection('node_time')
          .doc(nodeName)
          .delete();
      await FirebaseFirestore.instance
          .collection('node_error') 
          .doc(nodeName) 
          .delete();
      await FirebaseFirestore.instance
          .collection('node_notification')
          .doc(nodeName)
          .delete();
      await FirebaseDatabase.instance.ref().child(nodeName).remove();
      Navigator.pop(context);
      EasyLoading.showSuccess('ลบ Node สำเร็จ');
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  Future<void> removeWaterHistory() async {
    try {
      await FirebaseFirestore.instance
          .collection('node_log_$nodeName')
          .get()
          .then((snapshot) {
        if (snapshot.docs.isEmpty) {
          EasyLoading.showError('ไม่มีประวัติระดับน้ำ');
          return;
        }
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
        EasyLoading.showSuccess('ลบประวัติระดับน้ำสำเร็จ');
      });
    } catch (e) {
      EasyLoading.showError(e.toString());
    }
  }

  String nodeDeleteConfirm = "";
  Future<void> _inputDialogRemoveNode(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('ยืนยันลบ $nodeName'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  nodeDeleteConfirm = value;
                });
              },
              controller: _textNodeRemove,
              decoration:
                  InputDecoration(hintText: 'พิมพ์ $nodeName เพื่อยืนยัน'),
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
                    if (nodeDeleteConfirm == nodeName) {
                      removeNode();
                      Navigator.pop(context);
                    } else {
                      EasyLoading.showError('ชื่อ Node ไม่ตรงกัน');
                    }
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _inputDialogNodeDescription(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไขรายละเอียด Node'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  nodeDescription = value;
                });
              },
              controller: _textNodeDescription,
              decoration: InputDecoration(hintText: nodeDescription),
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
                    setNodeDescription(nodeDescription);
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _inputDialogMessage(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไข Message Delay'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueMessage = value;
                });
              },
              controller: _textFieldMessage,
              decoration: const InputDecoration(hintText: "2xxxx"),
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
                    setMessageDelay();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _inputDialogSystem(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไข System Delay'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueSystem = value;
                });
              },
              controller: _textFieldSensor,
              decoration: const InputDecoration(hintText: "2xxxx"),
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
                    setSystemDelay();
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

  Future<void> _inputDialogSetting(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('แก้ไข Setting Delay'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueSetting = value;
                });
              },
              controller: _textFieldSetting,
              decoration: const InputDecoration(hintText: "4xxxxx"),
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
                    setSettingDelay();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            color: Colors.black87,
            onPressed: () {
              setState(() {
                _inputDialogRemoveNode(context);
              });
            },
          ),
        ],
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
              settingsGroupTitle: "การตั้งค่า $nodeName",
              settingsGroupTitleStyle: GoogleFonts.kanit(
                fontSize: 22,
                color: Colors.black87,
              ),
              items: [
                SettingsItem(
                  onTap: () {},
                  icons: Icons.settings,
                  trailing: Switch.adaptive(
                    value: switchNodeStatus,
                    onChanged: (value) {
                      setState(() {
                        switchNodeStatus = value;
                      });
                      if (switchNodeStatus == true) {
                        EasyLoading.showSuccess('เปิดใช้งาน $nodeName');
                        setNodeStatus('on');
                      } else {
                        EasyLoading.showInfo('ปิดใช้งาน $nodeName');
                        setNodeStatus('off');
                      }
                    },
                    activeTrackColor: Colors.redAccent,
                    activeColor: Colors.red[200],
                  ),
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "เปิดใช้งาน",
                  titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  subtitleStyle: GoogleFonts.kanit(
                    fontSize: 14,
                  ),
                ),
                SettingsItem(
                  onTap: () {},
                  icons: Icons.gps_fixed_rounded,
                  trailing: Switch.adaptive(
                    value: switchGps,
                    onChanged: (value) {
                      setState(() {
                        switchGps = value;
                      });
                      if (switchGps == true) {
                        EasyLoading.showSuccess('เปิดใช้งาน GPS $nodeName');
                        setGps(true);
                      } else {
                        EasyLoading.showInfo('ปิดใช้งาน GPS $nodeName');
                        setGps(false);
                      }
                    },
                    activeTrackColor: Colors.redAccent,
                    activeColor: Colors.red[200],
                  ),
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "ค้นหาตำแหน่ง",
                  titleStyle: GoogleFonts.kanit(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  subtitleStyle: GoogleFonts.kanit(
                    fontSize: 14,
                  ),
                ),
                SettingsItem(
                  onTap: () {},
                  icons: Icons.monitor_rounded,
                  trailing: Switch.adaptive(
                    value: switchLed,
                    onChanged: (value) {
                      setState(() {
                        switchLed = value;
                      });
                      if (switchLed == true) {
                        EasyLoading.showSuccess('เปิดใช้งาน LED $nodeName');
                        setLed('on');
                      } else {
                        EasyLoading.showInfo('ปิดใช้งาน LED $nodeName');
                        setLed('off');
                      }
                    },
                    activeTrackColor: Colors.redAccent,
                    activeColor: Colors.red[200],
                  ),
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.red[400],
                  ),
                  title: "โหนดแสดงผล",
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
                    _inputDialogNodeName(context);
                  },
                  icons: Icons.device_unknown_rounded,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "ชื่อโหนด",
                  subtitle: changeName,
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
                    _inputDialogNodeDescription(context);
                  },
                  icons: Icons.display_settings_outlined,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "รายละเอียดโหนด",
                  subtitle: nodeDescription,
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NodeConfigLocation(
                                  widgetNodeName: nodeName,
                                )));
                  },
                  icons: Icons.display_settings_outlined,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "สถานที่ตั้งโหนด",
                  subtitle: 'Latitude: $lat, \nLongitude: $long',
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
                    checkConfigNode1();
                    _inputDialogMessage(context);
                  },
                  icons: Icons.display_settings_outlined,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "เปลี่ยนค่าดีเลย์ข้อความแจ้งเตือน",
                  subtitle: '$valueMessage ms',
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
                    checkConfigNode1();
                    _inputDialogSystem(context);
                  },
                  icons: Icons.display_settings_outlined,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "เปลี่ยนค่าดีเลย์ระบบ",
                  subtitle: '$valueSystem ms',
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
                    checkConfigNode1();
                    _inputDialogSetting(context);
                  },
                  icons: Icons.display_settings_outlined,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "เปลี่ยนค่าดีเลย์เช็คการตั้งค่า",
                  subtitle: '$valueSetting ms',
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NodeConfigMessage(
                                  widgetNodeName: nodeName,
                                )));
                  },
                  icons: Icons.message_rounded,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "ข้อความการแจ้งเตือน",
                  subtitle: '',
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
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('ยืนยันการลบประวัติระดับน้ำ $nodeName'),
                            content: const Text(
                                'คุณต้องการลบประวัติระดับน้ำทั้งหมดหรือไม่?'),
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
                                    removeWaterHistory();
                                    Navigator.pop(context);
                                  });
                                },
                              ),
                            ],
                          );
                        });
                  },
                  icons: Icons.waterfall_chart_rounded,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "ลบประวัติระดับน้ำ",
                  subtitle: "",
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
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('ยืนยันการรีสตาร์ทบอร์ด'),
                            content:
                                const Text('คุณต้องการรีสตาร์ทบอร์ดใช่หรือไม่'),
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
                                    setRestart();
                                    Navigator.pop(context);
                                  });
                                },
                              ),
                            ],
                          );
                        });
                  },
                  icons: Icons.restart_alt_rounded,
                  iconStyle: IconStyle(
                    withBackground: true,
                    borderRadius: 50,
                    backgroundColor: Colors.blue[400],
                  ),
                  title: "รีสตาร์ทบอร์ด",
                  subtitle: "",
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
