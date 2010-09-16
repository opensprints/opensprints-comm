// TODO:
// * deal with MAX_LINE_CHARS better.
// * use more pointers to char instead of arrays of chars.
// * add a command to request final results of last race.
// * add a command to request an update of race progress.
// * add a command to set frequency of race progress updates.

const char str_comm_protocol[] = "1.02";    // Some features are not yet completed
const char str_fw_version[] = "1.02";
const char str_hw_version[] = "3";          // Arduino with ATMega328p

#define PIN_STATUS_LED 13

#define NUM_SENSORS 4
const int racerGoLedPins[NUM_SENSORS] = {9,10,11,12};     // Arduino digital IOs
const int sensorPinsArduino[NUM_SENSORS] = {2,3,4,5};     // Arduino digital IOs
const int sensorPortDPinsAvr[NUM_SENSORS] = {2,3,4,5};    // Arduino digital IOs

int previousSensorValues;
int currentSensorValues;

unsigned long racerTicks[NUM_SENSORS] = {0,0,0,0};
unsigned long racerFinishTimeMillis[NUM_SENSORS] = {0,0,0,0};

unsigned int racerFinishedFlags = 0;
#define ALL_RACERS_FINISHED_MASK  0x0F // binary 00001111

// False start triggers on the second tick detected during countdown.
#define FALSE_START_TICKS   2
unsigned int countdownSecsRemaining;
unsigned long lastCountDownMillis;
int falseStartFlags; // Bit-wise representation: if bit is set, false start was
                     // detected.

unsigned long raceStartMillis;
unsigned long raceMillis;
unsigned int updateInterval = 250;   // milliseconds

// User-customizable settings exposed by the API
unsigned char countdownSecs;
unsigned int raceLengthTicks;
unsigned int raceDurationSecs;
boolean inMockMode;

//----- Communications ------
#define MAX_LINE_CHARS      31
#define MAX_COMMAND_CHARS   10
#define MAX_PAYLOAD_CHARS   (MAX_LINE_CHARS - MAX_COMMAND_CHARS)

char line[MAX_LINE_CHARS + 1];

#define CHAR_MSG_INITIAL        '!'
#define CHAR_PAYLOAD_SEPARATOR  ':'

struct COMMAND_MSG
{
  int command;
  boolean hasPayload;
  char *payloadStr;
} receivedMsg;

enum
{
  RX_MSG_A,     // Handshake
  RX_MSG_C,     // Countdown seconds
  RX_MSG_DEFAULTS,     // reinitialize: idle state with default values loaded
  RX_MSG_G,     // Start race countdown, then race.
  RX_MSG_HW,    // request hw type and version
  RX_MSG_I,     // Flags for which sensors are active, 0 thru 31. (NOT YET IMPLEMENTED)
  RX_MSG_L,     // Number of ticks in a distance race
  RX_MSG_M,     // Toggle "mock mode" (fake race outputs)
  RX_MSG_S,     // Kill ongoing race
  RX_MSG_T,     // Number of seconds in a fixed-time race (NOT YET IMPLEMENTED)
  RX_MSG_P,     // Request protocol version
  RX_MSG_V,     // Request firmware version
  NUM_RX_COMMANDS,
};

char * rxMsgList[NUM_RX_COMMANDS]=
{
  "a",  // RX_MSG_A,
  "c",  // RX_MSG_C,
  "defaults",  // RX_MSG_DEFAULTS,
  "g",  // RX_MSG_G,
  "hw", // RX_MSG_HW,
  "i",  // RX_MSG_I,
  "l",  // RX_MSG_L,
  "m",  // RX_MSG_M,
  "s",  // RX_MSG_S,
  "t",  // RX_MSG_T,
  "p",  // RX_MSG_P,
  "v",  // RX_MSG_V,
};

boolean rxMsgExpectsPayload[NUM_RX_COMMANDS]=
{
  true,     // RX_MSG_A,
  true,     // RX_MSG_C,
  false,    // RX_MSG_DEFAULTS,
  false,    // RX_MSG_G,
  false,    // RX_MSG_HW,
  true,     // RX_MSG_I,
  true,     // RX_MSG_L,
  false,    // RX_MSG_M,
  false,    // RX_MSG_S,
  true,     // RX_MSG_T,
  false,    // RX_MSG_P,
  false,    // RX_MSG_V,
};

