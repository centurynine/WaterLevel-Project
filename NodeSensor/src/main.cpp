#include <Arduino.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include "time.h"
#include <WiFiUdp.h>
#include <NTPClient.h>
#include <soc/soc.h>
#include <soc/rtc_cntl_reg.h>
#include <TinyGPSPlus.h>
#include <SoftwareSerial.h>

 
#define voltageValue 34
float percentage = 0.0;

static const int RXPin = 16, TXPin = 17;
static const uint32_t GPSBaud = 9600;
TinyGPSPlus gps;
SoftwareSerial ss(RXPin, TXPin);

WiFiClient client;
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

#define FirebaseFS_H
#define ENABLE_FIRESTORE
#define WIFI_SSID "WaterLevelSensor"
#define WIFI_PASSWORD "1212312121"
#define API_KEY "" // Firebase API
#define FIREBASE_PROJECT_ID "" // Firebase Project ID
#define USER_EMAIL "" // Firebase User Email
#define USER_PASSWORD "" // Firebase User Password
#define DATABASE_URL "" // Firebase Realtime Database URL
#define FIREBASE_MESSAGE_KEY "" // Firebase Cloud Messaging Key
#define FIREBASE_CLIENT_EMAIL "" // Firebase Service Account Email ( xxx@appspot.gserviceaccount.com )

const char *host = "fcm.googleapis.com";
const int httpsPort = 443;

String weekDays[7] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
String months[12] = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};

String messageTitle = "Water Level";
String messageBody = "ระดับน้ำ";
String warningTitle = "แจ้งเตือนแอดมิน";
String warningBody = "ระดับน้ำมีค่าเกิน";
String nodestatus = "on";

String hour;
String minute;
String second;
String currentDate;
String CurrentDayString;
String CurrentMonthString;

int currentYear;
int currentMonth;
int currentDay;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
String uid;

String databasePath;
String DistancePath;
int dataDistance[4];

unsigned long sendMessagePrevMillis = 0;
unsigned long timerMessageDelay = 20000;

unsigned long sendDataPrevMillis = 0;
unsigned long timerDelay = 20000;

unsigned long sendSettingMillis = 0;
unsigned long SettingDelay = 20000;

unsigned long checkSettingMillis = 0;
unsigned long checkSettingDelay = 25000;

unsigned long checkNodeStatus = 0;
unsigned long checkNodeStatusDelay = 40000;

unsigned long checkTimeMillis = 0;
unsigned long checkTimeDelay = 25000;

unsigned long saveLogMillis = 0;
unsigned long saveLogDelay = 25000;

unsigned long startSystemMillis = 0;
unsigned long startSystemDelay = 25000;

unsigned long wifiMillis = 50000;
unsigned long wifiDelay = 50000;

unsigned long warningMillis = 0;
unsigned long warningDelay = 500000;

unsigned long voltageMillis = 0;
unsigned long voltageDelay = 900000;

unsigned long wifiCheckMillis = 0;
unsigned long wifiCheckDelay = 30000;

unsigned long notificationMillis = 0;
unsigned long notificationDelay = 500000;

const int pingPin = 5; // Trig
const int inPin = 18;  // Echo
int distanceNotConvert = 0;
int maximumRange = 300;
int minimumRange = -1;
int setDistance = 80;
long duration, distance;
String NodeName = "node1";
String documentHardwarePath = "node/" + NodeName;
String documentSettingPath = "node_setting/" + NodeName;
String documentLogPath = "node_log_" + NodeName;
String documentTimePath = "node_time/" + NodeName;
String documentNotificationPath = "node_notification/water_notification";
String documentLatestSend = "node_notification/" + NodeName;
String documentErrorPath = "node_error/" + NodeName;

int errorCount = 0;
int errorWifiCount = 0;
int errorSensor = 0;
bool isErrorSensor = false;

int countNotification = 0;
int distanceLastedSendFCM = 0;
int latestSend[20];
int dataWater[20];
int distanceNow = 0;
bool notification = false;

bool loopSetup = true;
bool bootSetting = false;
bool restart = false;
bool gpsCheck = false;

int LED_BUILTIN = 2;

