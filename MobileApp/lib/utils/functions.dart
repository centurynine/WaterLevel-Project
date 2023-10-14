import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:async';

String apiKey = '';
String city = 'Thanyaburi';
var defaultRespond = {
  "location": {"name": "Error"},
  "current": {
    "temp_c": 0,
    "condition": {
      "text": "Error",
    }
  }
};
Future<Map<String, dynamic>> fetchWeatherData(double lat, double lng) async {
  try {
    await FirebaseFirestore.instance
        .collection('api')
        .doc('weather_api')
        .get()
        .then((value) => {
              apiKey = value.data()!['key'],
            });
    var response = await http.get(
      Uri.parse(
          'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$lat,$lng'),
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = json.decode(response.body);
      String textCondition =
          responseData['current']['condition']['text'].toString();
      if (textCondition.length > 20) {
        textCondition = textCondition.substring(0, 20);
        responseData['current']['condition']['text'] = '$textCondition..';
      }
      return responseData;
    } else {
      return defaultRespond;
    }
  } catch (e) {
    return defaultRespond;
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
