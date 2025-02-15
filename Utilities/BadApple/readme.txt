This utility generates the data files for the bad apple easter egg in-game (activated by
renaming any planet to "bad apple").
If you want to run this utility on your own (only works on Linux), you need to place a sequence of .png files
(named 1.png, 2.png...) representing individual frames of the bad apple music video
(or any other video) in the same folder as this file. Then run main from a terminal,
and if successful, a file called data.txt should appear.
THe Godot game engine is used to compress this file. To do that, open a new project in Godot,
then write:

var raw_data = FileAccess.open("data.txt")
var st = raw_data.get_as_text()
var data = FileAccess.open_compressed("res://badappledata", FileAccess.WRITE, FileAccess.COMPRESSION_DEFLATE)
data.store_string(st)
data.close()

This generates a compressed data file called badappledata, which HX3 reads in BadApple.gd to display the video
on a planet.

If you wish to modify main.c and recompile it, you will need to install libpng: http://www.libpng.org/pub/png/libpng.html
Follow the instructions in the INSTALL file. After that, you will need to do:

sudo apt-get install libpng-dev

Then compile the code with:

gcc main.c -o main -lpng