// Indexing corresponds to Rx counterparts for messages
// A through V.
enum
{
  TX_MSG_A,
  TX_MSG_C,
  TX_MSG_DEFAULTS,
  TX_MSG_G,
  TX_MSG_HW,
  TX_MSG_I,             // (NOT YET IMPLEMENTED)
  TX_MSG_L,
  TX_MSG_M,
  TX_MSG_S,
  TX_MSG_T,
  TX_MSG_P,
  TX_MSG_V,
  TX_MSG_0,
  TX_MSG_1,
  TX_MSG_2,
  TX_MSG_3,
  TX_MSG_0F,
  TX_MSG_1F,
  TX_MSG_2F,
  TX_MSG_3F,
  TX_MSG_TIMESTAMP,     // (NOT YET IMPLEMENTED)
  TX_MSG_F,             // (NOT YET IMPLEMENTED)
  TX_MSG_CD,
  TX_MSG_NACK,
  TX_MSG_ERROR,
  NUM_TX_MSGS,
};

char * txMsgList[NUM_TX_MSGS]=
{
  "A",
  "C",
  "DEFAULTS",
  "G",
  "HW",
  "I",
  "L",
  "M",
  "S",
  "T",
  "P",
  "V",
  "0",
  "1",
  "2",
  "3",
  "0f",
  "1f",
  "2f",
  "3f",
  "t",
  "F",
  "CD",
  "NACK",
  "ERROR",
};

enum STATE
{
  STATE_IDLE,
  STATE_COUNTDOWN,
  STATE_RACING,
  NUM_STATES,
} currentState;

//---------------------------
// Serial Rx functions

boolean lineAvailable(int max_line,char *line)
{
  int c;
  static int line_idx = 0;
  static boolean eol = false;
  if (max_line <= 0)    // handle bad values for max_line
  {
    eol = true;
    if (max_line == 0)
      line[0] = '\0';
  }
  else                // valid max_line
  {
    if (Serial.available() > 0)
    {
      c = Serial.read();
      if (c != -1)  // got a char -- should always be true
      {
        if (c == '\r' || c == '\n')
          eol = true;
        else
        {
        //Serial.print(c,BYTE);
          line[line_idx++] = c;
        }
        if (line_idx >= max_line)
          eol = true;
        line[line_idx] = '\0';     // always terminate line, even if unfinished
      }
      if (eol)
      {
        line_idx = 0;           // reset for next line
        eol = false;               // get ready for another line
        return true;
      }
      else
        return false;
    }
  }
}

boolean isAlphaNum(char c)
{
  if(c >= '0' && c <= '9')
  {
    return true;
  }
  if(c >= 'a' && c <= 'z')
  {
    return true;
  }
  if(c >= 'A' && c <= 'Z')
  {
    return true;
  }
  return false;
}

// Check whether received message and payload are both valid.
// Also, send TX responses when messages are in valid.
boolean isReceivedMsgValid(struct COMMAND_MSG testReceivedMsg)
{
  unsigned long int x;

  if(testReceivedMsg.hasPayload)
  {
    // testReceivedMsg has payload, but isn't supposed to.
    if(!rxMsgExpectsPayload[testReceivedMsg.command])
    {
      //Serial.println("testReceivedMsg has payload, but isn't supposed to.");
      Serial.println(txMsgList[TX_MSG_NACK]);
      return(false);
    }
    else
    {
      // testReceivedMsg has payload and is supposed to.
      // check whether the payload value is correct.
      x = atol(testReceivedMsg.payloadStr);
      //Serial.print("\r\n payload integer = ");
      //Serial.println(x,DEC);
      //Serial.println(x,HEX);
      switch(testReceivedMsg.command)
      {
        case RX_MSG_A:
          if(x >= 0 && x <= 65535)
          {
            return(true);
          }
          else
          {
            // Matching Rx and Tx commands have the same index
            Serial.print(txMsgList[testReceivedMsg.command]);
            Serial.print(":");
            Serial.println(txMsgList[TX_MSG_NACK]);
            return(false);
          }
          break;

        case RX_MSG_C:
          if(x >= 0 && x <= 255)
          {
            return(true);
          }
          else
          {
            // Matching Rx and Tx commands have the same index
            Serial.print(txMsgList[testReceivedMsg.command]);
            Serial.print(":");
            Serial.println(txMsgList[TX_MSG_NACK]);
            return(false);
          }
          break;
          
        case RX_MSG_I:
          // greater than zero and 32 bits or less.
          if(x > 0 && x <= 0xFFFFFFFF)
          {
            return(true);
          }
          else
          {
            // Matching Rx and Tx commands have the same index
            Serial.print(txMsgList[testReceivedMsg.command]);
            Serial.print(":");
            Serial.println(txMsgList[TX_MSG_NACK]);
            return(false);
          }
          break;
          
        case RX_MSG_L:
          if(x >= 0 && x <= 65535)
          {
            return(true);
          }
          else
          {
            // Matching Rx and Tx commands have the same index
            Serial.print(txMsgList[testReceivedMsg.command]);
            Serial.print(":");
            Serial.println(txMsgList[TX_MSG_NACK]);
            return(false);
          }
          break;
          
        case RX_MSG_T:
          if(x >= 0 && x <= 65535)
          {
            return(true);
          }
          else
          {
            // Matching Rx and Tx commands have the same index
            Serial.print(txMsgList[testReceivedMsg.command]);
            Serial.print(":");
            Serial.println(txMsgList[TX_MSG_NACK]);
            return(false);
          }
          break;
          
        default:
          Serial.println("FART!!!");
          return(false);
          break;
      }
    }
  }
  else  // (!testReceivedMsg.hasPayload)
  {
    // testReceivedMsg doesn't have payload, but is supposed to.
    if(rxMsgExpectsPayload[testReceivedMsg.command])
    {
      Serial.println(txMsgList[TX_MSG_NACK]);
      return(false);
    }
    else
    {
      // testReceivedMsg doesn't have payload, and isn't supposed to.
      return(true);
    }
  }
}

