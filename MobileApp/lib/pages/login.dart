import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../auth/auth_forgotpassword.dart';
import '../main.dart';
import '../utils/error_log.dart';
import '../utils/functions.dart';
import '../utils/storage.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _debouncer = Debouncer(milliseconds: 200);
  int status = 0;
  dynamic userEmail = "#Email";
  String userName = "#Name";

  final _formstate = GlobalKey<FormState>();
  String? email;
  String? password;
  final auth = FirebaseAuth.instance;
  bool hideCurrentPassword = true;
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signOut();
    if (FirebaseAuth.instance.currentUser != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const MyHomePage()));
      });
    }
  }

  void toggleCurrentPasswordView() {
    setState(() {
      hideCurrentPassword = !hideCurrentPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined,
                color: Colors.black87, size: 20),
            color: Colors.black87,
            onPressed: () {
              //   Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              Navigator.pushNamed(context, '/');
            },
          ),
        ),
        body: Form(
          autovalidateMode: AutovalidateMode.always,
          key: _formstate,
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: SizedBox(
                  height: 100,
                  child: Image.asset("assets/images/loginpage.png"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "    เข้าสู่ระบบ",
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: emailTextFormField(),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: passwordTextFormField(),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                margin: const EdgeInsets.only(left: 20.0, right: 10.0),
                child: forgetButton(context),
              ),
              Container(
                  margin: const EdgeInsets.only(left: 100.0, right: 100.0),
                  child: loginButton()),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      "ยังไม่ได้เป็นสมาชิก?",
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    )),
              ),
              Container(
                  margin: const EdgeInsets.only(left: 100.0, right: 100.0),
                  child: registerButton(context)),
            ],
          ),
        ));
  }

  GestureDetector registerButton(BuildContext context) {
    return GestureDetector(
      child: Container(
        alignment: Alignment.center,
        child: Text(
          "สมัครสมาชิก!",
          style: GoogleFonts.kanit(
            fontSize: 15,
            color: Colors.red[400],
          ),
        ),
      ),
      onTap: () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Signup()));
      },
    );
  }

  GestureDetector forgetButton(BuildContext context) {
    return GestureDetector(
      child: Container(
        alignment: Alignment.topRight,
        child: Text(
          "ลืมรหัสผ่าน?",
          style: GoogleFonts.kanit(
            fontSize: 15,
            color: Colors.red[400],
          ),
        ),
      ),
      onTap: () {
        Navigator.pushReplacement(context,
            CupertinoPageRoute(builder: (_) => const ForgotPassword()));
      },
    );
  }

  IconButton logoutButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      color: Colors.black,
      onPressed: () {
        _signOut();
      },
    );
  }

  IconButton loginfbButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.facebook),
      iconSize: 50.0,
      color: Colors.blue,
      onPressed: () {},
    );
  }

  ElevatedButton loginButton() {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red[400],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        onPressed: () async {
          _debouncer.run(() => login());
        },
        child: const Text('Login'));
  }

  Future login() async {
    if (FirebaseAuth.instance.currentUser == null) {
      String? userRole = 'false';
      bool isAdmin = false;
      if (_formstate.currentState!.validate()) {
        _formstate.currentState!.save();
        try {
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email!, password: password!)
              .then((value) async {
            if (value.user!.emailVerified) {
              userEmail = value.user!.email!;
              await FirebaseFirestore.instance
                  .collection('user')
                  .doc(email)
                  .get()
                  .then((value) => {
                        userName = value.data()!['name'],
                        userRole = value.data()!['admin']
                      });
              if (userRole == 'true') {
                isAdmin = true;
                UserStorage user = UserStorage();
                user.isAdmin = true;
                user.email = userEmail;
                user.name = userName;
              } else {
                UserStorage user = UserStorage();
                user.isAdmin = false;
                user.email = userEmail;
                user.name = userName;
              }

              EasyLoading.showSuccess('เข้าสู่ระบบสำเร็จ!');
              Future.delayed(const Duration(seconds: 3), () {
                Navigator.pushNamed(context, '/');
              });
            } else {
              FirebaseAuth.instance.currentUser!.sendEmailVerification();
              await FirebaseAuth.instance.signOut();
              EasyLoading.showError('โปรดตรวจสอบข้อความในอีเมลของคุณ');
              Navigator.pushNamed(context, '/login');
            }
          }).catchError((reason) {
            if (reason.code == 'user-not-found') {
              EasyLoading.showError('ไม่พบผู้ใช้งาน');
            } else if (reason.code == 'wrong-password') {
              EasyLoading.showError('รหัสผ่านไม่ถูกต้อง');
            } else {
              EasyLoading.showError('เกิดข้อผิดพลาด');
              sendErrorLog('$reason', 'login');
            }
            Future.delayed(const Duration(seconds: 3), () {
              EasyLoading.dismiss();
            });
          });
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            EasyLoading.showError('ไม่พบผู้ใช้งาน');
          } else if (e.code == 'wrong-password') {
            EasyLoading.showError('รหัสผ่านไม่ถูกต้อง');
          } else {
            sendErrorLog('$e', 'login');
          }
        }
      } else {
        _showMyDialog();
      }
    }
  }

  TextFormField passwordTextFormField() {
    return TextFormField(
      onSaved: (value) {
        password = value!.trim();
      },
      validator: (value) {
        if (value!.length < 8) {
          return 'กรุณากรอกรหัสผ่านให้มากกว่า 8 ตัวอักษร';
        } else {
          return null;
        }
      },
      obscureText: hideCurrentPassword,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(22.0)),
        ),
        hintText: 'รหัสผ่าน',
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          onPressed: toggleCurrentPasswordView,
          icon: Icon(
            hideCurrentPassword ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
    );
  }

  TextFormField emailTextFormField() {
    return TextFormField(
      onSaved: (value) {
        email = value!.trim();
      },
      validator: (value) {
        if (!validateEmail(value!)) {
          return 'Please fill in E-mail field';
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
        labelText: 'E-mail',
        prefixIcon: Icon(Icons.email),
        hintText: 'email@example.com',
      ),
    );
  }

  bool validateEmail(String value) {
    RegExp regex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    return (!regex.hasMatch(value)) ? false : true;
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ผิดพลาด'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('กรุณากรอกอีเมลล์และรหัสผ่านให้ถูกต้อง'),
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('   ตกลง   '),
              ),
            ),
          ],
        );
      },
    );
  }

  Future _signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