void initWiFi()
{

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi ..");
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print('.');
    delay(500);
    if (millis() - wifiMillis > wifiDelay)
    {
      wifiMillis = millis();
      Serial.println("Wifi Disconnect");
      WiFi.disconnect();
      delay(200);
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
    errorWifiCount = errorWifiCount + 1;
    if (errorWifiCount > 30)
    {
      Serial.println("Wifi Error");
      ESP.restart();
    }
  }
  Serial.println(WiFi.localIP());
  Serial.println();
}

void getNotification()
{

  String checkNull[20];
  Serial.println("Get notification from Firestore... ");
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentNotificationPath.c_str()))
  {
    DynamicJsonDocument doc(2048);

    DeserializationError error = deserializeJson(doc, fbdo.payload());
    if (error)
    {
      Serial.print(F("deserializeJson() failed: "));
      Serial.println(error.f_str());
    }
    String water = "";
    JsonObject object = doc.as<JsonObject>();
    JsonVariant object_notification = object["fields"]["notification"]["booleanValue"];
    notification = object_notification.as<bool>();
    countNotification = 0;
    for (int i = 0; i < 25; i++)
    {
      JsonVariant object_distance = object["fields"]["id" + String(i + 1)]["integerValue"];
      checkNull[i] = object_distance.as<String>();
      if (checkNull[i] == NULL || checkNull[i] == "null")
      {
        break;
      }
      dataWater[i] = object_distance.as<int>();
      countNotification = countNotification + 1;
      Serial.println(dataWater[i]);
    }
    if (notification)
    {
      Serial.println(object.size());
      Serial.println("Notification: " + String(countNotification));
      Serial.println("=======================================");
    }
  }
  else
  {
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
  delay(100);
}

void updateLatestDistanceSendFCM(String id, int distance)
{
  FirebaseJson contentDistanceLatest;
  contentDistanceLatest.set("fields/id" + id + "/integerValue", distance);
  Serial.println("Update a document Latest send... ");
  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentLatestSend.c_str(), contentDistanceLatest.raw(), "id" + id))
  {
    Serial.println("Update Latest send success!");
  }
  else
  {
    Serial.println(fbdo.errorReason());
  }
}

void getLatestSend()
{

  String checkNull[20];
  Serial.println("Get latest send from Firestore... ");
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentLatestSend.c_str()))
  {
    DynamicJsonDocument doc(2048);

    DeserializationError error = deserializeJson(doc, fbdo.payload());
    if (error)
    {
      Serial.print(F("deserializeJson() failed: "));
      Serial.println(error.f_str());
    }
    JsonObject object = doc.as<JsonObject>();
    for (int i = 0; i < 25; i++)
    {
      JsonVariant object_latestsend = object["fields"]["id" + String(i + 1)]["integerValue"];
      checkNull[i] = object_latestsend.as<String>();
      if (checkNull[i] == NULL || checkNull[i] == "null")
      {
        break;
      }
      latestSend[i] = object_latestsend.as<int>();
      Serial.println("latestSend: " + String(latestSend[i]));
    }
  }
  else
  {
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
  delay(100);
}

void getNodeStatus()
{

  Serial.println("Get on/off status from Firestore... ");
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentHardwarePath.c_str()))
  {
    DynamicJsonDocument doc(2048);
    DeserializationError error = deserializeJson(doc, fbdo.payload());
    if (error)
    {
      Serial.print(F("deserializeJson() failed: "));
      Serial.println(error.f_str());
    }
    JsonObject object = doc.as<JsonObject>();
    JsonVariant object_nodestatus = object["fields"]["status"]["stringValue"];
    nodestatus = object_nodestatus.as<String>();
    Serial.println("Status: " + nodestatus);
    Serial.println("=======================================");
  }
  else
  {
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
  delay(100);
}

void getHardwareBoot()
{

  Serial.println("Get settings from Firestore... ");

  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentSettingPath.c_str()))
  {
    DynamicJsonDocument doc(2048);
    DeserializationError error = deserializeJson(doc, fbdo.payload());
    if (error)
    {
      Serial.print(F("deserializeJson() failed: "));
      Serial.println(error.f_str());
    }
    JsonObject object = doc.as<JsonObject>();
    JsonVariant object_bootsetting = object["fields"]["setting"]["booleanValue"];
    JsonVariant object_restart = object["fields"]["restart"]["booleanValue"];
    JsonVariant object_gps = object["fields"]["gps"]["booleanValue"];
    bootSetting = object_bootsetting.as<bool>();
    restart = object_restart.as<bool>();
    gpsCheck = object_gps.as<bool>();
    Serial.println("bootSetting: " + String(bootSetting));
    Serial.println("restart: " + String(restart));
    Serial.println("gpsCheck: " + String(gpsCheck));
    Serial.println("=======================================");
  }
  else
  {
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
  delay(100);
}

