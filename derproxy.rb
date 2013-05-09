#!/usr/bin/env ruby

require 'socket'

serproxy_dir = "/Users/orluke/Downloads/tinkerproxy-2_0"
# TODO: determine the comm port 
pid = spawn("#{serproxy_dir}/serproxy.osx #{serproxy_dir}/serproxy.osx.cfg")

sleep(1)

sock = TCPSocket.new("localhost", 5331)
sleep(2)
sock.write "!v\n"
#puts sock.gets("\r\n")
#puts sock.readline("\r\n")
puts sock.recv(9)
#while line = sock.gets # Read lines from socket
#  puts line         # and print them
#end
sock.close

sleep(1)
Process.kill(9, pid)

