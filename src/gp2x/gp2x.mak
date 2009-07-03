CPUDEFS += -DHAS_CYCLONE=1
OBJDIRS += $(OBJ)/cpu/m68000_cyclone

CPUDEFS += -DHAS_DRZ80=1
OBJDIRS += $(OBJ)/cpu/z80_drz80

$(OBJ)/zlib/zlib.a: \
	$(OBJ)/zlib/adler32.o $(OBJ)/zlib/compress.o $(OBJ)/zlib/crc32.o \
	$(OBJ)/zlib/gzio.o $(OBJ)/zlib/uncompr.o $(OBJ)/zlib/deflate.o \
	$(OBJ)/zlib/trees.o $(OBJ)/zlib/zutil.o $(OBJ)/zlib/inflate.o \
	$(OBJ)/zlib/infback.o $(OBJ)/zlib/inftrees.o $(OBJ)/zlib/inffast.o

DRVLIBS += $(OBJ)/zlib/zlib.a

OSOBJS = $(OBJ)/gp2x/minimal.o $(OBJ)/gp2x/uppermem.o $(OBJ)/gp2x/cpuctrl.o \
	$(OBJ)/gp2x/squidgehack.o $(OBJ)/gp2x/flushcache.o \
	$(OBJ)/gp2x/memcmp.o $(OBJ)/gp2x/memcpy.o $(OBJ)/gp2x/memset.o \
	$(OBJ)/gp2x/strcmp.o $(OBJ)/gp2x/strlen.o $(OBJ)/gp2x/strncmp.o \
	$(OBJ)/gp2x/gp2x.o $(OBJ)/gp2x/video.o $(OBJ)/gp2x/blit.o \
	$(OBJ)/gp2x/sound.o $(OBJ)/gp2x/input.o $(OBJ)/gp2x/fileio.o \
	$(OBJ)/gp2x/usbjoy.o $(OBJ)/gp2x/usbjoy_mame.o \
	$(OBJ)/gp2x/config.o $(OBJ)/gp2x/fronthlp.o \
	$(OBJ)/cpu/m68000_cyclone/c68000.o $(OBJ)/cpu/m68000_cyclone/cyclone.o \
	$(OBJ)/cpu/z80_drz80/drz80_z80.o $(OBJ)/cpu/z80_drz80/drz80.o

mame.gpe:
	$(LD) $(LDFLAGS) src/gp2x/cpuctrl.cpp \
		src/gp2x/flushcache.s src/gp2x/minimal.cpp \
		src/gp2x/squidgehack.cpp src/gp2x/usbjoy.cpp \
		src/gp2x/usbjoy_mame.cpp src/gp2x/uppermem.cpp \
		src/gp2x/gp2x_frontend.cpp $(LIBS) -o $@
