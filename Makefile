ALL_ASM = $(wildcard src/**/*.asm) $(wildcard src/*.asm)
ALL_ASM_WO_SRC = $(subst src/,,${ALL_ASM})
ALL_ASM_BASE = $(basename ${ALL_ASM_WO_SRC})
ALL_OBJ = $(addprefix build/, $(addsuffix .o, ${ALL_ASM_BASE}))

default: arkanoid main
	echo ${ALL_ASM}

${ALL_OBJ}: build/%.o: src/%.asm
	mkdir -p $(dir $@)
	rgbasm -L -o $@ $^

build/arkanoid.gb: build/tutorial/main.o
	rgblink -o $@ $^
	rgbfix -v -p 0xFF $@

build/arkanoid.sym: build/tutorial/main.o
	rgblink -n $(subst .gb, .sym, $@) $^

build/main.gb: build/main.o build/graphics.o build/physics.o build/ram_map.o
	rgblink -o $@ $^
	rgbfix -v -p 0xFF $@
	rgblink -n $(subst .gb,.sym, $@) $^

arkanoid: build/arkanoid.gb build/arkanoid.sym

main: build/main.gb build/main.sym