import unittest
import socket
from time import sleep

TCP_IP = '127.0.0.1'
TCP_PORT = 5331

BUFFER_SIZE = 1024


class Test(unittest.TestCase):

    def setUp(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect((TCP_IP, TCP_PORT))
        sleep(3)
        message = "!v|"
        print('sending %s' % message)
        s.send(message)
        self.data = s.recv(BUFFER_SIZE)
        s.close()

    def test_zero(self):
        self.assertEqual('V:2.0.02\n', self.data)
