# Makefile for generating sheet music and MIDI files from tunes in the ABC
# Music Notation.
# 
# Dependencies:
# - abcm2ps (http://moinejf.free.fr/)
# - abc2midi (https://ifdo.ca/~seymour/runabc/top.html)
# - ps2pdf (part of Ghostscript)
# - convert (part of ImageMagick)
# - zip

##---------- Preliminaries ----------------------------------------------------
.POSIX:     # Get reliable POSIX behaviour
.SUFFIXES:  # Clear built-in inference rules
.SECONDARY: # Don't delete intermediate files

##---------- Commands ---------------------------------------------------------

# Convert to MIDI
abc2midi_cmd := abc2midi

# Convert to PS/PDF. The -i option is useful for debugging, the sheet music
# will have red circles around problematic areas.
abc2ps_cmd := abcm2ps -D format -F tunebook.fmt -O ps/= # -i
abc2eps_cmd := abcm2ps -E -D format -F tunebook.fmt -O  # -i
ps2pdf_cmd := ps2pdf
eps2jpg_cmd := convert -density 300 -resample 300x300
eps2jpg_cmd := convert -density 300 -resample 300x300

## --------- Variables --------------------------------------------------------

# Variables for build targets
sources := $(wildcard abc/*.abc)
ps_files := $(patsubst abc/%.abc,ps/%.ps,$(sources))
eps_files := $(patsubst abc/%.abc,eps/%.eps,$(sources))
pdf_files := $(patsubst abc/%.abc,pdf/%.pdf,$(sources))
midi_files := $(patsubst abc/%.abc,mid/%.mid,$(sources))
jpg_files := $(patsubst abc/%.abc,jpg/%.jpg,$(sources))
png_files := $(patsubst abc/%.abc,png/%.png,$(sources))

# Zip with all pdf's/mids/jpgs
archive := bertvv-abc-transcriptions
pdf_archive :=zip/$(archive)-pdf.zip
mid_archive := zip/$(archive)-mid.zip
png_archive := zip/$(archive)-png.zip
jpg_archive := zip/$(archive)-jpg.zip
archives := $(pdf_archive) $(mid_archive) $(png_archive) $(jpg_archive)

## --------- Build targets ----------------------------------------------------

help: ## Show this help message (default)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all-jpg: $(jpg_files) ## Generate a JPG file for all tunes
all-midi: $(midi_files) ## Generate a MIDI file for all tunes
all-pdf: $(pdf_files) ## Generate PDF sheet music for all tunes
all-png: $(png_files) ## Generate a PNG file for all tunes

all: all-jpg all-midi all-pdf all-png ## Generate all output formats

$(pdf_archive): all
	@[ -d zip ] || mkdir -v zip
	zip $@ pdf/*.pdf

$(mid_archive): all-midi
	@[ -d zip ] || mkdir -v zip
	zip $@ mid/*.mid

$(png_archive): all-png
	@[ -d zip ] || mkdir -v zip
	zip $@ png/*.png

$(jpg_archive): all-jpg
	@[ -d zip ] || mkdir -v zip
	zip $@ jpg/*.jpg

dist: $(archives) ## Create a zip with the generated files (PDF, MIDI, JPG, PNG)

clean: ## Remove all "intermediate" files
	@echo "Removing intermediate files"
	rm -rf eps/*.eps
	rm -rf ps/*.ps

mrproper: clean ## Remove all generated files
	@echo "Removing generated files"
	rm -rf jpg/*.jpg
	rm -rf mid/*.mid
	rm -rf pdf/*.pdf
	rm -rf png/*.png

## --------- Pattern rules ----------------------------------------------------

ps/%.ps: abc/%.abc
	@[ -d ps ] || mkdir -v ps
	$(abc2ps_cmd) $<

pdf/%.pdf: ps/%.ps
	@[ -d pdf ] || mkdir -v pdf
	$(ps2pdf_cmd) $< $@

eps/%.eps: abc/%.abc
	@[ -d eps ] || mkdir -v eps
	$(abc2eps_cmd) $@ $<
	mv -v eps/*001.eps $@

mid/%.mid: abc/%.abc
	@[ -d mid ] || mkdir -v mid
	$(abc2midi_cmd) $< -o $@

jpg/%.jpg: eps/%.eps
	@[ -d jpg ] || mkdir -v jpg
	$(eps2jpg_cmd) $< -trim $@

png/%.png: eps/%.eps
	@[ -d png ] || mkdir -v png
	$(eps2jpg_cmd) $< -trim -type grayscale $@

.PHONY: help all all-jpg all-midi all-pdf all-png dist clean mrproper