require 'rubygems'
require 'bacon'
require 'timeout'

describe 'Basic Message Firmware' do
  before do
    filename = ENV['OPENSPRINTS_PORT']||"/dev/ttyUSB0"
    raise "Can't find the arduino" unless File.writable?(filename)




    `stty -F #{filename} -parenb -parodd cs8 -hupcl -cstopb cread clocal -crtscts ignbrk -brkint ignpar -parmrk -inpck -istrip -inlcr -igncr -icrnl -ixon -ixoff -iuclc -ixany -imaxbel -iutf8 -opost -olcuc -ocrnl -onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0 -isig -icanon -iexten -echo -echoe -echok -echonl noflsh -xcase -tostop -echoprt -echoctl -echoke`
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
