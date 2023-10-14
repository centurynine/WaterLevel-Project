#include <Arduino.h>
#include <Firebase_ESP_Client.h>
#include <WiFi.h>
#include <ESP32-HUB75-MatrixPanel-I2S-DMA.h>
#include <Fonts/FreeMonoBold12pt7b.h>
#include <Fonts/FreeMonoBold9pt7b.h>
#include <Fonts/kongtext4pt7b.h>
#include <Fonts/FreeSerif9pt7b.h>
#include <Fonts/Tiny3x3a2pt7b.h>
#include <Adafruit_GFX.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

#define R1_PIN 25
#define G1_PIN 26
#define B1_PIN 27
#define R2_PIN 14
#define G2_PIN 12
#define B2_PIN 32
#define A_PIN 23
#define B_PIN 19
#define C_PIN 5
#define D_PIN 17
#define E_PIN -1
#define LAT_PIN 4
#define OE_PIN 15
#define CLK_PIN 16

#define voltageValue 34
float percentage = 0.0;

#define PANEL_RES_X 64
#define PANEL_RES_Y 32
#define PANEL_CHAIN 1

#define FirebaseFS_H
#define ENABLE_FIRESTORE
#define WIFI_SSID "WaterLevelLed"
#define WIFI_PASSWORD "1212312121"
#define API_KEY "" // Firebase API
#define FIREBASE_PROJECT_ID "" // Firebase Project ID
#define USER_EMAIL "" // Firebase User Email
#define USER_PASSWORD "" // Firebase User Password
#define DATABASE_URL "" // Firebase Realtime Database URL
#define FIREBASE_CLIENT_EMAIL "" // Firebase Service Account Email ( xxx@appspot.gserviceaccount.com )

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org");

String hour;
String minute;
String second;
String currentDate;
String CurrentDayString;
String CurrentMonthString;
int currentYear;
int currentMonth;
int currentDay;
String weekDays[7] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
String months[12] = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
String nodeSensorTime;

bool waterSensorError = false;
bool networkSensorOnline = false;
bool matchTime = false;
bool LEDStatus = true;
String status = "off";
MatrixPanel_I2S_DMA *dma_display = nullptr;
uint16_t myDARK = dma_display->color565(64, 64, 64);
uint16_t myWHITE = dma_display->color565(192, 192, 192);
uint16_t myRED = dma_display->color565(255, 0, 0);
uint16_t myGREEN = dma_display->color565(0, 255, 0);
uint16_t myBLUE = dma_display->color565(0, 0, 255);
uint16_t myBLACK = dma_display->color565(0, 0, 0);
uint16_t myPINK = dma_display->color565(255, 0, 255);
uint16_t mySKY = dma_display->color565(51, 153, 255);
uint16_t myTEST = dma_display->color565(255, 255, 255);
uint16_t myORANGE = dma_display->color565(255, 130, 55);
uint16_t myYELLOW = dma_display->color565(255, 255, 85);
uint16_t colours[11] = {myDARK, myWHITE, myRED, myGREEN, myBLUE, myBLACK, myPINK, mySKY, myTEST, myORANGE, myYELLOW};
uint16_t distanceColour = myWHITE;
uint16_t flagColour = myGREEN;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
String uid;
String distance;

String NodeName = "node1";
String documentHardwarePath = "node/" + NodeName;
String databasePath = "/" + NodeName + "/Distance";
String documentTimePath = "node_time/" + NodeName;
String documentErrorPath = "node_error/" + NodeName;
String documentDistancePath = "node_log_" + NodeName + "/";

unsigned long voltageMillis = 0;
unsigned long voltageDelay = 900000;

unsigned long getStatusMillis = 0;
unsigned long getStatusDelay = 20000;
unsigned long wifiMillis = 0;
unsigned long wifiDelay = 50000;
unsigned long loopMillis = 0;
unsigned long loopDelay = 5000;
unsigned long warningMillis = 0;
unsigned long warningDelay = 1000;
unsigned long timeMillis = 0;
unsigned long timeDelay = 10000;
unsigned long errorCheckMillis = 0;
unsigned long errorCheckDelay = 20000;
int errorCount = 0;

