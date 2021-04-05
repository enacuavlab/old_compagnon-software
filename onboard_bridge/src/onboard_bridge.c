/*
cc -g src/onboard_bridge.c -o exe/onboard_bridge -I./inc -I/home/pi/Projects/compagnon-software/pprzlink/build -L/home/pi/Projects/compagnon-software/onboard_bridge/lib -lbridge

export LD_LIBRARY_PATH=/home/pi/Projects/onboard_bridge/lib
./exe/onboard_bridge 4244 4245 4246
socat -u /dev/ttyAMA0,raw,echo=0,b115200 udp-sendto:127.0.0.1:4246
*/

#include <sys/time.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "libbridge.h"

// from messages.xml
#define ALT_UNIT_COEF_ATT 0.0139882
#define ALT_UNIT_COEF_GYR 57.29578

#define CLASS_TELEMETRY 1
#define CLASS_DATALINK 2

#define MAX_COMMANDS  10
#define MAX_ACTUATORS 10

#define IMUPIPE "/tmp/fromimu"
float msgpipe_g[3];
int imufd;

struct ping_t {struct timeval stamp;} ping_g;
struct rgps_t {struct timeval stamp; uint8_t pad; float x; float y; float z;
  float xd; float yd; float zd; uint32_t tow; float course;} rgps_g;
struct att_t {struct timeval stamp; float phi;float theta; float psi;} att_g;
struct gps_t {struct timeval stamp; uint8_t mode; int32_t utm_east; 
	        int32_t utm_north; int16_t course; int32_t alt; uint16_t speed;
                int16_t climb; uint16_t week; uint32_t itow; uint8_t utm_zone;
                uint8_t gps_nb_err;} gps_g;
struct mde_t {struct timeval stamp; uint8_t ap_mode; uint8_t ap_gaz; uint8_t ap_lateral;
	        uint8_t ap_horizontal; uint8_t if_calib_mode; uint8_t mcu1_status;} mde_g;
struct des_t {struct timeval stamp; float roll; float pitch; float course;
	        float x; float y; float altitude; float climb; float airspeed;} des_g;
struct cmd_t {struct timeval stamp; uint8_t nbvalues;int16_t values[MAX_COMMANDS];} cmd_g;
struct act_t {struct timeval stamp; uint8_t nbvalues;int16_t values[MAX_ACTUATORS];} act_g;
struct rfp_t {struct timeval stamp; float phi;float theta; float psi;} rfp_g;
struct gyr_t {struct timeval stamp; float gp;float gq; float gr;} gyr_g;
struct mag_t {struct timeval stamp; float mx;float my; float mz;} mag_g;
struct acc_t {struct timeval stamp; float ax;float ay; float az;} acc_g;


