#define MAX_LINE 20
char line[MAX_LINE + 1];
#define MAX_COMMAND_CHARS 3

#define CHAR_MSG_INITIAL '!'
#define CHAR_MSG_SEPARATOR ':'

enum
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
  NUM_RX_MSGS,
};

char * rxMsgList[NUM_RX_MSGS]=
{
  "a",
  "c",
  "g",
  "i",
  "l",
  "m",
  "s",
  "p",
  "v",
};

boolean * rxMsgExpectsPayload[NUM_RX_MSGS]=
{
  true,			//"a",
  true,			//"c",
  false,		//"g",
  true,			//"i",
  true,			//"l",
  false,		//"m",
  false,		//"s",
  false,		//"p",
  false,		//"v",
};

enum
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
  NUM_TX_MSGS,
};

char * txMsgList[NUM_TX_MSGS]=
{
  "F",
  "A",
  "C",
  "CD",
  "G",
  "I",
  "L",
  "M",
  "S",
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
  "NACK",
};

struct COMMAND_MSG
{
  int command;
	boolean hasPayload;
  char value[MAX_LINE - MAX_COMMAND_CHARS];
} receivedMsg;

enum STATE
{
  STATE_IDLE,
  STATE_COUNTDOWN,
  STATE_RACING,
};

STATE currentState=STATE_IDLE;

//---------------------------

void blinkLed()
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
				{
					Serial.print(c,BYTE);
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

bool isAlphaNum(char c)
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

// Returns the ID of the command in the message.
// Returns -1 if the message does not contain a proper command.
int extractMsgCommand(char *line)
{
	int idx = 0;
	char commandString[MAX_LINE + 1];
	boolean endOfCommand = false;

	while(isAlphaNum(line[idx+1]) && line[idx+1]!=CHAR_MSG_SEPARATOR && line[idx+1]!='\0')
	{
		commandString[idx]=line[idx+1];	// 1st char in line is CHAR_MSG_INITIAL 
		Serial.print("\r\nidx = ");
		Serial.println(idx);
		Serial.print("commandString[idx]=");
		Serial.print(commandString[idx],BYTE);
		Serial.print(" = ");
		Serial.println(commandString[idx],DEC);
		idx++;
	}
	commandString[idx]='\0';
	if(idx>0)		// if commandString filled with at least one character
	{
		Serial.print("\r\ncommandString=");
		Serial.println(commandString);
		for(int i=0;i<NUM_RX_MSGS;i++)
		{
			Serial.print("\r\nrxMsgList[i]=");
			Serial.println(rxMsgList[i]);
			if(strcmp(commandString,rxMsgList[i])==0)
			{
				Serial.println("a match.");
				return i;
			}
		}
	}
	Serial.println("not a match.");
	return -1;
}

int extractMsgPayload(char *line)
{
}

boolean newMsgReceived()
{
  if(lineAvailable(MAX_LINE,line))
  {
    Serial.print("\r\nreceived: ");       // echo back the line we just read
    Serial.print(line);       // echo back the line we just read
    Serial.print("\r\n");
		Serial.print("line[0] = ");
		Serial.println(line[0],BYTE);
		if(line[0]==CHAR_MSG_INITIAL)
		{
			return true;
		}
	}
	return false;
}

//---------------------------

void doStateIdle()
{
  if(newMsgReceived())
  {
		receivedMsg.command=extractMsgCommand(line);
		if(receivedMsg.command != -1)
		{
			Serial.print("new message: ");
			Serial.println(rxMsgList[receivedMsg.command]);
		}
		else
		{
			Serial.println("bad message.");
		}
  }
  else
  {
  }
}

void doStateCountdown()
{
  if(newMsgReceived())
  {
  }
  else
  {
  }
}

void doStateRacing()
{
  if(newMsgReceived())
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
