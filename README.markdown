The OpenSprints messaging protocol and RaceMonitor (Arduino) firmware described here is termed `basic-message-arduino` in the OpenSprints software. The versioning of the firmware releases is based on the supported protocol version--the release number of the firmware is prefixed by the protocol version.

# Protocol description

## Commands to RaceMonitor
### General message format
All messages going in either direction on the serial port are **ASCII strings** that end with the *carriage return-newline* character sequence `\r\n`. Syntax is case-sensitive.

#### Commands
Commands are the messages going from the PC to the RaceMonitor (aka, Arduino). Commands begin with the character `!`. The next string of characters after `!` represents the command. Some commands require a payload, which is a string of alphanumeric characters. To attach the required payload, append a colon `:` character after the command header. follow the `:` with the payload.

#### Responses
The RaceMonitor's response to a command can be a reply message and/or an action, depending on the received command.

The reply message will be queued and sent after any concurrent message has been sent. As a result, the reply message will not break up any other message string. (The race progress update messages are multiline messages; thus, reply messages to commands will be sent between the blocks of lines that form each race progress update message.)

If the command message is malformed, the reply message is:
    NACK

### Heartbeat / handshake
#### Heartbeat command
A *heartbeat command* acts as a request for alive-status confirmation from the RaceMonitor. The format is:
    !a:NNN
where the key `NNN` is a non-negative integer less than or equal to 65535. The PC app is free to select keys randomly or sequentially. The width of the number is not fixed to three digits.  

#### Heartbeat response
##### Reply
The RaceMonitor replies to a *heartbeat command* with a message in following format:
    A:NNN
where `NNN` represents the key received in the most recently received well-formed *heartbeat command*.  
  
If `NNN` is a malformed string that does not contain only numeral characters representing a value in the appropriate range, the reply message is as follows:
    NACK

##### Action
The RaceMonitor does not change state or take any further actions besides sending a reply message. This holds for each state.

#### Example command and reply messages
**Example 1**
    !a:12345
The reply to the *heartbeat command* example above is:
    A:12345
  
**Example 2**
    !a:12A45
The reply to the *heartbeat command* example above is:
    NACK

#### Heartbeat state-wise response matrix
The received key in these example responses is `12345`.  

<table>
<tr><th>RaceMonitor state</th>  <th>Reply from RaceMonitor</th>  <th>Action triggered</th></tr>
<tr><td>Idle</td>               <td><pre>A:12345</pre></td>      <td>No state change and no other actions.</td></tr>
<tr><td>Countdown</td>          <td><pre>A:12345</pre></td>      <td>No state change and no other actions.</td></tr>
<tr><td>Racing</td>             <td><pre>A:12345</pre></td>      <td>No state change and no other actions.</td></tr>
</table>

### Set the number of countdown seconds
#### Set countdown seconds command
The format is:
    !c:NNN
where the key `NNN` is a non-negative integer less than or equal to 255, representing the number of seconds of countdown that precede the beginning of the race. The number is not fixed to three digits. This command is only valid in idle state.

#### Set countdown seconds response
##### Reply
The RaceMonitor replies to a well-formed *set countdown seconds command* with a message in following format:
    C:NNN
where `NNN` represents the key value received.  
  
If the received key is invalid, the reply message is
    C:NACK
and no other action is taken.
  
If the *set countdown seconds command* is received while in countdown or racing state, the reply message is
    C:ERROR
and no other action is taken.

##### Action
Stores the number of countdown seconds. The number of countdown seconds is fixed until the Arduino power is cycled or the value is changed by another *set countdown seconds command*.

#### Example command and reply messages
    !c:10
The reply to the *set countdown seconds command* example above is:
    C:10

### Set race ticks
#### Set race ticks command
The format is:
    !l:NNN
where the key `NNN` is a non-negative integer less than or equal to 65535, representing the number of ticks to the finish of a distance race. This command is only valid in idle state.

#### Set race ticks response
##### Reply
The RaceMonitor replies to a well-formed *set race ticks command* with a message in following format:
    L:NNN
where `NNN` represents the key value received.  
  
If the received key is invalid, the reply message is
    L:NACK
and no other action is taken.
  
If the *set race ticks command* is received while in countdown or racing state, the reply message is
    L:ERROR
and no other action is taken.

##### Action
Stores the number of race ticks. The number of race ticks is fixed until the Arduino power is cycled or the value is changed by another *set race ticks command*.

#### Example command and reply messages
    !l:1000
The reply to the *set race ticks command* example above is:
    L:1000

### Set race seconds (NOT YET IMPLEMENTED)
Set the number of seconds in a fixed time duration race. *This needs to be implemented to store a 32-bit value.*

#### Example command and reply messages
A 20 minute race:
    !t:72000
The reply to the *set race seconds command* example above is:
    T:72000

### Get firmware release
#### Get firmware release command
The format is:
    !v

#### Get firmware release response
Replies with a message of the form
    V:ZZZ
Where `ZZZ` is a string representing the firmware release version.
This command is valid in every state.