// Check for a new valid message from the serial port.
// If one exists, update receivedMsg and return true.
// Otherwise, return false.
boolean newMsgReceived()
{
  struct COMMAND_MSG tempReceivedMsg;
  char tempCommandString[MAX_COMMAND_CHARS];
  char tempPayloadString[MAX_PAYLOAD_CHARS];
  unsigned int lineIdx;      // Used to index through string contained in "line".
  unsigned int linePartIdx;  // Used to index through "tempCommandString" and "tempPayloadString" .
  int i;

  if(lineAvailable(MAX_LINE_CHARS,line))
  {
  //Serial.print("\r\nreceived: ");
  //Serial.print(line);       // echo back the line we just read
  //Serial.println();
    if(line[0]!=CHAR_MSG_INITIAL)
    {
      Serial.println(txMsgList[TX_MSG_NACK]);
      return(false);
    }
    else // line[0]==CHAR_MSG_INITIAL
    {
      lineIdx = 0;
      lineIdx++; // 1st char in line is CHAR_MSG_INITIAL
      linePartIdx = 0;
      // Extract the ID of the command in the message.
      while(isAlphaNum(line[lineIdx]))
      {
        if(linePartIdx <= MAX_COMMAND_CHARS) 
        {
          tempCommandString[linePartIdx]=line[lineIdx];
          lineIdx++;
          linePartIdx++;
        }
        else
        {
          Serial.println(txMsgList[TX_MSG_NACK]);
          return(false);
        }
      }
      tempCommandString[linePartIdx]='\0';
      // Check whether tempCommandString is filled with at least one character.
      if(linePartIdx == 0)
      {
        Serial.println(txMsgList[TX_MSG_NACK]);
        return(false);
      }
      // tempCommandString is filled with at least one character
      // so continue processing.
      // Check for a bad character next in the string
      if(!(line[lineIdx] == '\0' || line[lineIdx] == CHAR_PAYLOAD_SEPARATOR))
      {
        Serial.println(txMsgList[TX_MSG_NACK]);
        return(false);
      }
      // Not a bad character, so continue processing.
      i = 0;
      while(i < NUM_RX_COMMANDS)
      {
        if(strcmp(tempCommandString,rxMsgList[i])==0)
        {
        //Serial.println("a match.");
          tempReceivedMsg.command=i;
          // Extract message payload
          if(line[lineIdx]=='\0')
          {
            tempReceivedMsg.hasPayload=false;
            tempReceivedMsg.payloadStr[0]='\0';
            if(isReceivedMsgValid(tempReceivedMsg))
            {
              receivedMsg=tempReceivedMsg;
              return(true);
            }
            else
            {
              return(false);
            }
          }
          else // line[lineIdx]==CHAR_PAYLOAD_SEPARATOR
          {
            tempReceivedMsg.hasPayload=true;
            lineIdx++;
            linePartIdx = 0;
            while(isAlphaNum(line[lineIdx]))
            {
              if(linePartIdx <= MAX_PAYLOAD_CHARS)
              {
                tempPayloadString[linePartIdx]=line[lineIdx];
                lineIdx++;
                linePartIdx++;
              }
              else
              {
              //Serial.println("payload string is too long.");
                Serial.println(txMsgList[TX_MSG_NACK]);
                return(false);
              }
            }
            tempPayloadString[linePartIdx]='\0';
            // first non-alpha-numeric character
            // should be '\0'
            if(!(line[lineIdx]=='\0'))
            {
            //Serial.println("some junk characters in payload string.");
              Serial.println(txMsgList[TX_MSG_NACK]);
              return(false);
            }
            // Payload should have more than zero characters.
            if(linePartIdx == 0)
            {
            //Serial.println("Zero characters in payload string.");
              Serial.println(txMsgList[TX_MSG_NACK]);
              return(false);
            }
            // check the payload
            tempReceivedMsg.payloadStr = tempPayloadString;
            if(isReceivedMsgValid(tempReceivedMsg))
            {
              receivedMsg=tempReceivedMsg;
              return(true);
            }
            else
            {
              return(false);
            }
          }
          break;
        }
        if(++i == NUM_RX_COMMANDS)
        {
          // No message matches. 
          Serial.println(txMsgList[TX_MSG_NACK]);
          return(false);
        }
      }
    }
  }
  // new message not received.
  return(false);
}

