import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waterlevel/main.dart';

import '../utils/error_log.dart';
import '../utils/functions.dart';
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formstate = GlobalKey<FormState>();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController name = TextEditingController();
  String? countUser;
  String? countID;
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  final _debouncer = Debouncer(milliseconds: 200);
  void togglePasswordView() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }

  void toggleConfirmPasswordView() {
    setState(() {
      hideConfirmPassword = !hideConfirmPassword;
    });
  }

  @override
  void initState() {
    super.initState();
    checkUserAndNavigate();
  }

  void checkUserAndNavigate() async {
    if (await isUserLogged()) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyApp()));
    }
  }

  final auth = FirebaseAuth.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black87, size: 20),
          color: Colors.black87,
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        
      ),
      body: Form(
        key: _formstate,
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: SizedBox(
                height: 100,
                child: Image.asset("assets/images/register.png"),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              alignment: Alignment.topLeft,
              child: Text(
                "    สมัครสมาชิก",
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              "              กรอกข้อมูลเพื่อทำการลงทะเบียน",
              style: GoogleFonts.kanit(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.only(left: 40.0, right: 40.0),
              child: buildNameField(),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 40.0, right: 40.0),
              child: buildEmailField(),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 40.0, right: 40.0),
              child: buildPasswordField(),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 40.0, right: 40.0),
              child: buildConfirmPasswordField(),
            ),
            const SizedBox(height: 30),
            Container(
              height: 50,
              margin: const EdgeInsets.only(left: 100.0, right: 100.0),
              child: buildRegisterButton(),
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton buildRegisterButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.red[400],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      child: Text(
        'สมัครสมาชิก',
        style: GoogleFonts.kanit(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      onPressed: () async {
        _debouncer.run(() => 
           registerWithEmailPassword()
        );
         
      },
    );
  }

  Future<void> registerWithEmailPassword() async {
 
  if (FirebaseAuth.instance.currentUser == null) {
    if (password.text.length < 8) {
      EasyLoading.showError('กรุณากรอกรหัสผ่านมากกว่า 8 ตัวอักษร');
      return;
    }
    if (password.text != confirmPassword.text) {
      EasyLoading.showError('รหัสผ่านไม่ตรงกัน');
      return;
    }
    if (email.text.contains(" ")) { 
      EasyLoading.showError('อีเมลล์ไม่สามารถมีช่องว่าง');
      return;
    }
    try {
      final user = await auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
      FirebaseAuth.instance.currentUser!.updateDisplayName(name.text.trim());
      countDocuments();
      user.user!.sendEmailVerification();
      EasyLoading.showSuccess('โปรดยืนยันอีเมลล์');
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        EasyLoading.showError('รหัสผ่านมีความปลอดภัยต่ำ');
      } else if (e.code == 'email-already-in-use') {
        EasyLoading.showError('อีเมลนี้มีผู้ใช้งานแล้ว');
      } else if (e.code == 'operation-not-allowed') {
        EasyLoading.showError('ไม่สามารถดำเนินการได้');
      } else {
        sendErrorLog('$e', 'signup');
        EasyLoading.showError('ติดต่อผู้ดูแลระบบ');
      }
    }
  } else {
    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const MyApp()));
  }
}


  TextFormField buildPasswordField() {
    return TextFormField(
      controller: password,
      validator: (value) {
        if (value!.length < 8) {
          return 'Please Enter more than 8 Character';
        } else {
          return null;
        }
      },
      obscureText: hidePassword,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
        ),
        prefixIcon: const Icon(Icons.lock),
        labelText: 'Password',
        suffixIcon: IconButton(
          onPressed: togglePasswordView,
          icon: Icon(
            hidePassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
    );
  }

  TextFormField buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmPassword,
      validator: (value) {
        if (value!.isEmpty) return 'กรุณากรอกรหัสผ่านอีกครั้ง';
        if (value != password.text) return 'รหัสผ่านไม่ตรงกัน';
        return null;
      },
      obscureText: hideConfirmPassword,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
        ),
        prefixIcon: const Icon(Icons.lock),
        labelText: 'Confirm Password',
        suffixIcon: IconButton(
          onPressed: toggleConfirmPasswordView,
          icon: Icon(
            hideConfirmPassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
    );
  }

  TextFormField buildNameField() {
    return TextFormField(
      controller: name,
      validator: (value) {
        if (value!.isEmpty) {
          return 'กรุณากรอกชื่อ';
        } else {
          return null;
        }
      },
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
        ),
        prefixIcon: Icon(Icons.person),
        labelText: 'Name',
        hintText: 'Firstname Lastname',
      ),
    );
  }

  TextFormField buildEmailField() {
    return TextFormField(
      controller: email,
      validator: (value) {
        if (value!.isEmpty) {
          return 'กรุณากรอกอีเมล';
        } else {
          return null;
        }
      },
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
        ),
        prefixIcon: Icon(Icons.email),
        labelText: 'E-mail',
        hintText: 'email@example.com',
      ),
    );
  }

  Future<bool> isUserLogged() async {
    var user = auth.currentUser;
    if (user != null) {
      return true;
    } else {
      return false;
    }
  }

  void countDocuments() async {
    try {
    QuerySnapshot allUser = await FirebaseFirestore.instance.collection('user').get();
    List<DocumentSnapshot> myDocCount = allUser.docs;
    countUser = myDocCount.length.toString();
    updateDocuments();
    } catch (e) {
      sendErrorLog('$e', 'signup');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  void updateDocuments() async {
    try {
    QuerySnapshot query = await FirebaseFirestore.instance.collection('user_count').where('userallcount').get();
    if (query.docs.isNotEmpty) {
      FirebaseFirestore.instance.collection('user_count').doc(query.docs[0].id).update({"userallcount": FieldValue.increment(1)});
      createID();
    } else if (query.docs.isEmpty) {
    }} catch (e) {
      sendErrorLog('$e', 'signup');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  void createID() async {
    try {
    QuerySnapshot createcountid = await FirebaseFirestore.instance.collection('user_count').where('userallcount').get();
    if (createcountid.docs.isNotEmpty) {
      var countid = (createcountid.docs[0]['userallcount'].toString());
      setState(() {
        countID = countid;
      });
      uploadUser(countID!);
    }} catch (e) {
      sendErrorLog('$e', 'signup');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  void uploadUser(String countID) async {
    try {
    await FirebaseFirestore.instance.collection("user").doc(email.text).set({
      "id": countID,
      "uid": auth.currentUser!.uid,
      "email": email.text,
      "name": name.text,
      "admin": false.toString(),
      "created_at": DateTime.now().toUtc().add(const Duration(hours: 7)),
      "loginwith": 'Firebase',
    });
    await FirebaseFirestore.instance.collection('user_option').doc(email.text).set({
      "email": email.text,
      "notification": false.toString(),
      "fullscreen": true.toString(),
    });
    await FirebaseAuth.instance.signOut();
    goLoginPage();} catch (e) {
      sendErrorLog('$e', 'signup');
      EasyLoading.showError('เกิดข้อผิดพลาด');
    }
  }

  void goLoginPage() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login()));
  }
}