void initWiFi()
{
  WiFi.setSleep(false);
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi ..");
  dma_display->setCursor(2, 5);
  dma_display->setFont(&kongtext4pt7b);
  dma_display->setTextSize(1);
  dma_display->setTextColor(mySKY);
  dma_display->fillRect(0, 0, 64, 32, myBLACK);
  dma_display->printf("Wifi ");
  dma_display->setFont();
  dma_display->setCursor(2, 13);
  dma_display->printf("Connecting..");
  dma_display->setFont();
  delay(5000);
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print('.');
    delay(500);
    if (millis() - wifiMillis > wifiDelay)
    {
      wifiMillis = millis();
      Serial.println("Wifi Disconnect");
      WiFi.disconnect();
      delay(1000);
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
  }
  dma_display->setFont(&kongtext4pt7b);
  dma_display->setTextSize(1);
  dma_display->setTextColor(mySKY);
  dma_display->fillRect(0, 0, 64, 32, myBLACK);
  dma_display->setCursor(2, 5);
  dma_display->printf(WiFi.localIP().toString().c_str());
  dma_display->setFont();
  delay(3000);
  Serial.println(WiFi.localIP());
  Serial.println();
  dma_display->fillRect(0, 0, 64, 32, myBLACK);
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
    JsonVariant object_nodestatus = object["fields"]["led_status"]["stringValue"];
    status = object_nodestatus.as<String>();
    if (status == "on")
    {
      LEDStatus = true;
    }
    else
    {
      LEDStatus = false;
    }
    Serial.println("Status: " + LEDStatus);
    Serial.println("=======================================");
  }
  else
  {
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
  delay(100);
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

    currentDate = String(currentYear) + "_" + String(CurrentMonthString) + "_" + String(CurrentDayString);
    String currentDateUp = String(currentYear) + "-" + String(CurrentMonthString) + "-" + String(CurrentDayString);
    Serial.print("Current date: ");
    Serial.println(currentDate);
    if (String(currentYear) == "1970")
    {
      loopTime = true;
    }
    else
    {
      loopTime = false;
    }

    FirebaseJson contentTime;
    contentTime.set("fields/ledCurrentTime/stringValue", time);
    Serial.println("Update a document time... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentTimePath.c_str(), contentTime.raw(), "ledCurrentTime"))
    {
      Serial.println("Update time success!");
    }
    else
    {
      Serial.println(fbdo.errorReason());
    }

    FirebaseJson contentDate;
    contentDate.set("fields/ledCurrentDate/stringValue", currentDateUp);
    Serial.println("Update a document date... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentTimePath.c_str(), contentDate.raw(), "ledCurrentDate"))
    {
      Serial.println("Update date success!");
    }
    else
    {
      Serial.println(fbdo.errorReason());
    }
  }

  delay(100);
}

void getRTDB()
{

  if (Firebase.ready())
  {
    Serial.println("Getting RTDB");
    if (Firebase.RTDB.getFloat(&fbdo, databasePath.c_str()))
    {
      Serial.println("Get RTDB Success");
      distance = fbdo.payload().c_str();
      Serial.println(fbdo.payload().c_str());
    }
    else
    {
      errorCount = errorCount + 1;
      Serial.println("Get RTDB Failed");
      Serial.println(fbdo.errorReason().c_str());
    }
  }
}

void getError()
{
  Serial.println("Get error from Firestore... ");
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
    JsonVariant object_SensorError = object["fields"]["sensor"]["booleanValue"];
    waterSensorError = object_SensorError.as<bool>();
    Serial.println("Sensor Error: " + String(waterSensorError));
    Serial.println("=======================================");
  }
  else
  {
    errorCount = errorCount + 1;
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
}

void getNodeSensorTime()
{
  Serial.println("Get time Node Sensor from Firestore... ");
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentTimePath.c_str()))
  {
    DynamicJsonDocument doc(2048);
    DeserializationError error = deserializeJson(doc, fbdo.payload());
    if (error)
    {
      Serial.print(F("deserializeJson() failed: "));
      Serial.println(error.f_str());
    }
    JsonObject object = doc.as<JsonObject>();
    JsonVariant object_nodeSensorTime = object["fields"]["currentTime"]["stringValue"];
    nodeSensorTime = object_nodeSensorTime.as<String>();
    Serial.println("Node Sensor Time: " + nodeSensorTime);
    Serial.println("=======================================");
  }
  else
  {
    errorCount = errorCount + 1;
    Serial.println(fbdo.errorReason());
    // ESP.restart();
  }
}

