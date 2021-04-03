/**
 * BMP280-MQTT.js
 *
 * By: Mike Klepper
 * Date: 24 November 2017
 *
 * This program demonstrates how to publish to MQTT
 *
 * See blog post on patriot-geek.blogspot.com
 * for instructions.
 */


#include <ArduinoJson.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BMP280.h>
// ADS 1115
#include <Adafruit_ADS1015.h>
  
  Adafruit_ADS1115 ads(0x48);  /* Use this for the 16-bit version */
  //Adafruit_ADS1015 ads;     /* Use thi for the 12-bit version */
  
// Smoothing
const int numReadings = 10;

float readings[numReadings];      // the readings from the analog input
float readings2[numReadings];
int readIndex = 0;              // the index of the current reading
float total = 0;                  // the running total
float average = 0;                // the average
float total2 = 0;
float average2 = 0;

WiFiClient espClient;
PubSubClient client(espClient);
Adafruit_BMP280 bmp;

const char* SSID                  = "inibukanwifi";
const char* PASSWORD              = "ayamgeprek";

const char* MQTT_BROKER           = "153.92.5.13";
const int   MQTT_PORT             = 1883;
const char* MQTT_TOPIC            = "home/BMP";
const char* MQTT_CLIENT_NAME      = "ESP32Client";
//const char* mqttUser = "tkusjali";
//const char* mqttPassword = "Hy4-C0PUEzkg";

const int   BMP280_DELAY          = 1000;
const int   RECHECK_INTERVAL      = 500;
const int   PUBLISH_INTERVAL      = 1000;

long        lastReconnectAttempt  = 0;
long        lastPublishAttempt    = 0;


void setup() 
{
  Serial.begin(115200);
  delay(10);

  setupWifi();
  setupBMP280();
  setupMQTT();

// ADS1115

  Serial.println("Getting single-ended readings from AIN0..3");
  //Serial.println("ADC Range: +/- 6.144V (1 bit = 3mV/ADS1015, 0.1875mV/ADS1115)");
  
  // The ADC input range (or gain) can be changed via the following
  // functions, but be careful never to exceed VDD +0.3V max, or to
  // exceed the upper and lower limits if you adjust the input range!
  // Setting these values incorrectly may destroy your ADC!
  //                                                                ADS1015  ADS1115
  //                                                                -------  -------
  // ads.setGain(GAIN_TWOTHIRDS);  // 2/3x gain +/- 6.144V  1 bit = 3mV      0.1875mV (default)
  //ads.setGain(GAIN_ONE);        // 1x gain   +/- 4.096V  1 bit = 2mV      0.125mV
  // ads.setGain(GAIN_TWO);        // 2x gain   +/- 2.048V  1 bit = 1mV      0.0625mV
  // ads.setGain(GAIN_FOUR);       // 4x gain   +/- 1.024V  1 bit = 0.5mV    0.03125mV
  // ads.setGain(GAIN_EIGHT);      // 8x gain   +/- 0.512V  1 bit = 0.25mV   0.015625mV
  ads.setGain(GAIN_SIXTEEN);    // 16x gain  +/- 0.256V  1 bit = 0.125mV  0.0078125mV
  
  ads.begin();

     for (int thisReading = 0; thisReading < numReadings; thisReading++) {
    readings[thisReading] = 0;
  }

  
}

void loop() 
{
  long now = millis();
  
  if(!client.connected()) 
  {
    if(now - lastReconnectAttempt > RECHECK_INTERVAL) 
    {
      lastReconnectAttempt = now;
      client.connect("ESP32Client"); //, mqttUser, mqttPassword

      if(client.connected())
      {
        // Resubscribe to any topics, if necessary
        // This is also a good place to publish an error to a separate topic!
      }
    }
  }
  else
  {
    if(now - lastPublishAttempt > PUBLISH_INTERVAL)
    {
      lastPublishAttempt = now;
      readAndPublishData();
      client.loop();
    }
  }
}


