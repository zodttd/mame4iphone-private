#ifndef _ICONTROLPAD_H_
#define _ICONTROLPAD_H_

#if 1
#define CP_DOWN         (1<<13)
#define CP_UP           (1<<0)
#define CP_Y            (1<<3)
#define CP_X            (1<<5)
#define CP_R_SHOULDER   (1<<6)
#define CP_A            (1<<4)
#define CP_LEFT         (1<<1)
#define CP_START        (1<<14)
#define CP_L_SHOULDER   (1<<10)
#define CP_RIGHT        (1<<15)
#define CP_SELECT       (1<<7)
#define CP_B            (1<<2)
#else
#define CP_R_SHOULDER	  (1<<11)
#define CP_L_SHOULDER	  (1<<6)
#define CP_RIGHT		    (1<<5)
#define CP_A		        (1<<10) 
#define CP_A2		        (1<<8) /* LOW */
#define CP_B		        (1<<0)
#define CP_Y		        (1<<13)
#define CP_X		        (1<<12)
#define CP_SELECT		    (1<<4)
#define CP_START		    (1<<7)
#define CP_DOWN		      (1<<15)
#define CP_UP		        (1<<14)
#define CP_LEFT		      (1<<10)
#define CP_LEFT2		    (1<<8) /* HIGH */
#endif

enum {CMD_NOP,CMD_INIT,CMD_IDLE,CMD_TX,CMD_READKEYPAD,CMD_STATUS,CMD_SERIALINIT,BUSY,NOT_BUSY,INIT_FAILED,CMD_DEINIT};

#ifdef __cplusplus
extern "C" {
#endif
	
int THREAD_Init_iControlPad();
int Cmd_iControlPad(int cmd_type);
int DoCommand(int cmd_type);

#ifdef __cplusplus
}
#endif
	
#endif
