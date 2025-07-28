#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>

// Definir pinos para 6 Relés
const int RELE_IGNITAR = 12; // Vermelho
const int RELE_AGITAR = 32; // Azul
const int RELE_INCLINAR = 33; // Verde
const int RELE_ALERTAR = 27; // Amarelo
const int RELE_DISPARAR = 26;
const int RELE_ABORTAR = 25;
//const int POT = 15;
const int sensorPressaoPin = 4;

//const float angulomaximo = 42.00;
//bool anguloMaximoAtingido = false; // Variável booleana para identificar se o ângulo máximo foi atingido
//bool tempoDisparo = false;

//float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
//    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;}

unsigned long tempoAnterior = 0;
const long intervalo = 1000;
float sensorVal;
float voltageSensor;  
float pressureValue;
//int contadorDisparo = 0;

BLECharacteristic *characteristicPRESSAO;
BLECharacteristic *characteristicANGULO;
bool deviceConnected = false;

#define SERVICE_UUID   "ab0828b1-198e-4351-b779-901fa0e0371e"
#define CHARACTERISTIC_UUID_RX  "4ac8a682-9736-4e5d-932b-e9b31405049c"
#define CHARACTERISTIC_UUID_PRESSAO  "0972ef8c-7613-4075-ad52-756f33d4da91"
#define CHARACTERISTIC_UUID_ANGULO  "0f1d2df9-f709-4633-bb27-0c52e13f748a"

// Objeto ADXL345
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);

// callback para eventos das características
class CharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *characteristic) {
        String value = characteristic->getValue();
        std::string rxValue = value.c_str();
        if (rxValue.length() > 0) {
            for (int i = 0; i < rxValue.length(); i++) {
                Serial.print(rxValue[i]);
            }
            Serial.println();

            // Controle dos 6 relés
            if (rxValue.find("L11") != -1) {
                digitalWrite(RELE_IGNITAR, LOW);
            } else if (rxValue.find("L10") != -1) {
                digitalWrite(RELE_IGNITAR, HIGH);
            }
            if (rxValue.find("L21") != -1) {
                digitalWrite(RELE_AGITAR, LOW);
            } else if (rxValue.find("L20") != -1) {
                digitalWrite(RELE_AGITAR, HIGH);
            }
            if (rxValue.find("L31") != -1) {
                digitalWrite(RELE_INCLINAR, LOW);
            } else if (rxValue.find("L30") != -1) {
                digitalWrite(RELE_INCLINAR, HIGH);
            }
            if (rxValue.find("L41") != -1) {
                digitalWrite(RELE_ALERTAR, LOW);
            } else if (rxValue.find("L40") != -1) {
                digitalWrite(RELE_ALERTAR, HIGH);
            }
            if (rxValue.find("L51") != -1) {
                digitalWrite(RELE_DISPARAR, LOW);
            } else if (rxValue.find("L50") != -1) {
                digitalWrite(RELE_DISPARAR, HIGH);
            }
//            if (rxValue.find("L51") != -1 && !tempoDisparo) {
 //               digitalWrite(RELE_DISPARAR, LOW);
 //               contadorDisparo = contadorDisparo +1;
 //               if (contadorDisparo >= 2){
 //                 tempoDisparo = true;
 //                 digitalWrite(RELE_DISPARAR, HIGH);
 //               }
 //           }else{
 //             contadorDisparo = 0;
 //           }

            // else if (rxValue.find("L50") != -1) {
               // digitalWrite(RELE_DISPARAR, HIGH);
            //}
            if (rxValue.find("L61") != -1) {
                digitalWrite(RELE_ABORTAR, LOW);
            } else if (rxValue.find("L60") != -1) {
                digitalWrite(RELE_ABORTAR, HIGH);
                digitalWrite(RELE_DISPARAR, HIGH);
                digitalWrite(RELE_ALERTAR, HIGH);
                digitalWrite(RELE_INCLINAR, HIGH);
                digitalWrite(RELE_AGITAR, HIGH);
                digitalWrite(RELE_IGNITAR, HIGH);
            }
        }
    }
};

// callback para receber os eventos de conexão de dispositivos
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        pServer->startAdvertising();
    }
};

