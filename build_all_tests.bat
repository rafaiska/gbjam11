rgbasm -Werror -Weverything -Hl src/test/harness.asm -o bin/harness.o
rgbasm -Werror -Weverything -Hl src/test/test-harness.asm -o bin/test-harness.o
rgbasm -Werror -Weverything -Hl src/test/console.asm -o bin/console.o
rgbasm -Werror -Weverything -Hl src/utils.asm -o bin/utils.o
rgblink --dmg --tiny -n bin/test_harness.sym -o bin/test_harness.gb bin/utils.o bin/harness.o bin/console.o bin/test-harness.o
rgbfix -v -p 0xFF --validate bin/test_harness.gb
