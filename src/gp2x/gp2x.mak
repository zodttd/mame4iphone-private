# CPUDEFS += -DHAS_CYCLONE=1 -DHAS_DRZ80=1
# OBJDIRS += $(OBJ)/cpu/m68000_cyclone $(OBJ)/cpu/z80_drz80
# CPUOBJS += $(OBJ)/cpu/m68000_cyclone/cyclone.o $(OBJ)/cpu/m68000_cyclone/c68000.o $(OBJ)/cpu/z80_drz80/drz80.o $(OBJ)/cpu/z80_drz80/drz80_z80.o

OSOBJS = $(OBJ)/gp2x/minimal.o \
	$(OBJ)/gp2x/gp2x.o $(OBJ)/gp2x/video.o $(OBJ)/gp2x/blit.o \
	$(OBJ)/gp2x/sound.o $(OBJ)/gp2x/input.o $(OBJ)/gp2x/fileio.o \
	$(OBJ)/gp2x/config.o $(OBJ)/gp2x/fronthlp.o \
	./main.o ./NowPlayingController.o ./Classes/helpers.o   ./Classes/OptionsController.o ./Classes/RecentController.o ./Classes/RomController.o ./Classes/SaveStatesController.o ./Classes/ShoutOutAppDelegate.o ./Classes/SOApplication.o ./Classes/TabBar.o ./Classes/AdMob/AltAds.o
