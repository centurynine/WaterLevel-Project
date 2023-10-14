import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/nav.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});
  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}
class _ForgotPasswordState extends State<ForgotPassword> {



  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  @override

  

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer:  const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Forgot Password',
            style: TextStyle(
              color: Colors.black87,
            )),
      
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Form(
        child: ListView(children: <Widget>[
          
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: SizedBox(
              height: 100,
              child: Image.asset(
                  "assets/images/forgotpassword.png"),
            ),
          ),
          const SizedBox(height: 80),
          Text("       Password Reset",
           style: GoogleFonts.kanit(
                        fontSize: 20,
                        color: Colors.black,
                      ),
          ),
           Text("              กรอกอีเมลล์ของคุณเพื่อรีเซ็ตรหัสผ่าน",
           style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      
                      
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Container(
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: forgorText()),
          ),
              const SizedBox(height: 20),
          Container(
              margin: const EdgeInsets.only(left: 100.0, right: 100.0),
              child: buildButton()),
              FirebaseAuth.instance.currentUser == null
                  ? registerButton(context)
                  : Container()
        ]

        
        ),
      ),
    );
  }

  TextFormField forgorText() {
    return TextFormField(
      controller: emailController,
      cursorColor: Colors.lightBlue,
      
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
       labelText: 'Email Address',
        labelStyle: GoogleFonts.kanit(
          fontSize: 15,
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (!validateEmail(value!)) {
          return 'Please enter your email';
        }
        return null;
      },
    );
  }

  ElevatedButton buildButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Colors.red[400],
        onPrimary: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      onPressed: () async {
        verifyEmail();
      },
      child: const Text('Reset Password'),
    );
  }

  Future verifyEmail() async {
    try {
      
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ส่งข้อมูลรีเซ็ทรหัสผ่านสำเร็จ")));
    } on FirebaseAuthException catch (e) {
      
       EasyLoading.showError('ไม่พบอีเมลล์นี้ในระบบ');
    }
  }

  bool validateEmail(String value) {
    RegExp regex = RegExp( 
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
    return (!regex.hasMatch(value)) ? false : true;
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
        Navigator.pushNamed(context, '/register');
      },
    );
  }

}