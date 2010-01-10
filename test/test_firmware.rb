require 'rubygems'
require 'bacon'
require 'timeout'
include Timeout
#prime the serial port
filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
serialport = File.open(filename, "w+")
serialport.close
sleep(2)

describe 'Basic Message Firmware' do
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

  should "respond with 'basic-2' to 'v'" do
    @serialport.putc ?v
    @serialport.putc ?\r
    @serialport.putc ?\n
    @serialport.flush
    timeout(0.1) {
      @serialport.readline.should==("v:basic-2\r\n")
    }
  end
#  should "respond with 'l:ERROR receiving tick lengths' to 'l\\000\\r\\n'" do
#    @serialport.putc ?l
#    @serialport.putc ?\000
#    @serialport.putc ?\r
#    @serialport.putc ?\n
#    timeout(0.1) {
#      @serialport.readline.should==("l:ERROR receiving tick lengths\r\n")
#    }
#  end

  should "respond with 'OK 0' to 'l\\000\\000\\r\\n'" do
    @serialport.putc ?l
    @serialport.putc ?\000
    @serialport.putc ?\000
    @serialport.putc ?\r
    @serialport.putc ?\n
    timeout(0.1) {
      @serialport.readline.should==("l:0\r\n")
    }
  end
  should "accept distance that include other commands" do
    @serialport.putc ?l
    @serialport.putc ?v
    @serialport.putc ?\000
    @serialport.putc ?\r
    @serialport.putc ?\n
    timeout(0.1) {
      @serialport.readline.should==("l:118\r\n")
    }
  end
  should "accept the max possible distance" do
    @serialport.putc ?l
    @serialport.putc 255
    @serialport.putc 255
    @serialport.putc ?\r
    @serialport.putc ?\n
    timeout(0.1) {
      @serialport.readline.should==("l:65535\r\n")
    }
  end
end

