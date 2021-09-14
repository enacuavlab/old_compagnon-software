#!/usr/bin/python3

import socket
import struct
import threading
import time
import signal

import sys
import serial


try:
    from enum import Enum
except ImportError:
    Enum = object

STX = 0x99

class PprzParserState(Enum):
    WaitSTX = 1
    GotSTX = 2
    GotLength = 3
    GotPayload = 4
    GotCRC1 = 5


class PprzTransport(object):
    def __init__(self):
        self.state = PprzParserState.WaitSTX
        self.length = 0
        self.buf = []
        self.ck_a = 0
        self.ck_b = 0
        self.idx = 0

    def parse_byte(self, c):
        b = struct.unpack("<B", c)[0]
        if self.state == PprzParserState.WaitSTX:
            if b == STX:
                self.state = PprzParserState.GotSTX
        elif self.state == PprzParserState.GotSTX:
            self.length = b - 4
            if self.length <= 0:
                self.state = PprzParserState.WaitSTX
                return False
            self.buf = bytearray(b)
            self.ck_a = b % 256
            self.ck_a = b % 256
            self.ck_b = b % 256
            self.buf[0] = STX
            self.buf[1] = b
            self.idx = 2
            self.state = PprzParserState.GotLength
        elif self.state == PprzParserState.GotLength:
            self.buf[self.idx] = b
            self.ck_a = (self.ck_a + b) % 256
            self.ck_b = (self.ck_b + self.ck_a) % 256
            self.idx += 1
            if self.idx == self.length+2:
                self.state = PprzParserState.GotPayload
        elif self.state == PprzParserState.GotPayload:
            if self.ck_a == b:
                self.buf[self.idx] = b
                self.idx += 1
                self.state = PprzParserState.GotCRC1
            else:
                self.state = PprzParserState.WaitSTX
        elif self.state == PprzParserState.GotCRC1:
            self.state = PprzParserState.WaitSTX
            if self.ck_b == b:
                self.buf[self.idx] = b
                return True
        else:
            self.state = PprzParserState.WaitSTX
        return False



class serial2ethernet(threading.Thread):
  def __init__(self, fd, sock, addr):
    threading.Thread.__init__(self)
    self.fd = fd
    self.sock = sock
    self.addr = addr
    self.shutdown_flag = threading.Event()
    self.trans = PprzTransport()
    self.running = True

  def stop(self):
    self.running = False
    self.server.close()

  def run(self):
    try:
      while self.running  and not self.shutdown_flag.is_set():
        try:
          while True:
            #print(rl.readline())
            waiting = self.fd.in_waiting 
            #msg += [chr(c) for c in ser.read(waiting)
            if waiting > 0:
              msg = self.fd.read(waiting)
              for c in msg:
                if not isinstance(c, bytes): c = struct.pack("B",c)
                if self.trans.parse_byte(c):
                  print("OUT msg_id:",self.trans.buf[5])
                  self.sock.sendto(self.trans.buf, self.addr)
        except socket.timeout:
          pass
    except StopIteration:
      pass



class ethernet2serial(threading.Thread):
  def __init__(self, fd, sock):
    threading.Thread.__init__(self)
    self.fd = fd
    self.sock = sock
    self.shutdown_flag = threading.Event()
    self.trans = PprzTransport()
    self.running = True

  def stop(self):
    self.running = False
    self.server.close()

  def run(self):
    try:
      while self.running  and not self.shutdown_flag.is_set():
        try:
          (msg, address) = self.sock.recvfrom(2048)
          length = len(msg)
          for c in msg:
            if not isinstance(c, bytes): c = struct.pack("B",c)
            if self.trans.parse_byte(c):
              print("IN msg_id:",self.trans.buf[5])
              self.fd.write(self.trans.buf)
        except socket.timeout:
          pass
    except StopIteration:
      pass



#SERIAL='/dev/ttyUSB0'
SERIAL='/dev/ttyAMA0'
BAUDRATE=115200
PORT_OUT=4244
PORT_IN=4245

if __name__ == '__main__':

  ser     = serial.Serial(SERIAL, BAUDRATE)
  sockIn  = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  sockOut = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  sockIn.bind(('localhost', PORT_IN))
  addr = ('localhost', PORT_OUT)

  streams = []
  streams.append(serial2ethernet(ser,sockOut,addr))
  streams.append(ethernet2serial(ser,sockIn))

  for thread in streams: thread.start()
  try:
    while True:
      time.sleep(2)
  except KeyboardInterrupt:
    for thread in streams:
      thread.shutdown_flag.set()
      thread.join()