//---------------------------
// Serial Tx functions

void txRespondError(struct COMMAND_MSG rxMsg)
{
  char txStr[MAX_LINE_CHARS];
  strcpy(txStr, txMsgList[rxMsg.command]);
  strcat(txStr, ":");
  strcat(txStr, "ERROR");
  Serial.println(txStr);
}
  
void txRespond(struct COMMAND_MSG rxMsg)
{
  char txStr[MAX_LINE_CHARS];
  strcpy(txStr, txMsgList[rxMsg.command]);
  if(rxMsg.hasPayload)
  {
    strcat(txStr, ":");
    strcat(txStr, rxMsg.payloadStr);
  }
  else
  {
    switch(rxMsg.command)
    {
      // These commands have special handlings per state, 
      // so the state handler manages the response.
      case RX_MSG_DEFAULTS:
      case RX_MSG_G:
      case RX_MSG_M:
      case RX_MSG_S:
        break;
        
      case RX_MSG_HW:
        strcat(txStr, ":");
        strcat(txStr, str_hw_version);
        break;
        
      case RX_MSG_P:
        strcat(txStr, ":");
        strcat(txStr, str_comm_protocol);
        break;
        
      case RX_MSG_V:
        strcat(txStr, ":");
        strcat(txStr, str_fw_version);
        break;
        
      default:
        Serial.println("FAAAART!\r\n");
        break;
    }
  }
  Serial.println(txStr);
}

//---------------------------

void switchToState(int newState)
{
  switch(newState)
  {
    case STATE_IDLE:
      // No initializations before beginning idle state
      currentState = STATE_IDLE;
      break;
      
    case STATE_COUNTDOWN:
      // Initializations before beginning countdown state
      for(int i=0; i < NUM_SENSORS; i++)
      {
        racerFinishedFlags = 0;
        racerFinishTimeMillis[i] = 0;
        racerTicks[i] = 0;
      }
      countdownSecsRemaining = countdownSecs;
      lastCountDownMillis = millis();
      falseStartFlags = 0;
      currentState = STATE_COUNTDOWN;
      break;
      
    case STATE_RACING:
      // Initializations before beginning racing state
      raceStartMillis = millis();
      for(int i=0; i < NUM_SENSORS; i++)
      {
        digitalWrite(racerGoLedPins[i],HIGH);
      }
      currentState = STATE_RACING;
      break;
      
    default:
      break;
  }
}