void getConfigFirebase()
{

  Serial.println("Get config from Firestore... ");
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentSettingPath.c_str()))
  {
    DynamicJsonDocument doc2(2048);
    DeserializationError error = deserializeJson(doc2, fbdo.payload());
    if (error)
    {
      Serial.print(F("deserializeJson() failed: "));
      Serial.println(error.f_str());
    }
    JsonObject object = doc2.as<JsonObject>();
    JsonVariant object_messageDelay = object["fields"]["message_delay"]["stringValue"];
    JsonVariant object_settingDelay = object["fields"]["setting_delay"]["stringValue"];
    JsonVariant object_messageTitle = object["fields"]["message_title"]["stringValue"];
    JsonVariant object_messageBody = object["fields"]["message_body"]["stringValue"];
    JsonVariant object_systemDelay = object["fields"]["system_delay"]["stringValue"];
    timerMessageDelay = object_messageDelay.as<String>().toInt();
    SettingDelay = object_settingDelay.as<String>().toInt();
    checkSettingDelay = SettingDelay;
    messageTitle = object_messageTitle.as<String>();
    messageBody = object_messageBody.as<String>();
    startSystemDelay = object_systemDelay.as<String>().toInt();

    Serial.println("timerMessageDelay: " + String(timerMessageDelay));
    Serial.println("SettingDelay: " + String(SettingDelay));
    Serial.println("messageTitle: " + messageTitle);
    Serial.println("messageBody: " + messageBody);
    Serial.println("startSystemDelay: " + String(startSystemDelay));
    Serial.println("=======================================");
  }
  else
  {
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
  delay(100);
}

void updateVoltage(float voltage)
{
  String voltageString = String(voltage);
  FirebaseJson contentVoltage;
  contentVoltage.set("fields/voltage/stringValue", voltageString);
  Serial.println("Update a document voltage... ");
  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentHardwarePath.c_str(), contentVoltage.raw(), "voltage"))
  {
    Serial.println("Update voltage!");
  }
  else
  {
    Serial.println(fbdo.errorReason());
  }
}

void sendFloat(String path, float value)
{
  if (Firebase.RTDB.setFloat(&fbdo, path.c_str(), value))
  {
    Serial.print("Writing value: ");
    Serial.print(value);
    Serial.print(" on the following path: ");
    Serial.println(path);
    Serial.println("PASSED");
    Serial.println("PATH: " + fbdo.dataPath());
    Serial.println("TYPE: " + fbdo.dataType());
  }
  else
  {
    Serial.println("FAILED");
    Serial.println("REASON: " + fbdo.errorReason());
    // ESP.restart();
  }
}

void ledBlink()
{
  digitalWrite(LED_BUILTIN, HIGH);
  delay(500);
  digitalWrite(LED_BUILTIN, LOW);
  delay(500);
}

void getTime()
{
  boolean loopTime = true;
  while (loopTime == true)
  {
    timeClient.update();
    timeClient.setTimeOffset(25200);
    time_t epochTime = timeClient.getEpochTime();
    Serial.print("Epoch Time: ");
    Serial.println(epochTime);

    String weekDay = weekDays[timeClient.getDay()];
    Serial.print("Week Day: ");
    Serial.println(weekDay);
    String time = timeClient.getFormattedTime();
    Serial.println(time);

    hour = time.substring(0, 2);
    minute = time.substring(3, 5);
    second = time.substring(6, 8);
    String currentTime = String(hour) + ":" + String(minute) + ":" + String(second);

    struct tm *ptm = gmtime((time_t *)&epochTime);
    currentDay = ptm->tm_mday;
    currentMonth = ptm->tm_mon + 1;
    String currentMonthName = months[currentMonth - 1];
    currentYear = ptm->tm_year + 1900;
    CurrentDayString = String(currentDay);
    CurrentMonthString = String(currentMonth);
    if (currentDay < 10)
    {
      CurrentDayString = "0" + String(currentDay);
    }
    if (currentMonth < 10)
    {
      CurrentMonthString = "0" + String(currentMonth);
    }

    currentDate = String(currentYear) + "-" + String(CurrentMonthString) + "-" + String(CurrentDayString);
    Serial.print("Current date: ");
    Serial.println(currentDate);
    if (String(currentYear) == "1970")
    {
      loopTime = true;
    }
    else
    {
      loopTime = false;
      FirebaseJson contentTime;
      contentTime.set("fields/currentTime/stringValue", time);
      Serial.println("Update a document time... ");
      if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentTimePath.c_str(), contentTime.raw(), "currentTime"))
      {
        Serial.println("Update time success!");
      }
      else
      {
        Serial.println(fbdo.errorReason());
      }
      // date
      FirebaseJson contentDate;
      contentDate.set("fields/currentDate/stringValue", currentDate);
      Serial.println("Update a document date... ");
      if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentTimePath.c_str(), contentDate.raw(), "currentDate"))
      {
        Serial.println("Update date success!");
      }
      else
      {
        Serial.println(fbdo.errorReason());
      }
      // time error check
    }
  }
  delay(100);
}

