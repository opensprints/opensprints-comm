require 'rubygems'
require 'bacon'
require 'timeout'

describe 'Basic Message Firmware' do
  before do
    filename = "/dev/ttyUSB0"
    raise "Can't find the arduino" unless File.writable?(filename)
    `stty -F #{filename} cs8 115200 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts`
    @serialport = File.open(filename, "w+")
  end

  after do
    @serial.close
  end

  it "should respond to 'v' with its version" do
    @serialport.putc ?v
    @serialport.putc ?\n
    Timeout.timeout(2) {
      @serialport.readline.should==("basic-1")
    }
  end
end
