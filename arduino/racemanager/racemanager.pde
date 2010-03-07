/*
 * Arduino wiring:
 * 
 * Arduino pin  ATmega168/328 Pin  Connected to
 * -----------  -----------------  ------------
 * digital 2    PD2                Sensor 0
 * digital 3    PD3                Sensor 1
 * digital 4    PD4                Sensor 2
 * digital 5    PD5                Sensor 3
 * 
 * digital 9    PB1                Racer0 Start LED anode, Stop LED cathode
 * digital 10   PB2                Racer1 Start LED anode, Stop LED cathode
 * digital 11   PB3                Racer2 Start LED anode, Stop LED cathode
 * digital 12   PB4                Racer3 Start LED anode, Stop LED cathode
 * 
 */

#include <avr/interrupt.h>  
#include <avr/io.h>

#define NUM_SENSORS 4
#define MAX_LINELENGTH 20
#define MAX_MSGCHARS 32

int statusLEDPin = 13;
long statusBlinkInterval = 250;
int lastStatusLEDValue = LOW;
long previousStatusBlinkMillis = 0;

struct COMMAND_MSG
{
  char type;
  char value[MAX_MSGCHARS];
};
COMMAND_MSG receivedMsg;

boolean mockMode = false;
unsigned long raceStartMillis;
unsigned long raceMillis;

int racerGoLedPins[NUM_SENSORS] = {9,10,11,12}; // Arduino digital IOs
int sensorPinsArduino[NUM_SENSORS] = {2,3,4,5}; // Arduino digital IOs
int sensorPortDPinsAvr[NUM_SENSORS] = {2,3,4,5};    // Arduino digital IOs
int previousSensorValues;
int currentSensorValues;
unsigned long racerTicks[NUM_SENSORS] = {0,0,0,0};
unsigned long racerFinishTimeMillis[NUM_SENSORS] = {0,0,0,0};

unsigned int racerFinishedFlags = 0;
#define ALL_RACERS_FINISHED_MASK  0x0F // binary 00001111

unsigned long lastCountDownMillis;
int lastCountDown;

int raceLengthTicks = 1000;

int updateInterval = 250;   // milliseconds
unsigned long lastUpdateMillis = 0;

int state;
enum
{
  STATE_IDLE,
  STATE_COUNTDOWN,
  STATE_RACING,
};

ISR(PCINT2_vect)
{
  unsigned int newRisingEdges;

  if(state == STATE_RACING)
  {
    if(!mockMode)
    {
      raceMillis = millis() - raceStartMillis;
      // Register rising edge events
      previousSensorValues = currentSensorValues;
      currentSensorValues = PIND;
      newRisingEdges = (previousSensorValues ^ currentSensorValues) & currentSensorValues;
      for(int i=0; i < NUM_SENSORS; i++)
      {
        if(newRisingEdges & (1<<sensorPortDPinsAvr[i]))
        {
          racerTicks[i]++;
        }
        if(racerTicks[i] == raceLengthTicks)
        {
          racerFinishTimeMillis[i] = raceMillis;
        }
      }
    }
  }
}

void setup()
{
  Serial.begin(115200); 
  pinMode(statusLEDPin, OUTPUT);
  for(int i=0; i < NUM_SENSORS; i++)
  {
    pinMode(racerGoLedPins[i], OUTPUT);
    digitalWrite(racerGoLedPins[i], LOW);
    pinMode(sensorPinsArduino[i], INPUT);
    digitalWrite(sensorPinsArduino[i], HIGH);   // set weak pull-up
  }
  // make digital IO pins 2,3,4,5 pin change interrupts
  PCICR |= (1 << PCIE2);
  PCMSK2 |= (1 << PCINT18);
  PCMSK2 |= (1 << PCINT19);
  PCMSK2 |= (1 << PCINT20);
  PCMSK2 |= (1 << PCINT21);

  state = STATE_IDLE;
}

void blinkLED()
{
  if (millis() - previousStatusBlinkMillis > statusBlinkInterval)
  {
    previousStatusBlinkMillis = millis();
    lastStatusLEDValue = !lastStatusLEDValue;
    digitalWrite(statusLEDPin, lastStatusLEDValue);
  }
}

