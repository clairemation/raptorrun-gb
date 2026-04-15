rgbasm -Werror -Weverything -o build/main.o main.asm
[ $? -eq 0 ] || exit 1
rgbasm -Werror -Weverything -o build/game.o game.asm
[ $? -eq 0 ] || exit 1
rgbasm -Werror -Weverything -o build/utils.o utils.asm
[ $? -eq 0 ] || exit 1
rgbasm -Werror -Weverything -o build/player.o player.asm
[ $? -eq 0 ] || exit 1
rgbasm -Werror -Weverything -o build/bouncers.o bouncers.asm
[ $? -eq 0 ] || exit 1
rgbasm -Werror -Weverything -o build/graphicsdata.o graphicsdata.asm
[ $? -eq 0 ] || exit 1
rgbasm -Werror -Weverything -o build/interrupts.o interrupts.asm
[ $? -eq 0 ] || exit 1
rgblink --dmg --map dist/raptorrun.map --sym dist/raptorrun.sym -o dist/raptorrun.gb build/main.o build/game.o build/utils.o build/graphicsdata.o build/interrupts.o build/player.o build/bouncers.o
[ $? -eq 0 ] || exit 1
rgbfix --title RaptorRun --mbc-type 0x19 --pad-value 0 --validate dist/raptorrun.gb
[ $? -eq 0 ] || exit 1

exit 0

