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
	serialport.readline
}

serialport.close

serialport = MockFirmware.open(filename, "w+")

serialport.write "!defaults\r\n"
serialport.flush
timeout(0.2) {
	serialport.readline
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
			write_stimulus("!a:65536\r\n").should==("A:NACK\r\n")
    end
  end
end

describe "The race length command" do
  describe "with a malformed message" do
    it "should NACK back" do
			write_stimulus("!l\r\n").should==("NACK\r\n")
    end
  end

  describe "with a number between 0 and 65535" do
    it "should ACK with the given number" do
      write_stimulus("!l:0\r\n").should==("L:0\r\n")
      write_stimulus("!l:65535\r\n").should==("L:65535\r\n")
    end
  end

  describe "with a number greater than 65535" do
    it "should NACK back" do
      write_stimulus("!l:65536\r\n").should==("L:NACK\r\n")
    end
  end

end

describe "The time command" do
  describe "with a malformed message" do
    it "should NACK back" do
      write_stimulus("!t\r\n").should==("NACK\r\n")
    end
  end

  describe "with a number between 0 and 65535" do
    it "should ACK with the given number" do
      write_stimulus("!t:0\r\n").should==("T:0\r\n")
      write_stimulus("!t:65535\r\n").should==("T:65535\r\n")
    end
  end

  describe "with a number greater than 65535" do
    it "should NACK back" do
      write_stimulus("!t:65536\r\n").should==("T:NACK\r\n")
    end
  end
end

describe "Setting the countdown length" do
  describe "with a number greater than 65535 or less than 0" do
    it "should NACK back" do
      write_stimulus("!c:-1\r\n").should==("NACK\r\n")
      write_stimulus("!c:256\r\n").should==("C:NACK\r\n")
    end
  end

  describe "with a number between 0 and 65535" do
    it "should ACK with the given number" do
      write_stimulus("!c:0\r\n").should==("C:0\r\n")
      write_stimulus("!c:1\r\n").should==("C:1\r\n")
      write_stimulus("!c:127\r\n").should==("C:127\r\n")
      write_stimulus("!c:128\r\n").should==("C:128\r\n")
      write_stimulus("!c:255\r\n").should==("C:255\r\n")
    end
  end
end

describe "The go command" do
  it "should NACK with a malformed message" do
    write_stimulus("!g:\r\n").should==("NACK\r\n")
    write_stimulus("!g:1098\r\n").should==("NACK\r\n")
    write_stimulus("!g:$!&#\r\n").should==("NACK\r\n")
  end

  it "should ACK with a well formed message" do
    write_stimulus("!g\r\n").should==("G\r\n")
  end
end