boolean newCommandMsgEvaluated()
{
  int max_line;
  int commandValueLen;
  char line[32];
  int lineLen;
  int c;
  static int charIdx = 0;
  static boolean eol = false;
  if (max_line <=f(receivedMsg.type == 'a')    // ACK heartbeat
			170   {
			171     if(commandValueLen==3)
			172     {
			173       // received 2-byte symbol. need to return it.
			174 
			175 
			176       sprintf(receivedMsg.value,"NACK");
			177     }
			178   }
			179   else if(receivedMsg.type == 'l')
			180   {
			181     if(isAlphaNumeric(receivedMsg.value) && numChars(receivedMsg.value))
			182     {
			183       raceLengthTicks = string2int(receivedMsg.value) 
			0)    // handle bad values for max_line
  {
    eol = true;
    if (max_line == 0)
      line[0] = '\0';
  }
  else        // valid max_line
  {
    if (Serial.available() > 0)
    {
      c = Serial.read();
      if (c != -1)  // got a char -- should always be true
      {
        if (c == '\r' || c == '\n')
          eol = true;
        else
          line[charIdx++] = c;
        if (charIdx >= max_line)
          eol = true;
        line[charIdx] = '\0';     // always terminate line, even if unfinished
      }
      if (eol)
      {
        lineLen = charIdx;
        charIdx = 0;      // reset for next line
        eol = false;       // get ready for another line
        return true;
      }
      else
        return false;
    }
  }
  // march through full line received and fill receivedMsg with data.
  if(receivedMsg.type == 'a')    // ACK heartbeat
  {
    if(commandValueLen==3)
    {
      // received 2-byte symbol. need to return it.


      sprintf(receivedMsg.value,"NACK");
    }
  }
  else if(receivedMsg.type == 'l')
  {
    if(isAlphaNumeric(receivedMsg.value) && numChars(receivedMsg.value)) 
    {
      raceLengthTicks = string2int(receivedMsg.value);
    }
    else
    {
      sprintf(receivedMsg.value,"ERROR receiving race length ticks");
    }

}   

void checkSerial()
{
  if (newCommandMsgEvaluated())
  {
    // react to received commands.
    if(receivedMsg.type == 'a')    // ACK heartbeat
    {
      Serial.print("a:");
      Serial.print(receivedMsg.value);
    }
    else if(receivedMsg.type == 'l')
    {
        // received all the parts of the distance. time to process the value we received.
        // The maximum for 2 chars would be 65 535 ticks.
        // For a 0.25m circumference roller, that would be 16384 meters = 10.1805456 miles.
        raceLengthTicks = receivedMsg.value;
        Serial.print("l:");
        Serial.println(receivedMsg.value);
      }
      else
      {
        Serial.println("ERROR receiving race length ticks");
      }
    }
    else if(receivedMsg.type == 'v')   // version
    {
      Serial.println("basic-2");
    }
    else if(receivedMsg.type == 'g')
    {
      state = STATE_COUNTDOWN;
      lastCountDown = 4;
      lastCountDownMillis = millis();
    }
    else if(receivedMsg.type == 'm')
    {
      // toggle mock mode
      mockMode = !mockMode;
    }
    else if(receivedMsg.type == 's')
    {
      for(int i=0; i < NUM_SENSORS; i++)
      {
        digitalWrite(racerGoLedPins[i],LOW);
      }
      state = STATE_IDLE;
    }
  }
}

void handleStates()
{
  long systemTime = millis();
  if(state == STATE_COUNTDOWN)
  {
    if((systemTime - lastCountDownMillis) > 1000)
    {
      lastCountDown -= 1;
      lastCountDownMillis = systemTime;
    }
    if(lastCountDown == 0)
    {
      raceStartMillis = systemTime;
      for(int i=0; i < NUM_SENSORS; i++)
      {
        racerFinishedFlags=0;
        racerTicks[i] = 0;
        racerFinishTimeMillis[i] = 0;
        digitalWrite(racerGoLedPins[i],HIGH);
      }
      state = STATE_RACING;
    }
  }
  if (state == STATE_RACING)
  {
    raceMillis = systemTime - raceStartMillis;
    if(raceMillis - lastUpdateMillis > updateInterval)
    // Print status update
    {
      lastUpdateMillis = raceMillis;
      for(int i=0; i < NUM_SENSORS; i++)
      {

        if(mockMode)
        {
          racerTicks[i]+=(i+1); // manufacture ticks.
        }
        Serial.print(i);
        Serial.print(": ");
        Serial.println(racerTicks[i], DEC);
      }
      Serial.print("t: ");
      Serial.println(raceMillis, DEC);
      for(int i=0; i < NUM_SENSORS; i++)
      {

        if(!(racerFinishedFlags & (1<<i)))
        // Finished racer hasn't been announced yet.
        {
          if(racerFinishTimeMillis[i] != 0)
          {
            Serial.print(i);
            Serial.print("f: ");
            Serial.println(racerFinishTimeMillis[i], DEC);
            digitalWrite(racerGoLedPins[i],LOW);
            racerFinishedFlags |= (1<<i);
          }
        }
      }
    }
    if(racerFinishedFlags == ALL_RACERS_FINISHED_MASK)
    {
      state = STATE_IDLE;
    }
  }
}

void loop()
{
  blinkLED();
  checkSerial();
  handleStates();
}

