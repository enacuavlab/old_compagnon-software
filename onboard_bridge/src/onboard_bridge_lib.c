#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <stdlib.h>
#include <stdbool.h>

#include <signal.h>
#include <stdio.h>
#include <string.h>

#include "muxlib.h"

#define BUFFSIZE 512

/*

cc -g -fPIC -shared muxer/src/muxlib.c -o muxer/lib/libmux.so -I/home/pi/muxer/inc -I/home/pi/pprzlink/build

*/

typedef struct {
  struct pprzlink_device_tx dev;
  char msg[PPRZSIZE+1];
  int bufcpt;
} tx_t;

typedef struct {
  struct pprzlink_device_rx dev;
  char msg[PPRZSIZE+1];
  char buf[BUFFSIZE+1];
  int bufcpt;
  int bufstr;
} rx_t;

typedef struct {
  struct sockaddr_in addr;
  int fd;
  tx_t tx;
  rx_t rx;
} stream_t;
stream_t streams[3];

sigset_t orig_mask;
uint8_t nbfdin=0,nbmax=0,current=0;

/*****************************************************************************/
void muxlib_send_GUIDED_SETPOINT_NED(uint8_t acid, uint8_t flags, float x, float y, float z, float yaw) {
  stream_t *ptr = &streams[0];
  uint8_t _acid=acid;
  uint8_t _flags=flags;
  float _x=x;float _y=y;float _z=z;float _yaw=yaw;
  pprzlink_msg_send_GUIDED_SETPOINT_NED(&(ptr->tx.dev), 0, 0, &_acid, &_flags, &_x, &_y, &_z, &_yaw);
  int len=sendto(ptr->fd, &(ptr->tx.msg), ptr->tx.bufcpt, 0,(struct sockaddr *)&(ptr->addr), sizeof(ptr->addr));
  printf("sent %d\n",len);
}

/*****************************************************************************/
uint8_t tx_check_space(uint8_t n) {if(n<(BUFFSIZE - streams[0].tx.bufcpt)) return true; else return false;}
void tx_put_char(uint8_t c) {streams[0].tx.msg[(streams[0].tx.bufcpt)++]=c;}

/*****************************************************************************/
int rx_char_available(void) {
  struct sockaddr_in addr;
  socklen_t addrlen = sizeof(addr);

  stream_t *ptr = &streams[current];
  if(ptr->rx.bufstr == 0) {
    ptr->rx.bufstr = recvfrom(ptr->fd, &(ptr->rx.buf),sizeof(ptr->rx.buf), 0, 
		                 (struct sockaddr *)&addr, &addrlen);
    ptr->rx.bufcpt=0;
  }
  return((ptr->rx.bufcpt)<(ptr->rx.bufstr));
}

/*****************************************************************************/
uint8_t rx_get_char(void) {
  return(streams[current].rx.buf[(streams[current].rx.bufcpt)++]);
}

/*****************************************************************************/
int muxlib_check_and_parse(uint8_t* classid,uint8_t* msgid, uint8_t* bufsize, uint8_t *buf) {
  int ret=0;
  uint8_t nready=0,cpt=0;
  fd_set rset; 
  stream_t *ptr;

  FD_ZERO(&rset);
  for(cpt=1;cpt<nbfdin;cpt++) FD_SET(streams[cpt].fd, &rset); 

  nready = select(nbmax+1, &rset, NULL, NULL, NULL); 
//nready = pselect(sock+1, &rset, NULL, NULL, NULL,&orig_mask); 

  for(cpt=1;cpt<nbfdin;cpt++) {
    if(FD_ISSET(streams[cpt].fd, &rset)) {
      current=cpt;
      ptr=&streams[current];
      ptr->rx.bufstr=0;
      while (ptr->rx.dev.char_available()) {
        pprzlink_parse(&(ptr->rx.dev), ptr->rx.dev.get_char());
        if (ptr->rx.dev.msg_received) {
          *classid = ptr->rx.dev.payload[2];
          *msgid   = ptr->rx.dev.payload[3];
  	  *bufsize = ptr->rx.dev.payload_len;
  	  memcpy(buf,ptr->rx.dev.payload,ptr->rx.dev.payload_len);
          ptr->rx.dev.msg_received = false;
  	  ret=1;
        }
      }
    }
  }
  return(ret);
}

/*****************************************************************************/
int muxlib_init(int argc, char **argv) {
  uint8_t ret=0,cpt=0;
  int optval = 1;
  sigset_t mask;
  stream_t *ptr;

//  sigemptyset (&mask);
//  sigaddset (&mask, SIGTERM);
//  sigprocmask(SIG_BLOCK, &mask, &orig_mask);


  while(ret==0&&(cpt<(argc-1))) {
    ptr=&streams[cpt];
    ptr->fd = socket(AF_INET, SOCK_DGRAM, 0);
    if(ptr->fd > 0) {

      memset((char *)&(ptr->addr), 0, sizeof(ptr->addr));
      ptr->addr.sin_family = AF_INET;
      ptr->addr.sin_port = htons(atoi(argv[cpt+1]));

      if(cpt!=0) {

	setsockopt(ptr->fd, SOL_SOCKET, SO_REUSEADDR,(const void *)&optval, sizeof(int));
        ptr->addr.sin_addr.s_addr = inet_addr("127.0.0.1");
        ret=bind(ptr->fd, (struct sockaddr *)&(ptr->addr), sizeof(ptr->addr));

        if(ret==0) {
          ptr->rx.bufcpt=0;
          ptr->rx.bufstr=0;
          ptr->rx.dev = pprzlink_device_rx_init(rx_char_available, rx_get_char,
			                        (uint8_t *)(ptr->rx.msg), (void *)0);
        }
      } else {
        ptr->addr.sin_addr.s_addr = htonl(INADDR_ANY);
        ptr->tx.dev = pprzlink_device_tx_init((check_space_t)tx_check_space, tx_put_char, NULL);
      }
    } else ret=-1;
    cpt++;
  }
  nbfdin = argc-1;
  for(cpt=1;cpt<nbfdin;cpt++) {if(nbmax < streams[cpt].fd) nbmax=streams[cpt].fd;}

  return(ret);
}