void updateVoltage(float voltage)
{
    String voltageString = String(voltage);
    FirebaseJson contentVoltage;
    contentVoltage.set("fields/led_voltage/stringValue", voltageString);
    Serial.println("Update a document voltage... ");
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentHardwarePath.c_str(), contentVoltage.raw(), "led_voltage"))
    {
        Serial.println("Update voltage!");
    }
    else
    {
        Serial.println(fbdo.errorReason());
    }
}

void setup()
{
  Serial.begin(115200);
  HUB75_I2S_CFG mxconfig(
      PANEL_RES_X,
      PANEL_RES_Y,
      PANEL_CHAIN

  );
  mxconfig.latch_blanking = 4;
  mxconfig.i2sspeed = HUB75_I2S_CFG::HZ_10M;
  mxconfig.clkphase = false;

  dma_display = new MatrixPanel_I2S_DMA(mxconfig);
  dma_display->setPanelBrightness(200);
  dma_display->begin();
  dma_display->clearScreen();

  initWiFi();

  config.api_key = API_KEY;
  config.timeout.serverResponse = 10 * 1000;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  Firebase.reconnectWiFi(true);
  Firebase.reconnectNetwork(true);
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
  uid = auth.token.uid.c_str();
  Serial.print("User UID: ");
  Serial.println(uid);
  // Firebase.setDoubleDigits(5);
  dma_display->drawLine(0, 0, 63, 0, myWHITE);
  dma_display->drawLine(0, 0, 0, 31, myWHITE);
  dma_display->drawLine(63, 0, 63, 31, myWHITE);
  dma_display->drawLine(0, 31, 63, 31, myWHITE);
}

