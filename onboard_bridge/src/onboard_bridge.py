#!/usr/bin/env python3

#export PYTHONPATH=/home/pi/pprzlink/lib/v2.0/python:$PYTHONPATH
#socat -u /dev/ttyAMA0,raw,echo=0,b115200 udp-sendto:127.0.0.1:4246 &
#python3 ./muxer/src/muxer.py 1 2

import sys
import time
import struct
import dataclasses

from ctypes import *

muxlib = CDLL("/home/pi/Projects/compagnon-software/onboard_bridge/lib/libbridge.so")

muxlib.muxlib_init.argtypes = [c_int,POINTER(c_char)]
muxlib.muxlib_check_and_parse.restype = c_int
muxlib.muxlib_check_and_parse.argtypes = [POINTER(c_int),POINTER(c_int),POINTER(c_int),POINTER(c_ubyte)]
muxlib.muxlib_send_GUIDED_SETPOINT_NED.argtypes = [c_int,c_int,c_float,c_float,c_float,c_float]

# from messages.xml
ALT_UNIT_COEF_ATT = 0.0139882
ALT_UNIT_COEF_GYR = 57.29578

# datalink
PPRZ_MSG_ID_SETTING = 4

# telemetry 
PPRZ_MSG_ID_ATTITUDE      = 6
PPRZ_MSG_ID_GPS           = 8
PPRZ_MSG_ID_PPRZ_MODE     = 11
PPRZ_MSG_ID_DESIRED       = 16
PPRZ_MSG_ID_COMMANDS      = 102
PPRZ_MSG_ID_ACTUATORS     = 105
PPRZ_MSG_ID_ROTORCRAFT_FP = 147
PPRZ_MSG_ID_IMU_GYRO      = 200
PPRZ_MSG_ID_IMU_MAG       = 201
PPRZ_MSG_ID_IMU_ACCEL     = 202

PPRZSIZE = 256

class att_t:
  stamp: time
  phy:   float
  theta: float
  psi:   float
att_g = att_t()

class gps_t:
  stamp:      time
  mode:       int
  utm_east:   int
  utm_north:  int
  course:     int
  alt:        int
  speed:      int
  climb:      int
  week:       int
  itow:       int
  utm_zone:   int
  gps_nb_err: int
gps_g = gps_t()

class mde_t:
  stamp:         time
  ap_mode:       int
  ap_gaz:        int
  ap_lateral:    int
  ap_horizontal: int
  if_calib_mode: int
  mcu1_status:   int
mde_g = mde_t()

class des_t:
  stamp:    time
  roll:     float
  pitch:    float
  course:   float
  x:        float
  y:        float
  altitude: float
  climb:    float
  airspeed: float
des_g = des_t()

class cmd_t:
  stamp:     time
  nbvalues:  int
  myvalues = []
cmd_g = cmd_t()

class act_t:
  stamp:     time
  nbvalues:  int
  myvalues = []
act_g = act_t()

class rfp_t:
  stamp: time
  phy:   float
  theta: float
  psi:   float
rfp_g = rfp_t()

class gyr_t:
  stamp: time
  gp:    float
  gq:    float
  gr:    float
gyr_g = gyr_t()

class mag_t:
  stamp: time
  mx:    float
  my:    float
  mr:    float
mag_g = mag_t()

class acc_t:
  stamp: time
  ax:    float
  ay:    float
  ar:    float
acc_g = acc_t()