void setup()
{
  // WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);

  Serial.begin(9600);

  Serial.println("GPS Connecting...");
  ss.begin(GPSBaud);
  pinMode(voltageValue, INPUT);
  analogReadResolution(12);
  // Serial.println(TinyGPSPlus::libraryVersion());

  // Serial.println("GPS Connected");
  pinMode(LED_BUILTIN, OUTPUT);
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  initWiFi();
  Firebase.reconnectWiFi(true);

  fbdo.setResponseSize(4096);
  config.token_status_callback = tokenStatusCallback;
  config.max_token_generation_retry = 5;
  Firebase.begin(&config, &auth);
  Serial.println("Getting User UID");
  while ((auth.token.uid) == "")
  {
    Serial.print('.');
    delay(100);
  }
  timeClient.begin();
  timeClient.setTimeOffset(25200);
  getTime();

  uid = auth.token.uid.c_str();
  Serial.print("User UID: ");
  Serial.println(uid);
  databasePath = "/" + NodeName;
  DistancePath = databasePath + "/Distance";
  getNotification();
  getHardwareBoot();
  getConfigFirebase();
}
void (*resetFunc)(void) = 0; // void reset arduino but not use

void GPSDisplay()
{
  if (gps.location.isValid())
  {
    float lat = gps.location.lat();
    float lng = gps.location.lng();
    FirebaseJson contentLog;
    Serial.print("Latitude: ");
    Serial.println(lat, 6);
    Serial.print("Longitude: ");
    Serial.println(lng, 6);
    contentLog.set("fields/location/mapValue/fields/latitude/doubleValue", lat);
    Serial.print("Update a document Latitude... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentHardwarePath, contentLog.raw(), "location.latitude"))
    {
    }
    else
    {
      Serial.println(fbdo.errorReason());
    }
    //
    contentLog.set("fields/location/mapValue/fields/longitude/doubleValue", lng);
    Serial.print("Update a document Longitude... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentHardwarePath, contentLog.raw(), "location.longitude"))
    {
      gpsCheck = false;
    }
    else
    {
      Serial.println(fbdo.errorReason());
    }
    gpsCheck = false;
    FirebaseJson contentGPS;
    contentGPS.set("fields/gps/booleanValue", false);
    Serial.print("Update a document Gps Check... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentSettingPath.c_str(), contentGPS.raw(), "gps"))
    {
    }
    else
    {
      Serial.println(fbdo.errorReason());
    }
  }
  else
  {
    Serial.print(F("INVALID LOCATION"));
  }

  Serial.print(F("  Date/Time: "));
  if (gps.date.isValid())
  {
    Serial.print(gps.date.month());
    Serial.print(F("/"));
    Serial.print(gps.date.day());
    Serial.print(F("/"));
    Serial.print(gps.date.year());
  }
  else
  {
    Serial.print(F("INVALID"));
  }

  Serial.print(F(" "));
  if (gps.time.isValid())
  {
    if (gps.time.hour() < 10)
      Serial.print(F("0"));
    Serial.print(gps.time.hour());
    Serial.print(F(":"));
    if (gps.time.minute() < 10)
      Serial.print(F("0"));
    Serial.print(gps.time.minute());
    Serial.print(F(":"));
    if (gps.time.second() < 10)
      Serial.print(F("0"));
    Serial.print(gps.time.second());
    Serial.print(F("."));
    if (gps.time.centisecond() < 10)
      Serial.print(F("0"));
    Serial.print(gps.time.centisecond());
  }
  else
  {
    Serial.print(F("INVALID"));
  }

  Serial.println();
}
void loop()
{

  if ((WiFi.status() != WL_CONNECTED) && (millis() - wifiCheckMillis >= wifiCheckDelay))
  {
    wifiCheckMillis = millis();
    Serial.println("Reconnecting to WiFi...");
    WiFi.disconnect();
    WiFi.reconnect();
  }
  else
  {
    ledBlink();
  }
//  13.1 1.14
  // if (millis() - voltageMillis > voltageDelay || voltageMillis == 0)
  // {
    voltageMillis = millis();
    int voltage = analogRead(voltageValue);
    float voltageDB = (voltage / 1500.0) * 13.1;
    if (voltageDB > 13.1) {
      updateVoltage(13.1);
    } else {
    Serial.println("Raw value = " + String(voltage));
    Serial.println("Voltage = " + String(voltageDB) + "V");
    percentage = (((voltage / 1500.0) * 13.1) / 13.1) * 100.0;
    Serial.println("Percentage = " + String(percentage, 2) + "%");
    Serial.println("===============");
    delay(500);
    updateVoltage(voltageDB);
   // }
  }

  if (millis() - notificationMillis > notificationDelay)
  {
    notificationMillis = millis();
    getNotification();
  }

  if (gpsCheck == true)
  {
    while (ss.available() > 0)
      if (gps.encode(ss.read()))
        GPSDisplay();
    if (millis() > 5000 && gps.charsProcessed() < 10)
    {
      Serial.println(F("No GPS detected: check wiring."));
    }
  }

  if (millis() - checkNodeStatus > checkNodeStatusDelay || checkNodeStatus == 0)
  {
    checkNodeStatus = millis();
    getNodeStatus();
  }
  if (nodestatus == "on")
  {
    if (millis() - checkSettingMillis > checkSettingDelay || checkSettingMillis == 0)
    {
      getHardwareBoot();
      checkSettingMillis = millis();
      if (restart == 1)
      {
        FirebaseJson contentRestart;
        contentRestart.set("fields/restart/booleanValue", false);
        Serial.print("Update a document Restart... ");
        if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentSettingPath.c_str(), contentRestart.raw(), "restart"))
        {
          Serial.printf("ok\n%s\n\n", fbdo.payload().c_str());
        }
        else
        {
          Serial.println(fbdo.errorReason());
        }
        delay(100);
        Serial.println("Restarting....");
        ESP.restart();
      }
      if (bootSetting == 1)
      {
        while (bootSetting == true)
        {
          if (Firebase.ready() && (millis() - sendSettingMillis > SettingDelay))
          {
            sendSettingMillis = millis();
            Serial.println("Starting setting...");

            getConfigFirebase();
            if (timerMessageDelay == 0 || timerDelay == 0 || SettingDelay == 0)
            {

              getConfigFirebase();
              bootSetting = true;
            }
            else
            {
              bootSetting = false;
            }
          }
          bootSetting = false;
          FirebaseJson contentSetting;
          contentSetting.set("fields/setting/booleanValue", false);
          Serial.print("Update a document Setting... ");
          if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentSettingPath.c_str(), contentSetting.raw(), "setting"))
          {
            Serial.printf("Update setting to false");
          }
          else
          {
            Serial.println(fbdo.errorReason());
          }
          Serial.println("Restart Setting Success....");
          delay(100);
        }
      }
    }

    if (millis() - startSystemMillis > startSystemDelay || startSystemMillis == 0)
    {
      startSystemMillis = millis();
      if (millis() - checkTimeMillis > checkTimeDelay)
      {
        checkTimeMillis = millis();
        getTime();
      }
      bool passScan = false;
      while (bootSetting == true)
      {
        Serial.println("Setting mode...");
        getNotification();
        getConfigFirebase();
      }
      boolean loopSensor = true;
      while (loopSensor == true)
      {
        errorSensor = errorSensor + 1;
        for (int i = 0; i < 4;)
        {
          pinMode(pingPin, OUTPUT);
          digitalWrite(pingPin, LOW);
          delayMicroseconds(2);
          digitalWrite(pingPin, HIGH);
          delayMicroseconds(5);
          digitalWrite(pingPin, LOW);
          pinMode(inPin, INPUT);
          duration = pulseIn(inPin, HIGH);
          distanceNotConvert = duration / 29 / 2;
          distance = abs(distanceNotConvert - setDistance);
          dataDistance[i] = distance;
          Serial.print("Distance From Array");
          Serial.print(i);
          Serial.print(" : ");
          Serial.println(dataDistance[i]);
          i++;
          delay(500);
        }
        if (dataDistance[0] < maximumRange && dataDistance[0] >= minimumRange && ((dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] + 1 && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] + 1 && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3] + 1) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] + 1 && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] + 1 && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3] + 1) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] && dataDistance[1] == dataDistance[3] + 1 && dataDistance[2] == dataDistance[3] + 1) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3] + 1) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] + 1 && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3] + 1) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3] + 1) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] + 1 && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3] + 1) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] + 1 && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] + 1 && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] + 1 && dataDistance[2] == dataDistance[3]) || (dataDistance[0] == dataDistance[1] + 1 && dataDistance[0] == dataDistance[2] + 1 && dataDistance[0] == dataDistance[3] + 1 && dataDistance[1] == dataDistance[2] + 1 && dataDistance[1] == dataDistance[3] && dataDistance[2] == dataDistance[3] + 1)))
        {
          errorSensor = 0;
          passScan = true;
          loopSensor = false;

          Serial.println("Get error... ");
          if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentErrorPath.c_str()))
          {
            DynamicJsonDocument doc(2048);
            DeserializationError error = deserializeJson(doc, fbdo.payload());
            if (error)
            {
              Serial.print(F("deserializeJson() failed: "));
              Serial.println(error.f_str());
            }
            JsonObject object = doc.as<JsonObject>();
            JsonVariant object_sensor = object["fields"]["sensor"]["booleanValue"];
            isErrorSensor = object_sensor.as<boolean>();
            Serial.println("Status: " + isErrorSensor);
            Serial.println("=======================================");
          }
          else
          {
            Serial.println(fbdo.errorReason());
            errorCount = errorCount + 1;
          }

          if (isErrorSensor == true)
          {
            isErrorSensor = false;

            FirebaseJson contentError;
            contentError.set("fields/sensor/booleanValue", false);
            Serial.println("Update a document error... ");
            if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentErrorPath.c_str(), contentError.raw(), "sensor"))
            {
              Serial.println("Update error success!");
            }
            else
            {
              Serial.println(fbdo.errorReason());
            }
          }
        }
        else
        {
          passScan = false;
          loopSensor = true;
          Serial.println("!!! Vaule is not same");
        }
        if (errorSensor > 100)
        {
          isErrorSensor = true;
          Serial.println("!!! Sensor Error");
          passScan = true;
          loopSensor = false;

          FirebaseJson contentError;
          contentError.set("fields/sensor/booleanValue", true);
          Serial.println("Update a document error... ");
          if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentErrorPath.c_str(), contentError.raw(), "sensor"))
          {
            Serial.println("Update error success!");
          }
          else
          {
            Serial.println(fbdo.errorReason());
          }
        }
      }
      while (passScan == true)
      {
        if (distance >= maximumRange || distance <= minimumRange)
        {
          Serial.println("Out of range"); // เมื่ออยู่นอกระยะ
        }
        else if (distance <= 10)
        {
          Serial.print("Distance: ");
          Serial.print(distance); // แสดงค่าระยะทาง
          Serial.println("   #ระยะสีเขียว");
        }
        else if (distance <= 20)
        {
          Serial.print("Distance: ");
          Serial.print(distance); // แสดงค่าระยะทาง
          Serial.println("   #ระยะสีเหลือง");
        }
        else if (distance <= 30)
        {
          Serial.print("Distance: ");
          Serial.print(distance); // แสดงค่าระยะทาง
          Serial.println("   #ระยะสีส้ม");
        }
        else if (distance <= 40)
        {
          Serial.print("Distance: ");
          Serial.print(distance); // แสดงค่าระยะทาง
          Serial.println("   #ระยะสีแดง");
        }
        else if (distance <= 61)
        {
          Serial.print("Distance: ");
          Serial.print(distance); // แสดงค่าระยะทาง
          Serial.println("   #ระยะสีแดงกะพริบ");
        }
        else
        {
          Serial.print("\nDistance: ");
          Serial.println(distance); // แสดงค่าระยะทาง
          Serial.println("   #Unknow");
        }

        if (distance >= 70)
        {

          if (millis() - warningMillis > warningDelay || warningMillis == 0)
          {
            warningMillis = millis();
            Serial.print("Warning to admin...");
            HTTPClient http;
            String data = "{";
            data = data + "\"to\": \"/topics/admin\",";
            data = data + "\"notification\": {";
            data = data + "\"body\": \"" + warningBody + " " + distance + " cm\",";
            data = data + "\"title\" : \"" + warningTitle + "\" ";
            data = data + "} }";
            http.begin("https://fcm.googleapis.com/fcm/send");
            http.addHeader("Authorization", FIREBASE_MESSAGE_KEY);
            http.addHeader("Content-Type", "application/json");
            http.addHeader("Host", "fcm.googleapis.com");
            http.addHeader("Content-Length", String(data.length()));
            http.POST(data);
            http.writeToStream(&Serial);
            http.end();
            Serial.println();
            Serial.println("Finished!");
            delay(1000);
          }
          delay(500);
        }

        if (notification == true)
        {
          if (millis() - sendMessagePrevMillis > timerMessageDelay || sendMessagePrevMillis == 0)
          {
            sendMessagePrevMillis = millis();
            getLatestSend();
            for (int i = 0; i < countNotification; i++)
            {
              String idTopic = String(i + 1);
              if (distance - latestSend[i] >= dataWater[i] || distance - latestSend[i] <= -dataWater[i])
              {
                Serial.print("connecting to fcm server...");
                HTTPClient http;
                String data = "{";
                data = data + "\"to\": \"/topics/" + NodeName + "_id" + idTopic + "\",";
                data = data + "\"notification\": {";
                data = data + "\"body\": \"" + messageBody + " " + distance + " cm\",";
                data = data + "\"title\" : \"" + messageTitle + "\" ";
                data = data + "} }";
                http.begin("https://fcm.googleapis.com/fcm/send");
                http.addHeader("Authorization", FIREBASE_MESSAGE_KEY);
                http.addHeader("Content-Type", "application/json");
                http.addHeader("Host", "fcm.googleapis.com");
                http.addHeader("Content-Length", String(data.length()));
                http.POST(data);
                http.writeToStream(&Serial);
                http.end();
                Serial.println();
                Serial.println("Finished!");
                delay(1000);
                String idSend = String(i + 1);
                int distanceSend = int(distance);
                Serial.println("dataWater: " + String(dataWater[i]));
                updateLatestDistanceSendFCM(idSend, distanceSend);
              }
            }
          }
          else
          {
            Serial.println("Not sending message (Delay)");
          }
        }
        else
        {
          Serial.println("Sending message is off");
        }
        if (distance <= maximumRange && distance >= minimumRange)
        {
          if (Firebase.ready() && (millis() - sendDataPrevMillis > timerDelay || sendDataPrevMillis == 0))
          {
            sendDataPrevMillis = millis();
            // Send readings to database:
            sendFloat(DistancePath, distance);
          }
          String distanceString = String(distance);
          String hourString = String(hour);
          String dateString = String(currentYear) + "_" + String(CurrentMonthString) + "_" + String(CurrentDayString);
          if (Firebase.ready() && (millis() - saveLogMillis > saveLogDelay || saveLogMillis == 0))
          {
            saveLogMillis = millis();
            FirebaseJson contentLog;

            contentLog.set("fields/D_" + dateString + "/mapValue/fields/H_" + hourString + "/stringValue", distanceString);
            Serial.print("Update a document Log... ");
            if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentLogPath + "/" + dateString, contentLog.raw(), "D_" + dateString + ".H_" + hourString))
            {
              Serial.println("Update a document log success");
            }
            else
            {
              Serial.println(fbdo.errorReason());
            }
          }
        }
        else
        {
          Serial.println("Out of range");
        }
        delay(100);
        passScan = false;
      }
      if (errorCount > 5)
      {
        //  ESP.restart();
      }
    }
    else
    {
      Serial.print(".");
      delay(1000);
    }
  }
  else
  {
    Serial.println("Node < " + NodeName + " > status: off");
    delay(1000);
  }
}