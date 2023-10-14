import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

import '../pages/nav.dart';

class NodeMap extends StatefulWidget {
  LatLng location;
  String nodeName;
  NodeMap({Key? key, required this.location, required String this.nodeName}) : super(key: key);

  @override
  State<NodeMap> createState() => _NodeMapState();
}
bool open = true;
class _NodeMapState extends State<NodeMap> {
 
  @override
  void initState() {
    super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const DrawerWidget(),
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'แผนที่ ${widget.nodeName}' ,
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
        body: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  height: 100.h,
                  width: 100.w,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    child: widget.location.latitude != 0 || widget.location.longitude != 0
                        ? Align(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.3,
                            widthFactor: 2.5,
                            child: GoogleMap(
                              markers: {
                                Marker(
                                  markerId: const MarkerId('node'),
                                  position: widget.location,
                                  infoWindow: const InfoWindow(
                                    title: 'Node',
                                    snippet: 'ตำแหน่ง Node',
                                  ),
                                ),
                              },
                              mapType: MapType.normal,
                              initialCameraPosition: CameraPosition(
                                target: widget.location,
                                zoom: 15,
                              ),
                            ),
                          )
                           :  Align(
                            alignment: Alignment.bottomRight,
                            heightFactor: 0.3,
                            widthFactor: 2.5,
                            child: Container(
                              child: const Center(
                                child: Text('ไม่พบตำแหน่ง Node'),
                              ),
                            ),
                          )
                        // : Center(
                        //     child: CircularProgressIndicator(),
                        //   ),
                  )),
            ],
          ),
        ));
  }
}
