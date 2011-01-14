require 'rubygems'
require 'timeout'
include Timeout
require 'serialport'

def getVersion(devLoc)
  #params for serial port
  port_str = devLoc  #may be different for you
  baud_rate = 115200
  data_bits = 8
  stop_bits = 1
  parity = SerialPort::NONE

  sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

  # The ATmega reboots once connection is made to the FTDI part.
  # So wait for it to come back up before sending anything.
  sleep(2)
  timeout(4) {
    sp.write "!v\r\n"
    puts sp.readline
  }

  sp.close                       #see note 1
  
  #raise "Can't find the arduino" unless File.writable?(devLoc)
end

# Prime the serial port
# First time opening the device (port / file / tty) after plugging in the 
# Arduino causes it to reboot.
mntLoc = Dir.glob("/dev/tty{.usb,USB}*")[0]
if mntLoc == nil
  puts "nothing attached to an expected mount point."
else
  puts mntLoc
  getVersion(mntLoc)
end

