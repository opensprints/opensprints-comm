# std
import io
import time

# vendor
import serial

ser = serial.Serial('/dev/tty.usbserial-A6008sxN', 115200, timeout=1)

time.sleep(2)
sio = io.TextIOWrapper(io.BufferedRWPair(ser, ser))
sio.write(unicode("v"))
sio.flush()
print(sio.readline())
ser.close()
