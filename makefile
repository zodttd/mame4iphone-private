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
CC = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.2.1
CPP = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.2.1
LD = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.2.1
ASM = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.2.1
MD = @mkdir
RM = @rm -f

GPLIBS = 
INCLUDES = 

ifdef DEBUG
TARGET = $(TARGET)d
endif

OBJ = obj

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

# -DWITH_ADS=1 
CFLAG_DEFINES = -DWITH_ADS=1 -DLSB_FIRST=1
CFLAG_DEFINES += -DALIGN_INTS=1
CFLAG_DEFINES += -DINLINE="static __inline"
CFLAG_DEFINES += -Dasm="__asm__ __volatile__" 
CFLAG_DEFINES += -DGP2X=1
CFLAG_DEFINES += -DMAME_UNDERCLOCK=1 
CFLAG_DEFINES += -DMAME_FASTSOUND=1
CFLAG_DEFINES += -DENABLE_AUTOFIRE=1 

CFLAGS	= -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.2.1.sdk/System/Library/Frameworks -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.2.1.sdk/System/Library/PrivateFrameworks -I./ -I./Classes/ -I./Classes/AdMob/ -I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.1.2.sdk/usr/lib/gcc/arm-apple-darwin9/4.2.1/include -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.2.1.sdk  -L/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.2.1.sdk/usr/lib -march=armv6 -DARM_ARCH -DGP2X_BUILD -miphoneos-version-min=2.2.1 -O3 -ffast-math -ftemplate-depth-36 -mstructure-size-boundary=32 -falign-functions=32 -falign-loops -falign-labels -falign-jumps -finline -finline-functions -fno-builtin -fno-common -fomit-frame-pointer -L./Classes/AdMob/ -L./Classes/AdMob/ARM/ -Isrc/ -Isrc/gp2x/ 


LIBS = 

OBJDIRS = $(OBJ) $(OBJ)/cpu $(OBJ)/sound $(OBJ)/$(MAMEOS) \
	$(OBJ)/drivers $(OBJ)/machine $(OBJ)/vidhrdw $(OBJ)/sndhrdw 

all:	maketree $(EMULATOR)

# include the various .mak files
include src/core.mak
include src/$(TARGET).mak
include src/rules.mak
include src/sound.mak
include src/$(MAMEOS)/$(MAMEOS).mak

ifdef DEBUG
DBGDEFS = -DMAME_DEBUG
else
DBGDEFS =
DBGOBJS =
endif

# combine the various definitions to one
CDEFS = $(DEFS) $(COREDEFS) $(CPUDEFS) $(SOUNDDEFS) $(ASMDEFS) $(DBGDEFS) $(CFLAG_DEFINES) 

$(EMULATOR): $(OBJS) $(COREOBJS) $(OSOBJS) $(DRVOBJS)
	$(LD) $(CDEFS) $(CFLAGS) $(LDFLAGS) $(OBJS) $(COREOBJS) $(OSOBJS) $(LIBS) $(DRVOBJS) -o $@

$(OBJ)/%.o: src/%.c
	@echo Compiling $<...
	$(CC) $(CDEFS) $(CFLAGS) -c $< -o $@

$(OBJ)/%.o: src/%.cpp
	@echo Compiling $<...
	$(CPP) $(CDEFS) $(CFLAGS) -c $< -o $@

%.o: %.cpp
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