void setupWifi()
{
  Serial.println("");
  Serial.print("Connecting to ");
  Serial.print(SSID);

  WiFi.begin(SSID, PASSWORD);

  while(WiFi.status() != WL_CONNECTED) 
  {
    delay(RECHECK_INTERVAL);
    Serial.print(".");
    yield();
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void setupBMP280()
{
  Serial.println("");
  Serial.print("Setting up BMP280");

//  while(!bmp.begin(0x76))
//  {
//    delay(RECHECK_INTERVAL);
//    Serial.print(".");
//    yield();
//  }
  
  Serial.println("");
  Serial.println("BMP280 found!");
  delay(BMP280_DELAY);
}

void setupMQTT()
{
  client.setServer(MQTT_BROKER, MQTT_PORT);
  
  Serial.println("");
  Serial.print("Connecting to MQTT");
  
  while(!client.connected())
  {
    Serial.print(".");
    client.connect("ESP32Client"); //, mqttUser, mqttPassword
    delay(RECHECK_INTERVAL);
  }
  
  Serial.println("");
  Serial.println("Connected!");
  Serial.println("");
}

void readAndPublishData()
{
  if(client.connected())
  {
    // ADS1115  
    int16_t  results, adc2;
    float adc3,result_arus;
    float multiplier = 0.0078125F; /* ADS1115  @ +/- 6.144V gain (16-bit results) */
  
    results = ads.readADC_Differential_0_1(); 
    result_arus = results*50/75;
    adc2 = ads.readADC_SingleEnded(2);
    adc3 = ads.readADC_SingleEnded(3);
  
    float fadc01, fadc2;
  
    fadc01 = (result_arus*multiplier)+((0.0274*(result_arus*multiplier))-0.0136);
    fadc2 = ((adc2*0.0078125)+((0.0142*(adc2*0.0078125))+0.59))*((1000+3.2)/3.2/1000);


  total = total - readings[readIndex];
  // read from the sensor:
  readings[readIndex] = fadc2;
  // add the reading to the total:
  total = total + readings[readIndex];

  total2 = total2 - readings2[readIndex];
  // read from the sensor:
  readings2[readIndex] = fadc01;
  // add the reading to the total:
  total2 = total2 + readings2[readIndex];
  // advance to the next position in the array:
  readIndex = readIndex + 1;

  // if we're at the end of the array...
  if (readIndex >= numReadings) {
    // ...wrap around to the beginning:
    readIndex = 0;
  }

  // calculate the average:
  average = total / numReadings;
  // send it to the computer as ASCII digits
  Serial.print("AIN0: "); Serial.println(fadc2);
  Serial.print("average tegangan = ");
  Serial.println(average);

  average2 = total2/numReadings;
  Serial.print("AIN12: "); Serial.println(fadc01);
  Serial.print("average arus = ");
  Serial.println(average2);

  

    //BMP
    float tempC = bmp.readTemperature();
    float tempF = 9.0/5.0 * tempC + 32.0;
    float altit = bmp.readAltitude();
    float pressurePascals = bmp.readPressure();
    float pressureInchesOfMercury = 0.000295299830714 * pressurePascals;
  
    /*String msg = String(tempF) + "  , " + String(altitude) + " , " + String(pressureInchesOfMercury)+ " , " + String(fadc0) + " , " + String(fadc1)+ " , " + String(fadc2)+ " ,  " + String(fadc3) ;
    char msgAsCharAway[msg.length()];
    msg.toCharArray(msgAsCharAway, msg.length());
  
    Serial.print(msg);
    client.publish(MQTT_TOPIC, msgAsCharAway);
    Serial.println(" - sent");*/

  Serial.println("—————");

  StaticJsonDocument<500> doc;                                    //Memory pool

//  doc["E-clevae"] = "Temperature";
//  doc["tempC"] = tempC;
  doc["altitude"] = altit;
//  doc["Pressure"] = pressurePascals;
  doc["tegangan"] = fadc2;
  doc["arus"] = fadc01;
  doc["latitide"] = average;
  doc["longitude"] = average2;
//  doc["distance"] = distance;
 
  Serial.println("\nPretty JSON message: ");
  serializeJsonPretty(doc, Serial);
  Serial.println();

  char buffer[512];
  serializeJson(doc, buffer);
  client.publish(MQTT_TOPIC, buffer);
  }
}
