require 'rubygems'
require 'bacon'
require 'timeout'
require 'lib/opensprints-comm'
include Timeout

filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
serialport = MockFirmware.open(filename, "w+")
serialport.flush
serialport.close
sleep(1.5)

serialport = MockFirmware.open(filename, "w+")
serialport.write "!s\r\n"
serialport.flush
timeout(0.2) {
	puts serialport.readline
}

serialport.close

serialport = MockFirmware.open(filename, "w+")

serialport.write "!defaults\r\n"
serialport.flush
timeout(0.2) {
	puts serialport.readline
}
serialport.close

def write_command(command)
  filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
  @serialport = MockFirmware.open(filename, "w+")
  @serialport.write command
  @serialport.close
  @serialport = MockFirmware.open(filename, "w+")
end

def set_to_defaults!
  write_command("!defaults\r\n")

  timeout(1.1) {
    @serialport.readline
  }
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