if __name__ == "__main__":
  argc = len(sys.argv)
  if ((argc<3)or(argc>4)):
    print("muxer.py 4244 4245")
    print("muxer.py 4244 4245 4246")
    sys.exit(2)
  else:
    p = (POINTER(c_char)*argc)()
    for i, arg in enumerate(sys.argv):
      enc_arg = arg.encode('utf-8')
      p[i] = create_string_buffer(enc_arg)

    if(muxlib.muxlib_init(argc,cast(p,POINTER(c_char))) == 0):
      classid = c_int()
      msgid   = c_int()
      bufsize = c_int()
      buf = (c_ubyte * PPRZSIZE)()
      ret = 0 

      tv = time.time()
      start = tv

      while (ret>=0):

        ret = muxlib.muxlib_check_and_parse(classid,msgid,bufsize,buf)

        if(ret>0):

          tv = time.time()
          elapsed = tv - start

          # UPLINK (datalink)

          if(msgid.value == PPRZ_MSG_ID_SETTING):
            index=struct.unpack('B',bytearray(buf[4:5]))[0]
            if(index==6):
              offset=6
              value = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
              if(value==19.0):
                offset=5;
                acid = struct.unpack('B',bytearray(buf[5:6]))[0]
                flag = 0x0E
          	# goto to a position relative to current position and heading in meters
                muxlib.muxlib_send_GUIDED_SETPOINT_NED(1,2,1.0,0.0,0.0,0.0);


          # DOWNLINK (telemetry)

          if(msgid.value == PPRZ_MSG_ID_ATTITUDE):
            att_g.stamp = tv
            offset=4
            att_g.phi   = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            att_g.psi   = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            att_g.theta = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            acid = buf[0]
            print("%.4f %d ATTITUDE %f %f %f" % (elapsed,acid,att_g.phi,att_g.psi,att_g.theta))
             

          if(msgid.value == PPRZ_MSG_ID_GPS):
            gps_g.stamp = tv
            offset=4
            gps_g.mode        = buf[offset];offset=offset+1
            gps_g.utm_north   = buf[offset];offset=offset+4
            gps_g.utm_east    = buf[offset];offset=offset+4
            gps_g.course      = buf[offset];offset=offset+2
            gps_g.alt         = buf[offset];offset=offset+4
            gps_g.speed       = buf[offset];offset=offset+2
            gps_g.climb       = buf[offset];offset=offset+2
            gps_g.week        = buf[offset];offset=offset+2
            gps_g.itow        = buf[offset];offset=offset+4
            gps_g.utm_zone    = buf[offset];offset=offset+1
            gps_g.gps_nb_err  = buf[offset];offset=offset+1
            acid = buf[0]
            print("%.4f %d GPS %d %d %d %d %d %d %d %d %d %d %d" % (elapsed,acid,
                gps_g.mode,gps_g.utm_east,gps_g.utm_north,gps_g.course,gps_g.alt,
                gps_g.speed,gps_g.climb,gps_g.week,gps_g.itow,gps_g.utm_zone,gps_g.gps_nb_err))


          if(msgid.value == PPRZ_MSG_ID_PPRZ_MODE):
            mde_g.stamp = tv
            offset=4
            mde_g.ap_mode       = buf[offset];offset=offset+1
            mde_g.ap_gaz        = buf[offset];offset=offset+1
            mde_g.ap_lateral    = buf[offset];offset=offset+1
            mde_g.ap_horizontal = buf[offset];offset=offset+1
            mde_g.if_calib_mode = buf[offset];offset=offset+1
            mde_g.mcu1_status   = buf[offset];offset=offset+1
            acid = buf[0]
            print("%.4f %d PPRZ_MODE %d %d %d %d %d %d\n" % (elapsed,acid,
                    mde_g.ap_mode,mde_g.ap_gaz,mde_g.ap_lateral,mde_g.ap_horizontal,
		    mde_g.if_calib_mode,mde_g.mcu1_status))


          if(msgid.value == PPRZ_MSG_ID_DESIRED):
            mde_g.stamp = tv
            offset=4
            des_g.roll     = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];offset=offset+4
            des_g.pitch    = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];offset=offset+4
            des_g.course   = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];offset=offset+4
            des_g.x        = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];offste=offset+4
            des_g.y        = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];offset=offset+4
            des_g.altitude = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];offset=offset+4
            des_g.climb    = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];offset=offset+4
            des_g.airspeed = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0];
            acid = buf[0]
            print("%.4f %d DESIRED %f %f %f %f %f %f %f %f\n" % (elapsed,acid,
	            des_g.roll,des_g.pitch,des_g.course,des_g.x,des_g.y,des_g.altitude,
		    des_g.climb, des_g.airspeed))


          if(msgid.value == PPRZ_MSG_ID_COMMANDS):
            cmd_g.stamp = tv
            offset=4
            cmd_g.nbvalues = buf[offset];offset=offset+1
            mystr=""
            for nb in range(cmd_g.nbvalues):
              if nb!=0:mystr=mystr+','
              cmd_g.myvalues.append(struct.unpack('h',bytearray(buf[offset:offset+2]))[0])
              offset=offset+2
              mystr=mystr+str(act_g.myvalues[nb])
            acid = buf[0]
            print("%.4f %d COMMANDS %s" % (elapsed,acid,str))
	 

          if(msgid.value == PPRZ_MSG_ID_ACTUATORS):
            act_g.stamp = tv
            offset=4
            act_g.nbvalues = buf[offset];offset=offset+1
            mystr=""
            for nb in range(act_g.nbvalues):
              if nb!=0:mystr=mystr+','
              act_g.myvalues.append(struct.unpack('h',bytearray(buf[offset:offset+2]))[0])
              offset=offset+2
              mystr=mystr+str(act_g.myvalues[nb])
            acid = buf[0]
            print("%.4f %d ACTUATORS %s" % (elapsed,acid,mystr))


          if(msgid.value == PPRZ_MSG_ID_ROTORCRAFT_FP):
            rfp_g.stamp = tv
            offset=28
            rfp_g.phy = ALT_UNIT_COEF_ATT*float(int.from_bytes(buf[offset:offset+4], byteorder='little', signed=True))
            offset=offset+4
            rfp_g.theta = ALT_UNIT_COEF_ATT*float(int.from_bytes(buf[offset:offset+4], byteorder='little', signed=True))
            offset=offset+4
            rfp_g.psi = ALT_UNIT_COEF_ATT*float(int.from_bytes(buf[offset:offset+4], byteorder='little', signed=True))
            acid=buf[0]
            print("%.4f %d ROTORCRAFT_FP %f %f %f" % (elapsed,acid,rfp_g.phy, rfp_g.theta, rfp_g.psi))


          if(msgid.value == PPRZ_MSG_ID_IMU_GYRO):
            gyr_g.stamp = tv
            offset=4
            gyr_g.gp = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            gyr_g.gq = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            gyr_g.gr = ALT_UNIT_COEF_GYR*struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            acid=buf[0]
            print("%.4f %d IMU_GYRO %f %f %f" % (elapsed,acid, gyr_g.gp, gyr_g.gq, gyr_g.gr))


          if(msgid.value == PPRZ_MSG_ID_IMU_MAG):
            mag_g.stamp = tv
            offset=4
            mag_g.mx = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            mag_g.my = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            mag_g.mz = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            acid=buf[0]
            print("%.4f %d IMU_MAG %f %f %f" % (elapsed,acid, mag_g.mx, mag_g.my, mag_g.mz))


          if(msgid.value == PPRZ_MSG_ID_IMU_ACCEL):
            acc_g.stamp = tv
            offset=4
            acc_g.ax = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            acc_g.ay = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            offset=offset+4
            acc_g.az = struct.unpack('f',bytearray(buf[offset:offset+4]))[0]
            acid=buf[0]
            print("%.4f %d IMU_ACCEL %f %f %f" % (elapsed,acid, acc_g.ax, acc_g.ay, acc_g.az))
