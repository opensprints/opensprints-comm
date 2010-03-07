#define MAX_LINE 20
char line[MAX_LINE + 1];

enum TX_MSG
{
  TX_MSG_F,
  TX_MSG_A,
  TX_MSG_C,
  TX_MSG_CD,
  TX_MSG_G,
  TX_MSG_I,
  TX_MSG_L,
  TX_MSG_M,
  TX_MSG_S,
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
  TX_MSG_T,
  TX_MSG_NACK,
};

enum RX_MSG
{
  RX_MSG_A,
  RX_MSG_C,
  RX_MSG_G,
  RX_MSG_I,
  RX_MSG_L,
  RX_MSG_M,
  RX_MSG_S,
  RX_MSG_P,
  RX_MSG_V,
};

struct COMMAND_MSG
{
  RX_MSG type;
  char value[MAX_LINE - 3];
};
COMMAND_MSG receivedMsg;

enum STATE
{
  STATE_IDLE,
  STATE_COUNTDOWN,
  STATE_RACING,
};

STATE currentState=STATE_IDLE;

//---------------------------

void blinkLED()
{
}

//---------------------------

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
          line[line_idx++] = c;
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

boolean newMsgAvailable()
{
  if(lineAvailable(MAX_LINE,line))
  {
    Serial.print(line);       // echo back the line we just read
    Serial.print("\r\n");
    return true;
  }
  else
  {
    return false;
  }
}

//---------------------------

void doStateIdle()
{
  if(newMsgAvailable())
  {
  }
  else
  {
  }
}

void doStateCountdown()
{
  if(newMsgAvailable())
  {
  }
  else
  {
  }
}

void doStateRacing()
{
  if(newMsgAvailable())
  {
  }
  else
  {
  }
}

void setup()
{
  Serial.begin(115200); 
}

void loop()
{
  blinkLED();
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
  }
}
