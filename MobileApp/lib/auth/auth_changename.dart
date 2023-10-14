import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/nav.dart';
import '../utils/error_log.dart';
import 'auth_setting.dart';


class ChangeName extends StatefulWidget {
  const ChangeName({super.key});
  @override
  State<ChangeName> createState() => _ChangeNameState();
}
 
class _ChangeNameState extends State<ChangeName> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? nameNew;

@override
void initState() {
  if (FirebaseAuth.instance.currentUser == null) {
    Navigator.pushNamed(context, '/login');
  } else {
    getName();
  }
  super.initState();
}

  Future<void> getName() async {
    try {
    if(FirebaseAuth.instance.currentUser != null){
      await FirebaseFirestore.instance
      .collection('user')
      .where('email', isEqualTo: FirebaseAuth.instance.currentUser!.email)
      .get()
      .then((value) => value.docs.forEach((element) {
        setState(() {
          nameController.text = element['name'];
        });
      }));
    }
  else {
    Navigator.pushNamed(context, '/');
  }
    }catch (e) {
      sendErrorLog('$e', 'auth_changename');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer:  const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(' เปลี่ยนชื่อแสดงผล',
            style: TextStyle(color: Colors.black87)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: SizedBox(
              height: 100,
              child: Image.asset(
                  "assets/images/idcard.png"),
            ),
          ),
          const SizedBox(height: 80),
          Text(
            "           เปลี่ยนชื่อแสดงผล",
            style: GoogleFonts.kanit(
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          Text(
            "             กรอกชื่อเพื่อเปลี่ยน",
            style: GoogleFonts.kanit(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Container(
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: nameText()),
          ),
          const SizedBox(height: 20),
          Container(
              margin: const EdgeInsets.only(left: 100.0, right: 100.0),
              child: buildButton()),
        ]),
      ),
    );
  }

  TextFormField nameText() {
    return TextFormField(
      controller: nameController,
      maxLength: 25,
      onSaved: (value) {
        nameNew = value!.trim();
      },
      validator: (value) {
        if (!validateUsername(value!)) {
          return 'กรุณากรอกชื่อให้มากกว่า 6 ตัวอักษร';
        } else {
          setState(() {
          nameNew = value;
        });
        }
          return null;
      },
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
        ),
        labelText: 'Display name',
        prefixIcon: Icon(Icons.email),
        hintText: 'Your Name',
      ),
    );
  }


  ElevatedButton buildButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.red[400],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      onPressed: () async {
        checkName();
      },
      child: const Text('ยืนยัน'),
    );
  }

  void checkName() async {
    final User? user = auth.currentUser;
    final email = user!.email;
    try {
    if (formKey.currentState!.validate()) {
      QuerySnapshot query = await FirebaseFirestore.instance
      .collection('user')
      .where('name' ,isEqualTo: nameNew)
      .get();
      if(query.docs.isEmpty){
        EasyLoading.show(status: 'กำลังโหลด...');
        changeName();
      }
      else {
         EasyLoading.showError('ชื่อนี้ถูกใช้ไปแล้ว');
      }
    } 
    } catch (e) {
      sendErrorLog('$e', 'auth_changename');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

 void changeName() async {
    final User? user = auth.currentUser;
    final email = user!.email;
    try {
    if (formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
      .collection('user')
      .where('uid' ,isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get()
      .then((value) => value.docs.forEach((element) {
        FirebaseFirestore.instance.collection('user').doc(element.id).update({
          'name': nameNew,
        });
      }));
      EasyLoading.dismiss();
      EasyLoading.showSuccess('เปลี่ยนชื่อสำเร็จแล้ว');
      Navigator.pop(context);
      
    }} catch (e) {
      sendErrorLog('$e', 'auth_changename');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  bool validateUsername(String value) {
    if (value.length < 6) {
      return false;
    } else {
      return true;
    }
  }


}