void loop()
{
   if (millis() - voltageMillis > voltageDelay || voltageMillis == 0)
   {
    voltageMillis = millis();
    int voltage = analogRead(voltageValue);
    float voltageDB = (voltage / 2700.0) * 13.1;
    if (voltageDB > 13.1) {
      updateVoltage(13.1);
    } else {
    Serial.println("Raw value = " + String(voltage));
    Serial.println("Voltage = " + String(voltageDB) + "V");
    percentage = (((voltage / 2700.0) * 13.1) / 13.1) * 100.0;
    Serial.println("Percentage = " + String(percentage, 2) + "%");
    Serial.println("===============");
    delay(500);
    updateVoltage(voltageDB);
    }
  }


  if (millis() - getStatusMillis > getStatusDelay || getStatusMillis == 0)
  {
    getStatusMillis = millis();
    getNodeStatus();
    Serial.println("LED Status: " + String(LEDStatus));
    if (LEDStatus == false)
    {
      dma_display->setCursor(0, 16);
      dma_display->setFont(&kongtext4pt7b);
      dma_display->setTextSize(2);
      dma_display->setTextColor(myRED);
      dma_display->fillRect(1, 1, 62, 30, myBLACK);
      dma_display->printf("OFF");
      dma_display->setFont();
    }
  }
  if (LEDStatus == true)
  {
    if (millis() - errorCheckMillis > errorCheckDelay)
    {
      errorCheckMillis = millis();
      getError();
    }
    if (millis() - timeMillis > timeDelay)
    {

      timeMillis = millis();
      getTime();
      getNodeSensorTime();
      String nodeSensorTimeH = nodeSensorTime.substring(0, 2);
      String nodeSensorTimeM = nodeSensorTime.substring(3, 5);
      String nodeSensorTimeS = nodeSensorTime.substring(6, 8);

      Serial.println("Current Time: " + hour + ":" + minute + ":" + second);
      Serial.println("Node Sensor Time: " + nodeSensorTimeH + ":" + nodeSensorTimeM + ":" + nodeSensorTimeS);
      // minus current time with node sensor time
      int hourMinus = hour.toInt() - nodeSensorTimeH.toInt();
      int minuteMinus = minute.toInt() - nodeSensorTimeM.toInt();
      int secondMinus = second.toInt() - nodeSensorTimeS.toInt();
      // convert minus to positive
      int minuteMinusAbs = abs(minuteMinus);
      Serial.println("Minute Minus: " + String(minuteMinusAbs));
      if (nodeSensorTimeH == hour && minuteMinus < 5)
      {
        matchTime = true;
      }
      else
      {
        matchTime = false;
      }

      if (matchTime == true && waterSensorError == false)
      {
        flagColour = myGREEN;
      }
      else if (matchTime == false && waterSensorError == false)
      {
        flagColour = myYELLOW;
      }
      else if (matchTime == true && waterSensorError == true)
      {
        flagColour = myORANGE;
      }
      else if (matchTime == false && waterSensorError == true)
      {
        flagColour = myRED;
      }
      else
      {
        flagColour = myRED;
      }

      if (distance.toFloat() >= 61)
      {

        dma_display->fillRect(48, 2, 12, 10, myBLACK);
        delay(500);

        if (millis() - warningMillis > warningDelay)
        {
          warningMillis = millis();
          dma_display->setCursor(50, 4);
          dma_display->setFont(&kongtext4pt7b);
          dma_display->setTextSize(1);
          dma_display->setTextColor(myRED);
          dma_display->fillTriangle(48, 11, 59, 11, 53, 2, myYELLOW);
          dma_display->printf("!");
          dma_display->setFont();

          // Add a delay of 5 milliseconds
          delay(2000);

          // Erase the exclamation point symbol
          dma_display->fillRect(48, 2, 12, 10, myBLACK);
        }
      }
      else
      {
        dma_display->fillRect(48, 2, 12, 10, myBLACK);
      }
      if (millis() - loopMillis > loopDelay)
      {
        loopMillis = millis();
        getRTDB();
        if (distance.toFloat() <= 10)
        {
          distanceColour = myGREEN;
        }
        else if (distance.toFloat() <= 20)
        {
          distanceColour = myYELLOW;
        }
        else if (distance.toFloat() <= 40)
        {
          distanceColour = myORANGE;
        }
        else if (distance.toFloat() <= 60)
        {
          distanceColour = myRED;
        }
        else if (distance.toFloat() >= 61)
        {
          distanceColour = myRED;
        }
        dma_display->drawLine(0, 0, 63, 0, distanceColour);
        dma_display->drawLine(0, 0, 0, 31, distanceColour);
        dma_display->drawLine(63, 0, 63, 31, distanceColour);
        dma_display->drawLine(0, 31, 63, 31, distanceColour);
        if (distance.toFloat() < 10)
        {
          dma_display->setCursor(10, 16);
          dma_display->setFont(&kongtext4pt7b);
          dma_display->setTextSize(3);
          dma_display->setTextColor(distanceColour);
          dma_display->fillRect(1, 7, 50, 18, myBLACK);
          dma_display->printf(distance.c_str());
          dma_display->setFont();
        }
        else
        {
          dma_display->setCursor(0, 16);
          dma_display->setFont(&kongtext4pt7b);
          dma_display->setTextSize(3);
          dma_display->setTextColor(distanceColour);
          dma_display->fillRect(1, 7, 50, 18, myBLACK);
          dma_display->printf(distance.c_str());
          dma_display->setFont();
        }
        dma_display->setCursor(47, 21);
        dma_display->setFont(&kongtext4pt7b);
        dma_display->setTextSize(1);
        dma_display->setTextColor(myWHITE);
        dma_display->printf("cm");
        dma_display->setFont();
        dma_display->fillCircle(54, 17, 1, flagColour);
      }

      if (errorCount > 20)
      {
        ESP.restart();
      }
    }
  }
}