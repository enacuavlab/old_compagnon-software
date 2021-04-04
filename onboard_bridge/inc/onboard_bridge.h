#ifndef MUXLIB_H
#define MUXLIB_H

#define PPRZSIZE 255

#include "pprzlink/telemetry_msg.h"
#include "pprzlink/datalink_msg.h"

extern int muxlib_init(int argc, char **argv); 
extern int muxlib_check_and_parse(uint8_t* classid,uint8_t* msgid, uint8_t* bufsize, uint8_t *buf);
extern void muxlib_send_GUIDED_SETPOINT_NED(uint8_t acid, uint8_t flags, float x, float y, float z, float yaw);

#endif
