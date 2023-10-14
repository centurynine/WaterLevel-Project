import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:waterlevel/utils/error_log.dart';

class About extends StatefulWidget {
  const About({Key? key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'คณะผู้จัดทำ',
          style: TextStyle(color: Colors.black87, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.black87, size: 20),
          color: Colors.black87,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          Container(
            
            margin: const EdgeInsets.only(left: 20, right: 20,top: 20),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 233, 245, 255),
              borderRadius: BorderRadius.circular(20),
            ),
            
            child: Column(
               
              children: [
 
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'นักศึกษาชั้นปีที่ 4 คณะวิศวกรรมศาสตร์',
                        style: TextStyle(
                            color: Color.fromARGB(221, 27, 27, 27),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'สาขาวิศวกรรมคอมพิวเตอร์',
                        style: TextStyle(
                            color: Color.fromARGB(221, 27, 27, 27),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                                            Text(
                        'มหาวิทยาลัยเทคโนโลยีราชมงคลธัญบุรี',
                        style: TextStyle(
                            color: Color.fromARGB(221, 27, 27, 27),
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/boy1.png',
                        width: 90,
                        height: 90,
                      ),
                      const Text(
                        'นายสรัล วรรณภูงา\n 116310400136-2 ',
                        style: TextStyle(
                            color: Color.fromARGB(221, 40, 39, 39),
                            fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'นายศิวกร กาญธนะบัตร\n 116310462002-1',
                        style: TextStyle(
                            color: Color.fromARGB(221, 40, 39, 39),
                            fontSize: 20),
                      ),
                        Image.asset(
                        'assets/images/boy2.png',
                        width: 90,
                        height: 90,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Image.asset(
                        'assets/images/boy3.png',
                        width: 90,
                        height: 90,
                      ),
                      const Text(
                        'นายบัณฑิต สงค์ประชา\n 116310462018-7',
                        style: TextStyle(
                            color: Color.fromARGB(221, 40, 39, 39),
                            fontSize: 20),
                      ),
                    ],
                  ),
                ),
                // เพิ่มรายละเอียดของอาจารย์ที่ปรึกษา
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: const Text(
                    'อาจารย์ที่ปรึกษา',
                    style: TextStyle(
                        color: Color.fromARGB(221, 27, 27, 27),
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: const Text(
                    'ผู้ช่วยศาสตราจารย์ ดร.พฤศยน นินทนาวงศา',
                    style: TextStyle(
                      color: Color.fromARGB(221, 40, 39, 39),
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  margin: const EdgeInsets.only(top: 10),
                  child: const Text(
                    'ผู้ช่วยศาสตราจารย์ เจษฎา อรุณฤกษ์',
                    style: TextStyle(
                      color: Color.fromARGB(221, 40, 39, 39),
                      fontSize: 18,
                    ),
                  ),
                ),
                // เพิ่มรายละเอียดอื่น ๆ ตามที่คุณต้องการ
              ],
            ),
          ),
        
          Column(
             
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              const SizedBox(
                height: 100,
              )
              ,Container(
                margin: const EdgeInsets.only(left:10 , right: 10),
                child: const Text('Icons made by Smashicons,Flat Icons,VectorsMarket,Freepik,Anggara,Creartive,Vectorslab,gungyoga04,bqlqn,justicon,Konkapp from www.flaticon.com',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54
                ) ,textAlign: TextAlign.center,
                ),
              )
            ],
          )
        ],
        
      ),
    );
  }
}
