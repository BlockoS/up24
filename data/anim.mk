frames := $(patsubst $(INDIR)/ScreenCharacterData_Layer_0_%.bin, %.bin, $(wildcard $(INDIR)/ScreenCharacterData_Layer_0_*.bin))

all: $(frames)

.PHONY: all

$(OUTDIR):
	@mkdir -p $(OUTDIR)

%.bin: $(OUTDIR)
	@echo "creating $@"
	@./buildframe "$(INDIR)/ScreenCharacterData_Layer_0_$@" "$(INDIR)/ScreenColorData_Layer_0_$@" "$(OUTDIR)/$@"
	@$(SALVADOR) -classic  $(OUTDIR)/$@  $(addsuffix '.zx0',$(OUTDIR)/$@)
