Check pprz.txt

-------------------------------------------------------------------------------
cd /home/pi/pprzlink

./tools/generator/gen_messages.py --protocol 2.0 --lang C_standalone -o build/pprzlink/datalink_msg.h message_definitions/v1.0/messages.xml datalink --opt PING,SETTING,GUIDED_SETPOINT_NED,REMOTE_GPS_LOCAL

./tools/generator/gen_messages.py --protocol 2.0 --lang C_standalone -o build/pprzlink/telemetry_msg.h message_definitions/v1.0/messages.xml telemetry --opt ATTITUDE,GPS,PPRZ_MODE,DESIRED,COMMANDS,ACTUATORS,ROTORCRAFT_FP,IMU_GYRO,IMU_MAG,IMU_ACCEL 

mkdir -p onboard_bridge/lib muxer/exe

cc -g -fPIC -shared onboard_bridge/src/muxlib.c -o muxer/lib/libmux.so -I/home/pi/muxer/inc -I/home/pi/pprzlink/build

cc -g onboard_bridge/src/muxer.c -o muxer/exe/muxer -I/home/pi/pprzlink/build -I/home/pi/muxer/inc -L/home/pi/muxer/lib -lmux


socat -u /dev/ttyAMA0,raw,echo=0,b115200 udp-sendto:127.0.0.1:4242 &
socat -u udp-listen:4243,reuseaddr,fork /dev/ttyAMA0,raw,echo=0,b115200 &

export PYTHONPATH=/home/pi/pprzlink/lib/v2.0/python:$PYTHONPATH
python3 ./onboard_bridge/src/muxer.py 4243 4242

export LD_LIBRARY_PATH=/home/pi/onboard_bridge/lib
./onboard_bridge/exe/muxer 4244 4245 4246