void main(int argc, char **argv) {
  if((argc<3)||(argc>4)) {
    printf("muxer 4244 4245\n");
    printf("muxer 4244 4245 4246\n");
  } else {
    if(muxlib_init(argc,argv)==0) {

      mkfifo(IMUPIPE, 0666); 
      imufd = open(IMUPIPE, O_RDWR | O_NONBLOCK);

      int ret=0;
      struct timeval tv;
      unsigned long start;float elapsed;
      uint8_t buf[PPRZSIZE];
      uint8_t acid,classid,msgid,bufsize;
      uint8_t index;float value;
      char str[(MAX_COMMANDS > MAX_ACTUATORS) ? MAX_COMMANDS : MAX_ACTUATORS];
      uint8_t len;uint16_t *ptr;

      gettimeofday(&tv,NULL);
      start = ((tv.tv_sec * 1000000) + tv.tv_usec);

      while(ret>=0) {
    
        ret = muxlib_check_and_parse(&classid,&msgid,&bufsize,buf);
    
        if (ret>0) {

          gettimeofday(&tv, NULL);
          elapsed = (((tv.tv_sec * 1000000) + tv.tv_usec) - start)/1000000.0;
	  if(classid == CLASS_DATALINK) {

            if (msgid == PPRZ_MSG_ID_PING) {
              memcpy(&(ping_g.stamp),&tv,sizeof(struct timeval));
              printf("%.4f 0 PING\n",elapsed);
  	    }
  	 
            if (msgid == PPRZ_MSG_ID_SETTING) {
              index=pprzlink_get_SETTING_index(buf);
  	      if (index==6) {
                value=pprzlink_get_SETTING_value(buf);
  	        if(value==19.0) {  // GUIDED_MODE
  		  // goto to a position relative to current position and heading in meters
                  muxlib_send_GUIDED_SETPOINT_NED(pprzlink_get_SETTING_ac_id(buf),0x0E,1.0,0.0,0.0,0.0);
		}
  	      }
  	    }
  
            if (msgid == PPRZ_MSG_ID_REMOTE_GPS_LOCAL) {
              memcpy(&(rgps_g.stamp),&tv,sizeof(struct timeval));
              acid          = pprzlink_get_REMOTE_GPS_LOCAL_ac_id(buf);
              rgps_g.pad    = pprzlink_get_REMOTE_GPS_LOCAL_pad(buf);
              rgps_g.x      = pprzlink_get_REMOTE_GPS_LOCAL_enu_x(buf);
              rgps_g.y      = pprzlink_get_REMOTE_GPS_LOCAL_enu_y(buf);
              rgps_g.z      = pprzlink_get_REMOTE_GPS_LOCAL_enu_z(buf);
              rgps_g.xd     = pprzlink_get_REMOTE_GPS_LOCAL_enu_xd(buf);
              rgps_g.yd     = pprzlink_get_REMOTE_GPS_LOCAL_enu_yd(buf);
              rgps_g.zd     = pprzlink_get_REMOTE_GPS_LOCAL_enu_zd(buf);
              rgps_g.tow    = pprzlink_get_REMOTE_GPS_LOCAL_tow(buf);
              rgps_g.course = pprzlink_get_REMOTE_GPS_LOCAL_course(buf);
              printf("%.4f %d REMOTE_GPS_LOCAL %d %f %f %f %f %f %f %d %f\n",elapsed,acid,
                     rgps_g.pad,rgps_g.x,rgps_g.y,rgps_g.z,rgps_g.xd,rgps_g.yd,rgps_g.zd,
                     rgps_g.tow,rgps_g.course);
            }
	  }
	  if(classid == CLASS_TELEMETRY) {
            if (msgid == PPRZ_MSG_ID_ATTITUDE) {
      	      memcpy(&(att_g.stamp),&tv,sizeof(struct timeval));
              att_g.phi   = pprzlink_get_ATTITUDE_phi(buf);
              att_g.psi   = pprzlink_get_ATTITUDE_psi(buf);
              att_g.theta = pprzlink_get_ATTITUDE_theta(buf);
  	      acid = buf[0];
              printf("%.4f %d ATTITUDE %f %f %f\n",elapsed,acid,att_g.phi,att_g.psi,att_g.theta); 
  	    }
  	  
            if (msgid == PPRZ_MSG_ID_GPS) {
      	      memcpy(&(gps_g.stamp),&tv,sizeof(struct timeval));
              gps_g.mode       = pprzlink_get_GPS_mode(buf);
              gps_g.utm_east   = pprzlink_get_GPS_utm_east(buf);
              gps_g.utm_north  = pprzlink_get_GPS_utm_north(buf);
              gps_g.course     = pprzlink_get_GPS_course(buf);
              gps_g.alt        = pprzlink_get_GPS_alt(buf);
              gps_g.speed      = pprzlink_get_GPS_speed(buf);
              gps_g.climb      = pprzlink_get_GPS_climb(buf);
              gps_g.week       = pprzlink_get_GPS_week(buf);
              gps_g.itow       = pprzlink_get_GPS_itow(buf);
              gps_g.utm_zone   = pprzlink_get_GPS_utm_zone(buf);
              gps_g.gps_nb_err = pprzlink_get_GPS_gps_nb_err(buf);
  	      acid = buf[0];
              printf("%.4f %d GPS %d %d %d %d %d %d %d %d %d %d %d\n",elapsed,acid,
                      gps_g.mode,gps_g.utm_east,gps_g.utm_north,gps_g.course,gps_g.alt,
  		    gps_g.speed,gps_g.climb,gps_g.week,gps_g.itow,gps_g.utm_zone,gps_g.gps_nb_err);
  	    } 
  
            if (msgid == PPRZ_MSG_ID_PPRZ_MODE) {
      	      memcpy(&(mde_g.stamp),&tv,sizeof(struct timeval));
              mde_g.ap_mode       = pprzlink_get_PPRZ_MODE_ap_mode(buf);
              mde_g.ap_gaz        = pprzlink_get_PPRZ_MODE_ap_gaz(buf);
              mde_g.ap_lateral    = pprzlink_get_PPRZ_MODE_ap_lateral(buf);
              mde_g.ap_horizontal = pprzlink_get_PPRZ_MODE_ap_horizontal(buf);
              mde_g.if_calib_mode = pprzlink_get_PPRZ_MODE_if_calib_mode(buf);
              mde_g.mcu1_status   = pprzlink_get_PPRZ_MODE_mcu1_status(buf);
  	      acid = buf[0];
              printf("%.4f %d PPRZ_MODE %d %d %d %d %d %d",elapsed,acid,
                      mde_g.ap_mode,mde_g.ap_gaz,mde_g.ap_lateral,mde_g.ap_horizontal,
  		      mde_g.if_calib_mode,mde_g.mcu1_status);
            }
  
            if (msgid == PPRZ_MSG_ID_DESIRED) {
      	      memcpy(&(des_g.stamp),&tv,sizeof(struct timeval));
              des_g.roll     = ALT_UNIT_COEF_GYR*pprzlink_get_DESIRED_roll(buf);
              des_g.pitch    = ALT_UNIT_COEF_GYR*pprzlink_get_DESIRED_pitch(buf);
              des_g.course   = ALT_UNIT_COEF_GYR*pprzlink_get_DESIRED_course(buf);
              des_g.x        = pprzlink_get_DESIRED_x(buf);
              des_g.y        = pprzlink_get_DESIRED_y(buf);
              des_g.altitude = pprzlink_get_DESIRED_altitude(buf);
              des_g.climb    = pprzlink_get_DESIRED_climb(buf);
              des_g.airspeed = pprzlink_get_DESIRED_airspeed(buf);
  	      acid = buf[0];
              printf("%.4f %d DESIRED %f %f %f %f %f %f %f %f\n",elapsed,acid,
  	            des_g.roll,des_g.pitch,des_g.course,des_g.x,des_g.y,des_g.altitude,
  		    des_g.climb, des_g.airspeed);
  	    }
  
            if (msgid == PPRZ_MSG_ID_COMMANDS) {
      	      memcpy(&(cmd_g.stamp),&tv,sizeof(struct timeval));
              cmd_g.nbvalues = pprzlink_get_COMMANDS_values_length(buf);
  	      ptr=pprzlink_get_COMMANDS_values(buf);
  	      for(int nb=0;nb<cmd_g.nbvalues;nb++) {
  	        if(nb!=0) str[len++]=',';else len=0;
  	        memcpy(&cmd_g.values[nb],ptr,sizeof(int16_t));
  	        ptr+=sizeof(int16_t);
  	        len += sprintf(str+len,"%d",cmd_g.values[nb]);
  	      }
              printf("%.4f %d COMMANDS %s\n",elapsed,acid,str);
  	    }
  
            if (msgid == PPRZ_MSG_ID_ACTUATORS) {
      	      memcpy(&(act_g.stamp),&tv,sizeof(struct timeval));
              act_g.nbvalues = pprzlink_get_ACTUATORS_values_length(buf);
  	      ptr=pprzlink_get_ACTUATORS_values(buf);
  	      for(int nb=0;nb<act_g.nbvalues;nb++) {
  	        if(nb!=0) str[len++]=',';else len=0;
  	        memcpy(&act_g.values[nb],ptr,sizeof(int16_t));
  	        ptr+=sizeof(int16_t);
  	        len += sprintf(str+len,"%d",act_g.values[nb]);
  	      }
              printf("%.4f %d ACTUATORS %s\n",elapsed,acid,str);
  	    }
            if (msgid == PPRZ_MSG_ID_ROTORCRAFT_FP) {
      	      memcpy(&(rfp_g.stamp),&tv,sizeof(struct timeval));
              rfp_g.phi  =ALT_UNIT_COEF_ATT*pprzlink_get_ROTORCRAFT_FP_phi(buf);
              rfp_g.theta=ALT_UNIT_COEF_ATT*pprzlink_get_ROTORCRAFT_FP_theta(buf);
              rfp_g.psi  =ALT_UNIT_COEF_ATT*pprzlink_get_ROTORCRAFT_FP_psi(buf);
  	      acid = buf[0];
              printf("%.4f %d ROTORCRAFT_FP %f %f %f\n",elapsed,acid,rfp_g.phi,rfp_g.theta,rfp_g.psi); 

              msgpipe_g[0]=rfp_g.phi; msgpipe_g[1]=rfp_g.theta; msgpipe_g[2] = rfp_g.psi;
              write(imufd, &msgpipe_g, sizeof(msgpipe_g));
            }
            if (msgid == PPRZ_MSG_ID_IMU_GYRO) {
      	      memcpy(&(gyr_g.stamp),&tv,sizeof(struct timeval));
              gyr_g.gp  =ALT_UNIT_COEF_GYR*pprzlink_get_IMU_GYRO_gp((uint8_t *)&buf);
              gyr_g.gq  =ALT_UNIT_COEF_GYR*pprzlink_get_IMU_GYRO_gq((uint8_t *)&buf);
              gyr_g.gr  =ALT_UNIT_COEF_GYR*pprzlink_get_IMU_GYRO_gr((uint8_t *)&buf);
  	      acid = buf[0];
              printf("%.4f %d IMU_GYRO %f %f %f\n",elapsed,acid,gyr_g.gp,gyr_g.gq,gyr_g.gr); 
            }
  
            if (msgid == PPRZ_MSG_ID_IMU_MAG) {
      	      memcpy(&(mag_g.stamp),&tv,sizeof(struct timeval));
              mag_g.mx  =pprzlink_get_IMU_MAG_mx((uint8_t *)&buf);
              mag_g.my  =pprzlink_get_IMU_MAG_my((uint8_t *)&buf);
              mag_g.mz  =pprzlink_get_IMU_MAG_mz((uint8_t *)&buf);
  	      acid = buf[0];
              printf("%.4f %ld IMU_MAG %f %f %f\n",elapsed,acid,mag_g.mx,mag_g.my,mag_g.mz); 
  	    }
  
            if (msgid == PPRZ_MSG_ID_IMU_ACCEL) {
      	      memcpy(&(acc_g.stamp),&tv,sizeof(struct timeval));
      	      acc_g.stamp.tv_sec = tv.tv_sec; acc_g.stamp.tv_usec=tv.tv_usec;
              acc_g.ax  =pprzlink_get_IMU_GYRO_gp((uint8_t *)&buf);
              acc_g.ay  =pprzlink_get_IMU_GYRO_gq((uint8_t *)&buf);
              acc_g.az  =pprzlink_get_IMU_GYRO_gr((uint8_t *)&buf);
  	      acid = buf[0];
              printf("%.4f %ld IMU_ACCEL %f %f %f\n",elapsed,acid,acc_g.ax,acc_g.ay,acc_g.az); 
            }
          }
        }
      }
    }
  }
}

