CC   := gcc
CXX  := g++
ASM := sjasmplus
ECHO := echo
SALVADOR := salvador

BIN_NAME = UP24

CCFLAGS := -W -Wall
ASMFLAGS := --nologo

ALL = cge2bin bin2m12 buildframe up24.bin up24.m12

all: $(ALL)

cge2bin: tools/cge2bin.c
	@$(ECHO) "CC    $@"
	@$(CC) $(CCFLAGS) -o $@ $^

bin2m12: tools/bin2m12.c
	@$(ECHO) "CC    $@"
	@$(CC) $(CCFLAGS) -o $@ $^

buildframe: tools/buildframe.c
	@$(ECHO) "CC    $@"
	@$(CC) $(CCFLAGS) -o $@ $^

bounce: tools/bounce.c
	@$(ECHO) "CC    $@"
	@$(CC) $(CCFLAGS) -o $@ $^
	@./bounce

music:
	@$(ECHO) "PROCESS    $@"
	@$(SALVADOR) -classic ./data/music.akl music.zx0

frames: buildframe
	@$(ECHO) "CREATING $@"
	@make -f data/anim.mk INDIR=./data/stripes OUTDIR=./_data/stripes
	@make -f data/anim.mk INDIR=./data/anim OUTDIR=./_data/anim
	@make -f data/anim.mk INDIR=./data/welcome OUTDIR=./_data/welcome

%.bin: %.asm frames music bounce
	@$(ECHO) "ASM	$@"
	@$(ASM) $(ASMFLAGS) $< --raw=$@ --sym=$(addsuffix .sym, $@)

%.m12: %.bin bin2m12
	@$(ECHO) "M12	$@"
	@./bin2m12 $< $@ $(BIN_NAME)

clean:
	@$(ECHO) "CLEANING UP..."
	@rm -rf bin2m12 *.sym *.m12 *.bin *.zx0 _data
#	@find . -name "*.o" -exec rm -f {} \;
