The game's localization sheet goes through a post-processing step to calculate additional data
such as number of lines translated for a given language, and to display the default language in case
a non-English text is out-of-date (marked by a "![locale]" at the beginning").

In theory you can just download the csv from the Google sheets file and put it in the Text folder as-is and the game will work,
so you don't have to use this utility for quick testing.

To use this utility, first download the csv from Google sheets. Then run processLocSheet.sh from a terminal with its current directory
set to this directory. You may need to modify processLocSheet.sh to suit your environment, especially if you're not on Linux.
You will also need Python 3.x installed (any recent version will do), so the script can run processLocSheet.py.

If you use this frequently, you may find it useful to set up a keyboard shortcut to auto-execute processLocSheet.sh
by pressing a combination of keys.