void doStateIdle()
{
  char txStr[MAX_LINE_CHARS];
  if(newMsgReceived())
  {
    switch(receivedMsg.command)
    {
      case RX_MSG_A:
      case RX_MSG_HW:
      case RX_MSG_P:
      case RX_MSG_V:
        txRespond(receivedMsg);
        break;

      case RX_MSG_C:
        txRespond(receivedMsg);
        countdownSecs = atoi(receivedMsg.payloadStr);
        break;

      case RX_MSG_DEFAULTS:
        txRespond(receivedMsg);
        defaultsInit();
        break;

      case RX_MSG_G:
        // Either raceLengthTicks or raceDurationSecs needs to be zero
        // but not both.
        if(raceLengthTicks != raceDurationSecs && (raceLengthTicks == 0 || raceDurationSecs == 0))
        {
          txRespond(receivedMsg);
          switchToState(STATE_COUNTDOWN);
        }
        else
        {
          txRespondError(receivedMsg);
        }
        break;

      case RX_MSG_I:
        // @@@ TO DO: record which racer positions/sensors are active
        //txRespond(receivedMsg);

        // @@@ for now, all 4 fixed inputs are active.
        txRespondError(receivedMsg);
        break;

      case RX_MSG_L:
        txRespond(receivedMsg);
        // Record value for raceLengthTicks
        raceLengthTicks = atol(receivedMsg.payloadStr);
        break;

      case RX_MSG_M:
        // Toggle mock mode.
        strcpy(txStr, txMsgList[receivedMsg.command]);
        strcat(txStr, ":");
        if(!inMockMode)
        {
          strcat(txStr, "ON");
          inMockMode = true;
        }
        else
        {
          strcat(txStr, "OFF");
          inMockMode = false;
        }
        Serial.println(txStr);
        break;

      case RX_MSG_S:
          txRespondError(receivedMsg);
        break;

      case RX_MSG_T:
        txRespond(receivedMsg);
        // record value for raceDurationSecs
        raceDurationSecs = atol(receivedMsg.payloadStr);
        break;

      default:
        Serial.println("WHOOPS!\r\n");
        break;
    }
  }
}

void doStateCountdown()
{
  unsigned long systemTime = millis();
  char txStr0[MAX_LINE_CHARS];
  char txStr1[MAX_LINE_CHARS];
  if(newMsgReceived())
  {
    switch(receivedMsg.command)
    {
      // Respond with error to these. They are not valid in this state.
      case RX_MSG_C:
      case RX_MSG_DEFAULTS:
      case RX_MSG_G:
      case RX_MSG_M:
      case RX_MSG_L:
      case RX_MSG_T:
      case RX_MSG_I:
        txRespondError(receivedMsg);
        break;

      // Respond to handshake or info requests.
      case RX_MSG_A:
      case RX_MSG_HW:
      case RX_MSG_P:
      case RX_MSG_V:
        txRespond(receivedMsg);
        break;

      case RX_MSG_S:
        // Stop the countdown.
        txRespond(receivedMsg);
        switchToState(STATE_IDLE);
        return;
        break;

      default:
        Serial.println("WHOOOPS!\r\n");
        break;
    }
  }
  else
  {
    // Check for a false start.
    for(int i=0; i < NUM_SENSORS; i++)
    {
      if(racerTicks[i] >= FALSE_START_TICKS)
      {
        // Only deal with racers that have not already false-started
        if(!(falseStartFlags & (1<<i)))
        {
          strcpy(txStr0, "F:");
          itoa(i, txStr1, 10);
          strcat(txStr0, txStr1);
          Serial.println(txStr0);
          // activate the false start flag so the message doesn't keep printing
          falseStartFlags |= (1<<i);
        }
      }
    }

    // Check if one second elapsed.
    if((systemTime - lastCountDownMillis) > 1000)
    {
      countdownSecsRemaining--;
      lastCountDownMillis = systemTime;
      // Announce new countdown second.
      strcpy(txStr0, txMsgList[TX_MSG_CD]);
      strcat(txStr0, ":");
      itoa(countdownSecsRemaining, txStr1, 10);
      strcat(txStr0, txStr1);
      Serial.println(txStr0);
    }
    if(countdownSecsRemaining == 0)
    {
      // When countdown hits zero, start race
      switchToState(STATE_RACING);
    }
  }
}

