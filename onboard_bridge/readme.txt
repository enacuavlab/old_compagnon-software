Check pprz.txt

-------------------------------------------------------------------------------
cd /home/pi/Projects/compagnon-software/pprzlink

./tools/generator/gen_messages.py --protocol 2.0 --lang C_standalone -o build/pprzlink/datalink_msg.h message_definitions/v1.0/messages.xml datalink --opt PING,SETTING,GUIDED_SETPOINT_NED,REMOTE_GPS_LOCAL

./tools/generator/gen_messages.py --protocol 2.0 --lang C_standalone -o build/pprzlink/telemetry_msg.h message_definitions/v1.0/messages.xml telemetry --opt ATTITUDE,GPS,PPRZ_MODE,DESIRED,COMMANDS,ACTUATORS,ROTORCRAFT_FP,IMU_GYRO,IMU_MAG,IMU_ACCEL 

cd /home/pi/Projects/compagnon-software/onboard_bridge
mkdir lib exe

cc -g -fPIC -shared src/libbridge.c -o lib/libbridge.so -I./inc -I/home/pi/Projects/compagnon-software/pprzlink/build

cc -g src/onboard_bridge.c -o exe/onboard_bridge -I./inc -I/home/pi/Projects/compagnon-software/pprzlink/build -L/home/pi/Projects/compagnon-software/onboard_bridge/lib -lbridge

-------------------------------------------------------------------------------
socat -u /dev/ttyAMA0,raw,echo=0,b115200 udp-sendto:127.0.0.1:4242 &
socat -u udp-listen:4243,reuseaddr,fork /dev/ttyAMA0,raw,echo=0,b115200 &

LD_LIBRARY_PATH=/home/pi/Projects/compagnon-software/onboard_bridge/lib;./exe/onboard_bridge 4244 4245 4246

-------------------------------------------------------------------------------
export PYTHONPATH=/home/pi/pprzlink/lib/v2.0/python:$PYTHONPATH
python3 ./onboard_bridge/src/onboard_bridge.py 4243 4242
