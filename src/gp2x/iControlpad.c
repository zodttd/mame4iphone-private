#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <pthread.h>
#include "iControlpad.h"

//#define DEBUG
#define SKIP_INIT 0

static struct termios gOriginalTTYAttrs;
static unsigned short KeypadData = 0xFFFF; //Buttons are active low
static int COMMAND = CMD_NOP;
static int STATUS = NOT_BUSY;
//static int BAD_CRC = 0;
static FILE* debugfile = NULL;

int iControlPadRead ( int fd, char *data, int numChars);

void iControlPadDebug(char *fmt, ...)
{
  char debugmsg[1024];
	va_list list;

	va_start(list, fmt);
	vsprintf(debugmsg, fmt, list);
	va_end(list);

	debugmsg[1023]=0;

	printf("%s\n", debugmsg);
	fprintf(stderr, "%s", debugmsg);
	
	if(debugfile != NULL)
	{
	  fputs(debugmsg, debugfile);
	  sync();
	}
}

static int OpenSerialPort()
{
    int        fileDescriptor = -1;
    int        handshake;
    struct termios  options;
    
    fileDescriptor = open("/dev/tty.iap", O_RDWR | O_NOCTTY); // TEMP | O_NONBLOCK);
    if (fileDescriptor == -1)
    {
		#ifdef DEBUG
        iControlPadDebug("OpenLink: Error opening serial port %s - %s(%d).\n",
               "/dev/tty.iap", strerror(errno), errno);
		#endif
        goto error;
    }

    if (ioctl(fileDescriptor, TIOCEXCL) == -1)
    {
		#ifdef DEBUG
        iControlPadDebug("OpenLink: Error setting TIOCEXCL on %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
		#endif
        goto error;
    }
// TEMP /*
    if (fcntl(fileDescriptor, F_SETFL, 0) == -1)
    {
		#ifdef DEBUG
        iControlPadDebug("OpenLink: Error clearing O_NONBLOCK %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
		#endif
        goto error;
    }
// TEMP */
    if (tcgetattr(fileDescriptor, &gOriginalTTYAttrs) == -1)
    {
		#ifdef DEBUG
        iControlPadDebug("OpenLink: Error getting tty attributes %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
		#endif
        goto error;
    }

    options = gOriginalTTYAttrs;
    #ifdef DEBUG
    iControlPadDebug("OpenLink: Current input baud rate is %d\n", (int) cfgetispeed(&options));
    iControlPadDebug("OpenLink: Current output baud rate is %d\n", (int) cfgetospeed(&options));
    #endif
    cfmakeraw(&options);
    options.c_cc[VMIN] = 1;
    options.c_cc[VTIME] = 10;
        
    cfsetspeed(&options, B9600);    // Set 9600 baud    
    options.c_cflag |= (CS8);  // RTS flow control of input
      
    #ifdef DEBUG
    iControlPadDebug("OpenLink: Input baud rate changed to %d\n", (int) cfgetispeed(&options));
    iControlPadDebug("OpenLink: Output baud rate changed to %d\n", (int) cfgetospeed(&options));
    #endif
    if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1)
    {
		#ifdef DEBUG
        iControlPadDebug("OpenLink: Error setting tty attributes %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
		#endif
        goto error;
    }    

    // To set the modem handshake lines, use the following ioctls.
    // See tty(4) ("man 4 tty") and ioctl(2) ("man 2 ioctl") for details.
    
    if (ioctl(fileDescriptor, TIOCSDTR) == -1) // Assert Data Terminal Ready (DTR)
    {
  		#ifdef DEBUG
          iControlPadDebug("Error asserting DTR %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
      #endif
    }
    
    if (ioctl(fileDescriptor, TIOCCDTR) == -1) // Clear Data Terminal Ready (DTR)
    {
  		#ifdef DEBUG
          iControlPadDebug("Error clearing DTR %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
      #endif
    }
    
    handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
    if (ioctl(fileDescriptor, TIOCMSET, &handshake) == -1)
    // Set the modem lines depending on the bits set in handshake
    {
  		#ifdef DEBUG
          iControlPadDebug("Error setting handshake lines %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
      #endif
    }
    
    // To read the state of the modem lines, use the following ioctl.
    // See tty(4) ("man 4 tty") and ioctl(2) ("man 2 ioctl") for details.
    
    if (ioctl(fileDescriptor, TIOCMGET, &handshake) == -1)
    // Store the state of the modem lines in handshake
    {
  		#ifdef DEBUG
          iControlPadDebug("Error getting handshake lines %s - %s(%d).\n",
            "/dev/tty.iap", strerror(errno), errno);
      #endif
      
    }
    
		#ifdef DEBUG
        iControlPadDebug("Handshake lines currently set to %d\n", handshake);
    #endif
    
    return fileDescriptor;

error:
    if (fileDescriptor != -1)
    {
        close(fileDescriptor);
    }
    
    return -1;
}

int THREAD_Init_iControlPad() //Call this function once to get it started, then it is always running
{
	int i;
	static char FirstTime = 1; //iPod init sequence only needs to happen one time after power applied
	char response;
	int fd;
	char packet[5];

#ifdef DEBUG
  debugfile = fopen("/Applications/quake4iphone.app/debuglog.txt", "w+");
#endif

	while (1) {
		if (COMMAND == CMD_SERIALINIT) {
      		STATUS = BUSY;
			fd=OpenSerialPort(); // Open tty.iap with no hardware control, 8 bit, BLOCKING and at 9600 baud
			if(fd>-1)
			{
    	#ifdef DEBUG
			  iControlPadDebug("iControlPad serial init'd.\n");
			#endif
				// Check if iControlPad was already init'd.
				
				STATUS = NOT_BUSY;
			}
			else
			{
    	#ifdef DEBUG
			  iControlPadDebug("iControlPad serialinit failed.\n");
			#endif
			  STATUS = INIT_FAILED;
			}
			COMMAND = CMD_NOP;
		}
		else if (COMMAND == CMD_INIT) {
			if(fd>-1) {
				if (FirstTime) {
					STATUS = BUSY;
					FirstTime = 0;
				#ifdef DEBUG
					iControlPadDebug("iControlPad is initing for first time!\n");
					iControlPadDebug("iControlPad serial check.\n");
				#endif
					//write(fd,"?",1);
				#ifdef DEBUG
			  	iControlPadDebug("iControlPad serial written.\n");
				#endif
					//read(fd,&response,1);
				#ifdef DEBUG
					//iControlPadDebug("iControlPad serial read.\n");
        #endif
					//if(response == 'Y')
				  //{
				  //		FirstTime = 0;
				  #ifdef DEBUG
				  //		iControlPadDebug("iControlPad already initialized.\n");
					#endif
					//	STATUS = NOT_BUSY;
					//}
					//else
					{
						if (SKIP_INIT)
							write(fd,"s",1);
						else
							write(fd,"i",1);

						// add 2 second delay here for non-blocking version

						read(fd,&response,1);  //wait until gamepad responds
	
						if (response != 'R') {
						#ifdef DEBUG
						  iControlPadDebug("iControlPad failed to init!\n");
						#endif
							close (fd);
							STATUS = INIT_FAILED;
              break;
						}
						else {
			    	#ifdef DEBUG
							iControlPadDebug("iControlPad successfully initialized.\n");
						#endif
							STATUS = NOT_BUSY;
						}
					}
				}
			#ifdef DEBUG	
				iControlPadDebug("iControlPad init success.\n");
			#endif
				COMMAND = CMD_NOP;
				FirstTime = 0;
			}
			else {
			#ifdef DEBUG
			  iControlPadDebug("iControlPad init failed.\n");
			#endif
				STATUS = INIT_FAILED;
				COMMAND = CMD_NOP;
			}
		}
		else if (COMMAND == CMD_IDLE) {
      if(fd>-1) {
        write(fd,"I",1);
        /*if(BAD_CRC) {
			#ifdef DEBUG
			    //iControlPadDebug("Resending TX command.\n");
			#endif
          COMMAND = CMD_TX;
          BAD_CRC = 0;
        }
        else*/
          COMMAND = CMD_NOP;
      }
		}
		else if (COMMAND == CMD_TX) {
			if(fd>-1) {
			#ifdef DEBUG
			  //iControlPadDebug("Starting packet transmission.\n");
			#endif
				write(fd,"T",1);
				read(fd,&packet[0],5); //get a full packet
				if (packet[0] == 'M' && packet[1] == 'W' ) {
					if ( (packet[2]+packet[3]) == packet[4])
					{
					  KeypadData = (((unsigned char)packet[3])<<8) + (unsigned char)packet[2];
            //KeypadData = ((((unsigned char)packet[2])<<8) + (unsigned char)packet[3]); // | 0x020E;
				  }
				} 
				/*else {
			#ifdef DEBUG
			    //iControlPadDebug("Packet failed.\n");
			#endif
          BAD_CRC = 1;
          COMMAND = CMD_IDLE;
				}*/
			}
			//Don't change mode
			else {
				STATUS = INIT_FAILED;
				COMMAND = CMD_NOP;
			}
		}
    else if (COMMAND == CMD_DEINIT) {
			if (fd > -1)
				close (fd);
      break;
		}
		
    usleep(100);
	}
	
#ifdef DEBUG
  if(debugfile != NULL)
  {
    fputs("DEBUG END", debugfile);
    sync();
    fclose(debugfile);
  }
#endif

	return -1;
}

int DoCommand(int cmd_type) //Call this function to change modes and get current keypad data
{
	if (cmd_type == CMD_READKEYPAD)
	{
    //iControlPadDebug("KeypadData 0x%x\n", KeypadData);
		return KeypadData;
	}
	else if (cmd_type == CMD_STATUS)
	{
	  return STATUS;
	}
	else
	{
		COMMAND = cmd_type;
		return 0;
	}
}

int Cmd_iControlPad(int cmd_type) //Call this function to change modes and get current keypad data
{
  int ret = DoCommand(CMD_STATUS);
  
  if( INIT_FAILED == ret )
  {
  	if (cmd_type == CMD_READKEYPAD)
  	{
  		return KeypadData;
  	}
  	else if (cmd_type == CMD_STATUS)
  	{
  	  return INIT_FAILED;
  	}
  	else
  	{
  		return 0;
  	}
  }
  
  while( NOT_BUSY != ret )
  {
    usleep(1000);
    ret = DoCommand(CMD_STATUS);
  }
  return DoCommand(cmd_type);
}

#define PAD_READ_RESOLUTION 10
#define PAD_READ_WAIT       (3125/(PAD_READ_RESOLUTION))

int iControlPadRead ( int fd, char *data, int numChars)
{
	int timeoutCount = PAD_READ_RESOLUTION;
	int result = -1;
	int numRead;

  if(numChars < 1)
    return result;    // FAIL
    
	while (timeoutCount && numChars)
	{
		numRead = read(fd, data, 1);
		if (numRead > 0)
		{
			numChars --;
			data ++;	
		}
		else
			timeoutCount --;
		usleep(PAD_READ_WAIT);
	}

	if ( !numChars)
		return 1;		//PASS
	else
		return result;	//FAIL
}
