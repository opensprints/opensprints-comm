require 'rubygems'
require 'bacon'
require 'timeout'

describe 'Basic Message Firmware' do
  before do
    filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
	flags = "406:0:18b2:8a30:3:1c:7f:8:4:2:64:0:11:13:1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0"
    raise "Can't find the arduino" unless File.writable?(filename)
    `stty -F #{filename} #{flags}`
    @serialport = File.open(filename, "w+")
  end

  after do
    @serialport.close
  end

  it "should respond to 'v' with its version" do
    @serialport.putc ?v
    @serialport.putc ?\n
    Timeout.timeout(2) {
      @serialport.readline.should==("basic-1\r\n")
    }
  end
end
