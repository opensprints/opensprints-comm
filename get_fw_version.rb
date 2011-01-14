require 'rubygems'
require 'timeout'
include Timeout

# Prime the serial port
# First time opening the device (port / file / tty) after plugging in the 
# Arduino causes it to reboot.
filename = Dir.glob("/dev/tty{.usb,USB}*")
puts filename
=begin
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

=end
