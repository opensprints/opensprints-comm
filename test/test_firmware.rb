require 'rubygems'
require 'bacon'
require 'timeout'
include Timeout

# Prime the serial port
# First time opening the device (port / file / tty) after plugging in the 
# Arduino causes it to reboot.
filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
serialport = File.open(filename, "w+")
serialport.close
sleep(1.5)

# First, get Racemonitor back to Idle State from any other state
serialport.write "!s"

stimulus_and_response = [
  ["Test the handshake:",   "!a:0\r\n",     "A:0\r\n"],
  ["Test the handshake:\n", "!a:12345\r\n", "A:12345\r\n"], 
  ["Test the handshake:\n", "!a:65535\r\n", "A:65535\r\n"], 
  ["Test a handshake boundary case\n",  "!a:65536\r\n", "A:NACK\r\n"], 
  ["Test a countdown boundary case:\n", "!c:-1\r\n",    "NACK\r\n"], 
  ["Test a countdown valid case:\n",    "!c:0\r\n",     "C:0\r\n"], 
  ["Test a countdown valid case:\n",    "!c:1\r\n",     "C:1\r\n"], 
  ["Test a countdown valid case:\n",    "!c:127\r\n",   "C:127\r\n"], 
  ["Test a countdown valid case:\n",	"!c:128\r\n",   "C:128\r\n"], 
  ["Test a countdown valid case:\n",    "!c:255\r\n",   "C:255\r\n"], 
  ["Test a countdown boundary case:\n", "!c:256\r\n",   "C:NACK\r\n"], 
  ["Test the Go command while in idle state:\n",    "!g\r\n",   "G\r\n"], 
  ["Test the Go command with a malformed message:\n",   "!g:\r\n",  "NACK\r\n"], 
  ["Test the Go command with a boundary case:\n",       "!g:1098\r\n","NACK\r\n"], 
  ["Test the Go command with a malformed message:\n",   "!g:$!&#\r\n","NACK\r\n"],
  ["Test the hw command with a valid message:\n",   "!hw\r\n","HW:3\r\n"],
  ["Test the racer enable command with a malformed message:\n",   "!i\r\n","NACK\r\n"],
  ["Test the racer enable command with a boundary case:\n",               "!i:0\r\n","I:NACK\r\n"],
  ["Test the racer enable command with a valid message:\n",  "!i:6\r\n","I:6\r\n"],
  ["Test the racer enable command with a valid message:\n",  "!i:4294967295\r\n","I:4294967295\r\n"],
  ["Test the racer enable command with a boundary case:\n",  "!i:4294967296\r\n","I:NACK\r\n"],
  ["Test the race length command with a malformed message:\n",   "!l\r\n","NACK\r\n"],
  ["Test the race length command with a valid message:\n",   "!l:0\r\n","L:0\r\n"],
  ["Test the race length command with a valid message:\n",   "!l:65535\r\n","L:65535\r\n"],
  ["Test the race length command with a boundary case:\n",   "!l:65536\r\n","L:NACK\r\n"],
  ["Test the mock mode command with a valid message:\n",     "!m\r\n","M\r\n"],
  ["Test the mock mode command with a malformed message:\n", "!m:0\r\n","NACK\r\n"],
  ["Test the Stop command while in race state:\n",           "!s\r\n","S\r\n"],
  ["Test the Stop command with a malformed message:\n",      "!s:0\r\n","NACK\r\n"],
  ["Test the timer command with a malformed message:\n",   "!t\r\n","NACK\r\n"],
  ["Test the timer command with a valid message:\n",   "!t:0\r\n","T:0\r\n"],
  ["Test the timer command with a valid message:\n",   "!t:65535\r\n","T:65535\r\n"],
  ["Test the timer command with a boundary case:\n",   "!t:65536\r\n","T:NACK\r\n"],
  ["Test the protocol request command with a valid message:\n",   "!p\r\n","P:1.02\r\n"],
  ["Test the protocol request command with a malformed message:\n",   "!p:023\r\n","NACK\r\n"],
  ["Test the version request command with a valid message:\n",   "!v\r\n","V:1.02\r\n"],
  ["Test the version request command with a malformed message:\n",   "!v:555\r\n","NACK\r\n"]
]


stimulus_and_response.each do |descr,stimulus,expected_response|

	describe descr do
		before do
			filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
			flags = "406:0:18b2:8a30:3:1c:7f:8:4:2:64:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0"
			raise "Can't find the arduino" unless File.writable?(filename)
			`stty -F #{filename} #{flags}`
			@serialport = File.open(filename, "w+")
			@serialport.flush
		end

		after do
			@serialport.close
		end

		should "respond with '" + expected_response.strip + "\\r\\n" + "' to '" + stimulus.strip + "\\r\\n" + "'" do
			@serialport.write stimulus
			@serialport.flush
			timeout(0.1) {
				@serialport.readline.should==(expected_response)
			}
		end
	end

end

