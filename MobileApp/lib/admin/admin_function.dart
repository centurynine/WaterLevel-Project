import 'dart:convert';
import 'package:http/http.dart';

String key = "";
var httpsUri =
    Uri(scheme: 'https', host: 'fcm.googleapis.com', path: '/fcm/send');

Future<void> sendFCM() async {

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization':
        key,
  };
  String jsonMap = jsonEncode({
    "to": "/topics/all",
    "notification": {
      "title": "Water Level",
      "body": "ระดับน้ำเกินค่าที่กำหนดแล้ว"
    }
  });

  final encoding = Encoding.getByName('utf-8');
  Response response = await post(
    httpsUri,
    headers: headers,
    body: jsonMap,
    encoding: encoding,
  );
 
}

Future<void> sendFCMProblem(String topic,String title, String body) async {

  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization':
        key,
  };
  String jsonMap = jsonEncode({
    "to": "/topics/$topic",
    "notification": {
      "title": title,
      "body": body
    }
  });

  final encoding = Encoding.getByName('utf-8');
  Response response = await post(
    httpsUri,
    headers: headers,
    body: jsonMap,
    encoding: encoding,
  );
 
}
