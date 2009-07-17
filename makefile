TARGET = mame
# TARGET = mess
# TARGET = neomame
# TARGET = tiny

# uncomment next line to include the debugger
# DEBUG = 1

# set this the operating system you're building for
# (actually you'll probably need your own main makefile anyways)
# MAMEOS = msdos
MAMEOS = gp2x

# extension for executables
# EXE = .exe
EXE =

# CPU core include paths
VPATH=src $(wildcard src/cpu/*)

# compiler, linker and utilities
AR = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-ar
CC = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.0.1
CPP = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
LD = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
ASM = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.0.1
MD = @mkdir
RM = @rm -f

GPLIBS = 
INCLUDES = 

ifdef DEBUG
TARGET = $(TARGET)d
endif

OBJ = obj/$(NAME)

EMULATOR = $(TARGET)$(EXE)

LDFLAGS = -lobjc \
	        -lpthread \
          -framework CoreFoundation \
          -framework Foundation \
          -framework UIKit \
          -framework QuartzCore \
          -framework CoreGraphics \
          -framework CoreSurface \
          -framework CoreLocation \
          -framework AudioToolbox \
          -framework GraphicsServices \
          -lz \
          -framework AddressBook -lAdMobDeviceNoThumb3_0 -lsqlite3 -framework SystemConfiguration 

CFLAG_DEFINES = -DWITH_ADS=1 -DLSB_FIRST=1
CFLAG_DEFINES += -DALIGN_INTS=1
CFLAG_DEFINES += -DINLINE="static __inline"
CFLAG_DEFINES += -Dasm="__asm__ __volatile__" 
CFLAG_DEFINES += -DGP2X=1
CFLAG_DEFINES += -DMAME_UNDERCLOCK=1 
CFLAG_DEFINES += -DMAME_FASTSOUND=1
CFLAG_DEFINES += -DENABLE_AUTOFIRE=1 
CFLAG_DEFINES += -DHAS_QSOUND=1 
CFLAG_DEFINES += -DHAS_C140=1 
CFLAG_DEFINES += -DHAS_CEM3394=1 
CFLAG_DEFINES += -DHAS_RF5C68=1
CFLAG_DEFINES += -DHAS_SEGAPCM=1 
CFLAG_DEFINES += -DHAS_K053260=1 
CFLAG_DEFINES += -DHAS_K051649=1 
CFLAG_DEFINES += -DHAS_K007232=1 
CFLAG_DEFINES += -DHAS_K005289=1 
CFLAG_DEFINES += -DHAS_HC55516=1 
CFLAG_DEFINES += -DHAS_UPD7759=1 
CFLAG_DEFINES += -DHAS_MSM5205=1 
CFLAG_DEFINES += -DHAS_OKIM6295=1 
CFLAG_DEFINES += -DHAS_ADPCM=1 
CFLAG_DEFINES += -DHAS_VLM5030=1 
CFLAG_DEFINES += -DHAS_TMS5220=1 
CFLAG_DEFINES += -DHAS_TMS36XX=1 
CFLAG_DEFINES += -DHAS_NAMCO=1 
CFLAG_DEFINES += -DHAS_ASTROCADE=1 
CFLAG_DEFINES += -DHAS_NES=1 
CFLAG_DEFINES += -DHAS_POKEY=1 
CFLAG_DEFINES += -DHAS_SN76496=1 
CFLAG_DEFINES += -DHAS_SN76477=1 
CFLAG_DEFINES += -DHAS_Y8950=1 
CFLAG_DEFINES += -DHAS_YM3526=1 
CFLAG_DEFINES += -DHAS_YM3812=1 
CFLAG_DEFINES += -DHAS_YM2413=1 
CFLAG_DEFINES += -DHAS_YM3438=1 
CFLAG_DEFINES += -DHAS_YM2612=1 
CFLAG_DEFINES += -DHAS_YM2610B=1 
CFLAG_DEFINES += -DHAS_YM2610=1 
CFLAG_DEFINES += -DHAS_YM2608=1 
CFLAG_DEFINES += -DHAS_YM2151_ALT=1
CFLAG_DEFINES += -DHAS_YM2203=1 
CFLAG_DEFINES += -DHAS_AY8910=1 
CFLAG_DEFINES += -DHAS_DAC=1 
CFLAG_DEFINES += -DHAS_SAMPLES=1 
CFLAG_DEFINES += -DHAS_MIPS=1 
CFLAG_DEFINES += -DHAS_ADSP2105=1 
CFLAG_DEFINES += -DHAS_ADSP2100=1 
CFLAG_DEFINES += -DHAS_CCPU=1 
CFLAG_DEFINES += -DHAS_TMS320C10=1 
CFLAG_DEFINES += -DHAS_Z8000=1 
CFLAG_DEFINES += -DHAS_TMS9980=1 
CFLAG_DEFINES += -DHAS_TMS34010=1 
CFLAG_DEFINES += -DHAS_S2650=1 
CFLAG_DEFINES += -DHAS_T11=1 
CFLAG_DEFINES += -DHAS_M68000=1 
CFLAG_DEFINES += -DHAS_KONAMI=1 
CFLAG_DEFINES += -DHAS_M6809=1 
CFLAG_DEFINES += -DHAS_HD6309=1 
CFLAG_DEFINES += -DHAS_HD63705=1 
CFLAG_DEFINES += -DHAS_M68705=1 
CFLAG_DEFINES += -DHAS_M6805=1 
CFLAG_DEFINES += -DHAS_NSC8105=1 
CFLAG_DEFINES += -DHAS_HD63701=1 
CFLAG_DEFINES += -DHAS_M6808=1 
CFLAG_DEFINES += -DHAS_M6803=1 
CFLAG_DEFINES += -DHAS_M6802=1 
CFLAG_DEFINES += -DHAS_M6801=1 
CFLAG_DEFINES += -DHAS_M6800=1 
CFLAG_DEFINES += -DHAS_N7751=1 
CFLAG_DEFINES += -DHAS_I8048=1 
CFLAG_DEFINES += -DHAS_I8039=1 
CFLAG_DEFINES += -DHAS_I8035=1 
CFLAG_DEFINES += -DHAS_V33=1 
CFLAG_DEFINES += -DHAS_V30=1 
CFLAG_DEFINES += -DHAS_V20=1 
CFLAG_DEFINES += -DHAS_I188=1 
CFLAG_DEFINES += -DHAS_I186=1 
CFLAG_DEFINES += -DHAS_I88=1 
CFLAG_DEFINES += -DHAS_I86=1 
CFLAG_DEFINES += -DHAS_H6280=1 
CFLAG_DEFINES += -DHAS_N2A03=1 
CFLAG_DEFINES += -DHAS_M6510=1 
CFLAG_DEFINES += -DHAS_M7501=1 
CFLAG_DEFINES += -DHAS_M6510=1 
CFLAG_DEFINES += -DHAS_M6510T=1 
CFLAG_DEFINES += -DHAS_M6510=1 
CFLAG_DEFINES += -DHAS_M65SC02=1 
CFLAG_DEFINES += -DHAS_M65C02=1 
CFLAG_DEFINES += -DHAS_M6502=1 
CFLAG_DEFINES += -DHAS_Z80=1 
CFLAG_DEFINES += -DHAS_8080=1 
CFLAG_DEFINES += -DHAS_8085A=1 
CFLAG_DEFINES += -DHAS_M65SC02=1 
CFLAG_DEFINES += -DHAS_M65C02=1 
CFLAG_DEFINES += -DHAS_M6502=1 
CFLAG_DEFINES += -DHAS_Z80=1 
CFLAG_DEFINES += -DHAS_8080=1 
CFLAG_DEFINES += -DHAS_8085A=1 
CFLAG_DEFINES += -DHAS_M6510=1 
CFLAG_DEFINES += -DHAS_M8502=1 
CFLAG_DEFINES += -DHAS_CUSTOM=1 
CFLAG_DEFINES += -DHAS_M68010=1 
CFLAG_DEFINES += -DHAS_YMZ280B=1
CFLAG_DEFINES += -DHAS_M68EC020=1

CFLAGS	= -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk/System/Library/Frameworks -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk/System/Library/PrivateFrameworks -I./ -I./Classes/ -I./Classes/AdMob/ -I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk/usr/lib/gcc/arm-apple-darwin9/4.0.1/include -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk  -L/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.0.sdk/usr/lib -march=armv6 -DARM_ARCH -DGP2X_BUILD -miphoneos-version-min=2.0 -O3 -ffast-math -ftemplate-depth-36 -mstructure-size-boundary=32 -falign-functions=32 -falign-loops -falign-labels -falign-jumps -finline -finline-functions -fno-builtin -fno-common -fomit-frame-pointer -L./Classes/AdMob/ -L./Classes/AdMob/ARM/ -Isrc/ -Isrc/gp2x/ 


LIBS = 

OBJDIRS = obj $(OBJ) $(OBJ)/cpu $(OBJ)/sound $(OBJ)/$(MAMEOS) \
	$(OBJ)/drivers $(OBJ)/machine $(OBJ)/vidhrdw $(OBJ)/sndhrdw 

all:	maketree $(EMULATOR)

# include the various .mak files
include src/core.mak
include src/$(TARGET).mak
include src/rules.mak
include src/$(MAMEOS)/$(MAMEOS).mak

ifdef DEBUG
DBGDEFS = -DMAME_DEBUG
else
DBGDEFS =
DBGOBJS =
endif

# combine the various definitions to one
CDEFS = $(DEFS) $(COREDEFS) $(CPUDEFS) $(SOUNDDEFS) $(ASMDEFS) $(DBGDEFS) $(CFLAG_DEFINES) 

$(EMULATOR): $(OBJS) $(COREOBJS) $(OSOBJS) $(DRVLIBS)
	$(LD) $(CDEFS) $(CFLAGS) $(LDFLAGS) $(OBJS) $(COREOBJS) $(OSOBJS) $(LIBS) $(DRVLIBS) -o $@

$(OBJ)/%.o: src/%.c
	@echo Compiling $<...
	$(CC) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.o: src/%.cpp
	@echo Compiling $<...
	$(CPP) $(CDEFS) $(CFLAGS) -c $< -o $@

%.o: %.m
	@echo Compiling $<...
	$(CC) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.o: src/%.s
	$(CPP) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.o: src/%.S
	$(CPP) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.a:
	$(RM) $@
	$(AR) cr $@ $^

$(sort $(OBJDIRS)):
	$(MD) $@

maketree: $(sort $(OBJDIRS))

clean:
	$(RM) -r $(OBJ)
	$(RM) $(EMULATOR)
