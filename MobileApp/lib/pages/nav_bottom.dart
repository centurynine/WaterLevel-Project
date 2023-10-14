import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DrawerBottom extends StatefulWidget {
  const DrawerBottom({super.key});

  @override
  State<DrawerBottom> createState() => _DrawerBottomState();
}

class _DrawerBottomState extends State<DrawerBottom> {
  @override
  Widget build(BuildContext context) {
    return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                            ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),

                  child: Stack(
                    children: [Row(
                      
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 240, 249, 255),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                              ),
                            ),
                            height: 50,
                            //color: Color.fromARGB(255, 240, 249, 255),
                            child: const Center(
                              child: Text('หน้าแรก'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 50,
                            color: const Color.fromARGB(255, 240, 249, 255),
                  
                            child: const Center(
                              child: Text(''),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 240, 249, 255),
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                              ),
                            ),
                            height: 50,
                            child: const Center(
                              child: Text('ตั้งค่า'),
                            ),
                          ),
                        ),
                            
                      ],
                    ),
                  ]
                  ),
                ));

  }
}