#### Example command and reply messages
    !v
The reply to the example above is something like:
    V:2.0.00

### Get protocol version
#### Get protocol version command
The format is:
    !p
This command is valid in every state.

#### Get protocol version response
Replies with the message
    P:2.0

### Get hardware version (NOT YET IMPLEMENTED CORRECTLY)
*This feature requires persistent storage and the implementation of a corresponding "Set Hardware Version" command, since the firmware cannot know which hardware system it has been installed in.*

#### Get hardware version command
The format is:
    !hw
This command will be valid in every state.

#### Get hardware version response
Currently replies with the message
    HW:3

### Start the countdown
Command message:
    !g
The expected response from the Arduino is an immediate reply with the line
    G
This command is invalid during countdown and during an ongoing race. In those situations this command will cause the reply
    G:ERROR

### Stop a race during racing or countdown states
Command message:
    !s
The expected response from the Arduino is an immediate reply with the line
    S
This command is only valid during countdown and during an ongoing race. In idle state, this command will cause the reply
    S:ERROR

### Toggle mock mode
In mock mode, the fake ticks are generated and outputted in the progress messages during a race.
  
Command message:
    !m
The expected response from the Arduino is an immediate reply with the line
    M:ON
If mock mode was off is toggled on.  
or
    M:OFF
If mock mode was is toggled off.  
  
This command is only valid during an ongoing race. In racing and countdown states, this command will cause the response
    M:ERROR

### Reinitialize settings
Reinitialize race parameters countown, time, length, mock to the default values. See below for the default parameter values.
  
Command message:
    !defaults
The expected response from the RaceMonitor is an immediate reply with the line
    DEFAULTS
  
This command is only valid during idle state. If this command is issued during racing or countdown states, this command will cause the response
    DEFAULTS:ERROR

### Set enabled rollers bitflags (NOT YET IMPLEMENTED)
Command message format:
    !i:F
where `F` is decimal integer representing a bitfield. bit 0 is sensor 0, etc.  
  
The expected response from the RaceMonitor is an immediate reply with the line
    I:F
  
E.g. only sensors 0 and 3 are active: `F` = 9.
  
`F` must be 8 bits long or less -- **Verify!!!**
  
`F` is greater than 0, and `F` is less than or equal to 0xFFFFFFFF
  
## Race progress update messages
### Countdown seconds remaining
The message format is
    CD:X
where `X` is the number of the seconds in the countdown remaining until the start of the race.

### False-starts
The message format is
    F:X
where `X` is the number of the sensor that detected a false start. Values begin with zero. E.g. if the first racer on the first bike jumps the gun, the message will be:
    F:0

### Reaction times
The message format is
    RT:X:TTTTT
where `X` is the number of the sensor of the racer whose reaction time is being reported. Sensor values begin with zero. `TTTTT` is the number of milliseconds transpired from the start of the race until racer `X` completed started pedaling.  
  
E.g. If the first racer on the first bike had a 14 ms reaction time, the message would be:
    RT:0:14

### Distance progress, timestamp
The message format is
    0: A
    1: B
    2: C
    3: D
    t: NNNNN
where `A`, `B`, `C`, and `D` are the number of ticks seen by the first, second, third and fourth sensors, respecitively since the start of the race. `NNNNN` represents the number of milliseconds transpired since the start of the race.

### Finish times
The message format is
    Xf:TTTTT
where `X` is the number of the sensor of the racer who finished. Values begin with zero. `TTTTT` is the number of milliseconds transpired from the start of the race until racer `X` completed the race.  
  
E.g. if the first racer on the first bike finishes, the message will be:
    0F:14058

# Distance race or time trial race
Either the race distance must be set to 0 or the race ticks must be set to 0. Both cannot be zero, and both cannot be nonzero.

# Default settings:
* countdown seconds: 5
* race length ticks: 500
* race duration time: 0 (Not Yet Implemented)
* mock mode: off

# Protocol Changes
## Version 2.0

* Commands from the PC to the RaceMonitor (Arduino) now start with a bang (`!`) and end with carriage-return and newline tokens. Several commands now require a payload string preceded by a colon character (`:`).
    + The payload for the command that sets the race length is now an integer number represented by a string of typeable characters instead of two binary words.
* The RaceMonitor now replies back with messages.
* Newly supported commands and functionality:
    + Heartbeat
    + Enable rollers
    + Number of countdown seconds
    + False-start detection
    + Reaction times
* TODO:
    + Set race progress update interval in milliseconds
    + Allow writing the hardware version to persistent storage.
    + Allow time trials as alternative to distance races.

## Original Version
The original Arduino protocol was supported by the Arduino firmware releases prior to Release 2.0. The syntax and behavior is much different than that of subsequent releases.

# Firmware Changes
## Release 2.0.01
* Fixes Red Light Green Light Bugs

## Release 2.0.00
* Supports Protocol Version 2.0.

## Original Release
The original Arduino firmware was delivered in the debian packages before OpenSprints Software Release X. The firmware supported the Original Protocol Version.

