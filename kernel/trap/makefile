OBJECTS += trap/trap.o\
    trap/trapasm.o\
    trap/vectors.o\

VPATH += ./trap

trap/vectors.S: trap/vectors.pl
	perl trap/vectors.pl > trap/vectors.S

