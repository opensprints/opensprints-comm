require 'rubygems'
require 'bacon'
require 'timeout'
include Timeout
#prime the serial port
filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
serialport = File.open(filename, "w+")
serialport.close
sleep(1)

stimulus_and_response = [
  ["!a:0\r\n","A:0\r\n"],
  ["!a:12345\r\n","A:12345\r\n"],
  ["!a:65535\r\n","A:65535\r\n"],
  ["!a:65536\r\n","A:NACK\r\n"],
  ["!c:-1\r\n","NACK\r\n"],
  ["!c:0\r\n","C:0\r\n"],
  ["!c:1\r\n","C:1\r\n"],
  ["!c:127\r\n","C:127\r\n"],
  ["!c:128\r\n","C:NACK\r\n"],
  ["!g\r\n","G\r\n"],
  ["!g:\r\n","NACK\r\n"],
  ["!g:1098\r\n","NACK\r\n"],
  ["!g:$!&#\r\n","NACK\r\n"],
  ["!hw\r\n","HW:3\r\n"],
  ["!i\r\n","NACK\r\n"],
  ["!i:0\r\n","I:NACK\r\n"],
  ["!i:6\r\n","I:6\r\n"],
  ["!i:4294967295\r\n","I:4294967295\r\n"],
  ["!i:4294967296\r\n","I:NACK\r\n"],
  ["!l\r\n","NACK\r\n"],
  ["!l:0\r\n","L:0\r\n"],
  ["!l:65535\r\n","L:65535\r\n"],
  ["!l:65536\r\n","L:NACK\r\n"],
  ["!m\r\n","M\r\n"],
  ["!m:0\r\n","NACK\r\n"],
  ["!s\r\n","S\r\n"],
  ["!s:0\r\n","NACK\r\n"],
  ["!t\r\n","NACK\r\n"],
  ["!t:0\r\n","T:0\r\n"],
  ["!t:65535\r\n","T:65535\r\n"],
  ["!t:65536\r\n","T:NACK\r\n"],
  ["!p\r\n","P:2.0\r\n"],
  ["!p:023\r\n","NACK\r\n"],
  ["!v\r\n","V:2.0\r\n"],
  ["!v:555\r\n","NACK\r\n"]
]


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

  stimulus_and_response.each do |stimulus,expected_response|
    should "respond with '" + expected_response + "' to '" + stimulus + "'" do
      @serialport.write stimulus
      @serialport.flush
      timeout(0.1) {
        @serialport.readline.should==(expected_response)
      }
    end
  end

end