void doStateRacing()
{
  unsigned long systemTime = millis();
  static unsigned long lastUpdateMillis = 0;
  char txStr0[80];
  char txStr1[10];

  // Watch for each racer to reach racelength ticks
    // kill race when all racers arrive at the destination
    // Report final time for each racer upon reaching the destination
    //currentState=STATE_IDLE;

  // @@@ TODO: Or instead, Watch for race timer to expire 
    // kill race when time expires
    // Report final distance for each racer
    //currentState=STATE_IDLE;

  raceMillis = systemTime - raceStartMillis;
  if(raceMillis - lastUpdateMillis > updateInterval)
  // Send race progress messages periodically.
  {
    lastUpdateMillis = raceMillis;
    strcpy(txStr0, "\r\n");
    for(int i=0; i < NUM_SENSORS; i++)
    {

      if(inMockMode)
      {
        racerTicks[i]+=(i+4); // manufacture ticks.
        if(racerTicks[i] >= raceLengthTicks)
        {
          racerFinishTimeMillis[i] = raceMillis;
        }
      }
      itoa(i, txStr1, 10);
      strcat(txStr0, txStr1);
      strcat(txStr0, ": ");
      itoa(racerTicks[i], txStr1, 10);
      strcat(txStr0, txStr1);
      strcat(txStr0, "\r\n");
    }
    strcat(txStr0, "t: ");
    ltoa(raceMillis, txStr1, 10);
    strcat(txStr0, txStr1);
    for(int i=0; i < NUM_SENSORS; i++)
    {
      if(!(racerFinishedFlags & (1<<i)))
      // Finished racer hasn't been announced yet.
      {
        if(racerFinishTimeMillis[i] != 0)
        {
          strcat(txStr0, "\r\n");
          itoa(i, txStr1, 10);
          strcat(txStr0, txStr1);
          strcat(txStr0, "f: ");
          itoa(racerFinishTimeMillis[i], txStr1, 10);
          strcat(txStr0, txStr1);

          digitalWrite(racerGoLedPins[i],LOW);
          racerFinishedFlags |= (1<<i);
        }
      }
    }
    Serial.println(txStr0);
  }
  if(racerFinishedFlags == ALL_RACERS_FINISHED_MASK)
  {
    switchToState(STATE_IDLE);
    return;
  }
  if(newMsgReceived())
  {
    switch(receivedMsg.command)
    {
      // Respond with error to these. They are not valid in this state.
      case RX_MSG_C:
      case RX_MSG_G:
      case RX_MSG_M:
      case RX_MSG_L:
      case RX_MSG_T:
      case RX_MSG_I:
        txRespondError(receivedMsg);
        break;

      // Respond to handshake or info requests.
      case RX_MSG_A:
      case RX_MSG_HW:
      case RX_MSG_P:
      case RX_MSG_V:
        txRespond(receivedMsg);
        break;

      case RX_MSG_S:
        // Stop the race.
        txRespond(receivedMsg);
        switchToState(STATE_IDLE);
        break;

      default:
        Serial.println("WHOOOPS!\r\n");
        break;
    }
  }
}

//---------------------------

void blinkLed()
{
  const unsigned int statusBlinkInterval = 250;     // number of millis
  static int lastStatusLEDValue = HIGH;
  static unsigned long previousStatusBlinkMillis = 0;

  switch(currentState)
  {
    case STATE_IDLE:
      // slow flashing
      if (millis() - previousStatusBlinkMillis > statusBlinkInterval / 4)
      {
        previousStatusBlinkMillis = millis();
        lastStatusLEDValue = !lastStatusLEDValue;
        digitalWrite(PIN_STATUS_LED, lastStatusLEDValue);
      }
      break;

    case STATE_COUNTDOWN:
      // moderate flashing
      if (millis() - previousStatusBlinkMillis > statusBlinkInterval)
      {
        previousStatusBlinkMillis = millis();
        lastStatusLEDValue = !lastStatusLEDValue;
        digitalWrite(PIN_STATUS_LED, lastStatusLEDValue);
      }
      break;

    case STATE_RACING:
      // rapid flashing
      if (millis() - previousStatusBlinkMillis > statusBlinkInterval / 4)
      {
        previousStatusBlinkMillis = millis();
        lastStatusLEDValue = !lastStatusLEDValue;
        digitalWrite(PIN_STATUS_LED, lastStatusLEDValue);
      }
      break;
  }
}

//---------------------------
ISR(PCINT2_vect)
{
  unsigned int newRisingEdges;

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
    if(racerTicks[i] >= raceLengthTicks)
    {
      racerFinishTimeMillis[i] = raceMillis;
    }
  }
}

//---------------------------

void defaultsInit()
{
  countdownSecs = 5;
  raceLengthTicks = 500;
  raceDurationSecs = 0;
  inMockMode = false;
}

void setup()
{
  Serial.begin(115200); 
  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, HIGH);
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

  defaultsInit();

  switchToState(STATE_IDLE);
}

void loop()
{
  blinkLed();
  switch(currentState)
  {
    case STATE_IDLE:
      doStateIdle();
      break;

    case STATE_COUNTDOWN:
      doStateCountdown();
      break;

    case STATE_RACING:
      doStateRacing();
      break;

    default:
      break;
  }
}
