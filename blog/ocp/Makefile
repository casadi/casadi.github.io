SVG=$(wildcard *.svg)

PNGSVG=$(SVG:.svg=.png)

all: $(PNGSVG)

$(PNGSVG): %.png : %.svg
	inkscape -f $< -e $@ -w 1000 -d