void setup() {
    Serial.begin(115200);

    // Inicializar pinos dos relés como saída
    pinMode(RELE_IGNITAR, OUTPUT);
    pinMode(RELE_AGITAR, OUTPUT);
    pinMode(RELE_INCLINAR, OUTPUT);
    pinMode(RELE_ALERTAR, OUTPUT);
    pinMode(RELE_DISPARAR, OUTPUT);
    pinMode(RELE_ABORTAR, OUTPUT);
    //pinMode(POT, INPUT);
    pinMode(sensorPressaoPin, INPUT);
    analogReadResolution(12);

    digitalWrite(RELE_ABORTAR, HIGH);
    digitalWrite(RELE_DISPARAR, HIGH);
    digitalWrite(RELE_ALERTAR, HIGH);
    digitalWrite(RELE_INCLINAR, HIGH);
    digitalWrite(RELE_AGITAR, HIGH);
    digitalWrite(RELE_IGNITAR, HIGH);

    // Create the BLE Device
    BLEDevice::init("MOBFOG-IFRN");

    // Create the BLE Server
    BLEServer *server = BLEDevice::createServer();
    server->setCallbacks(new ServerCallbacks());

    // Create the BLE Service
    BLEService *service = server->createService(SERVICE_UUID);

    // Create a BLE Characteristic para envio de dados
    characteristicPRESSAO = service->createCharacteristic(
                       CHARACTERISTIC_UUID_PRESSAO,
                       BLECharacteristic::PROPERTY_NOTIFY
                     );

    characteristicPRESSAO->addDescriptor(new BLE2902());

    // Create a BLE Characteristic para envio de dados
    characteristicANGULO = service->createCharacteristic(
                       CHARACTERISTIC_UUID_ANGULO,
                       BLECharacteristic::PROPERTY_NOTIFY
                     );

    characteristicANGULO->addDescriptor(new BLE2902());

    // Create a BLE Characteristic para recebimento de dados
    BLECharacteristic *characteristic = service->createCharacteristic(
                                                      CHARACTERISTIC_UUID_RX,
                                                      BLECharacteristic::PROPERTY_WRITE
                                                    );

    characteristic->setCallbacks(new CharacteristicCallbacks());

    // Start the service
    service->start();

    // Start advertising (descoberta do ESP32)
    server->getAdvertising()->start();

    Serial.println("Aguardando algum dispositivo conectar...");

    // Inicialize o ADXL345
    if (!accel.begin()) {
       Serial.println("Não foi possível encontrar um ADXL345. Verifique a conexão!");
        while (1);
    }

    // Defina o intervalo para +/- 16G
    accel.setRange(ADXL345_RANGE_16_G);
}

void loop() {
    if (deviceConnected) {
        unsigned long tempoAtual = millis();
        if (tempoAtual - tempoAnterior >= intervalo) {
            tempoAnterior = tempoAtual;
            
            // Leia os valores do acelerômetro
            sensors_event_t event;
            accel.getEvent(&event);

            // Calcule os ângulos de inclinação em relação aos eixos X, Y e Z
            float angleX = atan(event.acceleration.x / sqrt(pow(event.acceleration.y, 2) + pow(event.acceleration.z, 2))) * 180.0 / PI;
            float angleY = atan(event.acceleration.y / sqrt(pow(event.acceleration.x, 2) + pow(event.acceleration.z, 2))) * 180.0 / PI;
            float angleZ = atan(event.acceleration.z / sqrt(pow(event.acceleration.x, 2) + pow(event.acceleration.y, 2))) * 180.0 / PI;
            //float anguloReal = 3.0 + (15.6 / 48.0) * angleY;
            //float anguloReal = mapFloat(angleY, 3.72, 17.4, 0, 47.00);
            float anguloReal = ((angleY - 3.72) / (17.4 - 3.72)) * 47.0;
            //float anguloReal = 5.921 * (angleY + 2.2);
            //float anguloReal = 3.00 + ((angl6eY - 0) * (17.00 - 3.00)) / (45 - 0);
            //float anguloReal = 3.00 + (angleY * 14.00) / 45.00;
            //float anguloReal = ((angleY - 3.90) * 47.0) / (16.92 - 3.90);
            //float anguloReal = angleY;



            // Calcular pressão em psi
            sensorVal = analogRead(sensorPressaoPin);
            voltageSensor = sensorVal * 3.3 / 4095.0 + 0.09;
            if (voltageSensor <= 0.5) {
                pressureValue = 0; 
            } else {
                pressureValue = (voltageSensor - 0.5) * 75.0;
            }

            // Exibir valores no Serial Monitor
            Serial.print("Angle X: "); Serial.print(angleX); 
            Serial.print("Angle Y: "); Serial.print(angleY); 
            Serial.print("Angle Z: "); Serial.println(angleZ); 
            Serial.print("Angle Real: "); Serial.println(anguloReal); Serial.print("° ");
            //Serial.print("Pressão: "); Serial.println(pressureValue); Serial.print(" ");


            // Verificar se o ângulo máximo foi atingido
            //if (anguloReal >= angulomaximo) {
            //    anguloMaximoAtingido = true;
            //} else {
            //    anguloMaximoAtingido = false;
            //}

            // Construir string para enviar via Bluetooth
            char pressaoString[32];
            snprintf(pressaoString, sizeof(pressaoString), "%.2f", pressureValue);
            
            // Definir valor da característica e notificar cliente
            characteristicPRESSAO->setValue(pressaoString);
            characteristicPRESSAO->notify();

            // Construir string para enviar via Bluetooth
            char anguloString[32];
            snprintf(anguloString, sizeof(anguloString), "%.2f", anguloReal);
       
            // Definir valor da característica e notificar cliente
            characteristicANGULO->setValue(anguloString);
            characteristicANGULO->notify();
        }
    }
}
