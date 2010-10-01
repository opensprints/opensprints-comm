# TODO
# Either raceLengthTicks or raceDurationSecs needs to be zero.
#    Test for the invalid state in which neither or both are zero.
#

require 'rubygems'
require 'bacon'
require 'timeout'
include Timeout

# Prime the serial port
# First time opening the device (port / file / tty) after plugging in the 
# Arduino causes it to reboot.
filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
flags = "406:0:18b2:8a30:3:1c:7f:8:4:2:64:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0"
raise "Can't find the arduino" unless File.writable?(filename)
`stty -F #{filename} #{flags}`
serialport = File.open(filename, "w+")
serialport.flush
serialport.close
sleep(1.5)

# Get Racemonitor back to Idle State from any other state
# and reset all API-writeable values to their system defaults.
serialport = File.open(filename, "w+")
serialport.write "!s\r\n"
serialport.flush
timeout(0.2) {
	puts serialport.readline
}

serialport.close

serialport = File.open(filename, "w+")

serialport.write "!defaults\r\n"
serialport.flush
timeout(0.2) {
	puts serialport.readline
}


idle_stimulus_and_response = [
  ["Test a countdown boundary case:\n", "!c:-1\r\n",    "NACK\r\n"], 
  ["Test a countdown valid case:\n",    "!c:0\r\n",     "C:0\r\n"], 
  ["Test a countdown valid case:\n",    "!c:1\r\n",     "C:1\r\n"], 
  ["Test a countdown valid case:\n",    "!c:127\r\n",   "C:127\r\n"], 
  ["Test a countdown valid case:\n",	"!c:128\r\n",   "C:128\r\n"], 
  ["Test a countdown valid case:\n",    "!c:255\r\n",   "C:255\r\n"], 
  ["Test a countdown boundary case:\n", "!c:256\r\n",   "C:NACK\r\n"], 
  ["Test the hw command with a valid message:\n",   "!hw\r\n","HW:3\r\n"],
  ["Test the racer enable command with a malformed message:\n",   "!i\r\n","NACK\r\n"],
  ["Test the racer enable command with a boundary case:\n",  "!i:0\r\n","I:NACK\r\n"],
  ["Test the racer enable command with a boundary case:\n",  "!i:4294967296\r\n","I:NACK\r\n"],
  ["Test the racer enable command with a valid message:\n",  "!i:6\r\n","I:ERROR\r\n"],
  ["Test the racer enable command with a valid message:\n",  "!i:4294967295\r\n","I:ERROR\r\n"],
# Replace the above 2 tests with the following 2 sets when the i: command gets implemented.
#  ["Test the racer enable command with a valid message:\n",  "!i:6\r\n","I:6\r\n"],
#  ["Test the racer enable command with a valid message:\n",  "!i:4294967295\r\n","I:4294967295\r\n"],
  ["Test the race length command with a malformed message:\n",   "!l\r\n","NACK\r\n"],
  ["Test the race length command with a valid message:\n",   "!l:0\r\n","L:0\r\n"],
  ["Test the race length command with a valid message:\n",   "!l:65535\r\n","L:65535\r\n"],
  ["Test the race length command with a boundary case:\n",   "!l:65536\r\n","L:NACK\r\n"],
  ["Test the mock mode command with a valid message:\n",     "!m\r\n","M:ON\r\n"],
  ["Test the mock mode command with a malformed message:\n", "!m:0\r\n","NACK\r\n"],
  ["Test the mock mode command with a valid message:\n",     "!m\r\n","M:OFF\r\n"],
  ["Test the mock mode command with a valid message:\n",     "!m\r\n","M:ON\r\n"],
  ["Test the timer command with a malformed message:\n",   "!t\r\n","NACK\r\n"],
  ["Test the timer command with a valid message:\n",   "!t:0\r\n","T:0\r\n"],
  ["Test the timer command with a valid message:\n",   "!t:65535\r\n","T:65535\r\n"],
  ["Test the timer command with a boundary case:\n",   "!t:65536\r\n","T:NACK\r\n"],
  ["Test the protocol request command with a valid message:\n",   "!p\r\n","P:1.02\r\n"],
  ["Test the protocol request command with a malformed message:\n",   "!p:023\r\n","NACK\r\n"],
  ["Test the fw version request command with a valid message:\n",   "!v\r\n","V:1.02\r\n"],
  ["Test the fw version request command with a malformed message:\n",   "!v:555\r\n","NACK\r\n"],
  ["Test the Go command with a malformed message:\n",   "!g:\r\n",  "NACK\r\n"],
  ["Test the Go command with a boundary case:\n",       "!g:1098\r\n","NACK\r\n"],
  ["Test the Go command with a malformed message:\n",   "!g:$!&#\r\n","NACK\r\n"],
]

idle_stimulus_and_response.each do |descr,stimulus,expected_response|

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

def write_command(command)
  filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
  flags = "406:0:18b2:8a30:3:1c:7f:8:4:2:64:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0"
  raise "Can't find the arduino" unless File.writable?(filename)
  `stty -F #{filename} #{flags}`
  @serialport = File.open(filename, "w+")
  @serialport.write command
  @serialport.close
  @serialport = File.open(filename, "w+")
end

def set_to_defaults!
  write_command("!defaults\r\n")

  timeout(1.1) {
    @serialport.readline
  }
end

describe "countdown" do
  before do
    set_to_defaults!
  end

  it "should count down to zero, defaulting to 4" do
    #@serialport.flush
    write_command("!g\r\n") 
    timeout(0.1) {
      @serialport.readline.should == "G\r\n"
    }
    result = ''
    timeout(6) do
      6.times do
        result += @serialport.readline
      end
      #result.should == "CD:4\r\nCD:3\r\nCD:2\r\nCD:1\r\nCD:0\r\n"
      result.should.include("CD:4\r\nCD:3\r\nCD:2\r\nCD:1\r\nCD:0\r\n")
    end
  end

end

def write_stimulus(stimulus)
  write_command(stimulus)
  timeout(0.1) {
    return @serialport.readline
  }
end

describe "The handshake" do
  before do
    set_to_defaults!
  end
  describe "with a number 0-65535" do
    it "should reply with the given number" do
      write_stimulus("!a:0\r\n").should==("A:0\r\n")
      write_stimulus("!a:12345\r\n").should==("A:12345\r\n")
      write_stimulus("!a:65535\r\n").should==("A:65535\r\n") 
    end
  end

  describe "with numbers greater than 65535" do
    it "should NACK back" do
			write_command("!a:65536\r\n")
			timeout(0.1) {
				@serialport.readline.should==("A:NACK\r\n")
			}
    end
  end
end

describe "Get default race length" do
  before do
    set_to_defaults!
  end
  describe "After resetting parameters to default values, raceLengthTicks " do
    it "should be 500" do
      write_stimulus("!getlen\r\n").should==("L:500\r\n")
    end
  end
end

describe "Get changed race length" do
  before do
    set_to_defaults!
    write_stimulus("!l:400\r\n")
  end
  describe "After changing value raceLengthTicks of raceLengthTicks to 444, " do
    it "getlen should respond with 444" do
      write_stimulus("!getlen\r\n").should==("L:500\r\n")
    end
  end
end
