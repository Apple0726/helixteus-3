<h1 align="center">Helixteus 3</h1>
<p align="center">
<img src="icon.png" alt="icon">
</p>

A space-themed incremental game where you manage planets and resources in a quest to dominate the universe with buildings and megastructures.

## Community
All active discussion is happening on our [Discord server](https://discord.com/invite/gDHcDA3). Come and say hi!

## Quick start for contributers
- Clone this Git repository.
- Download the [Godot 3](https://godotengine.org/download) game engine.
- Open Godot, select `Import` from the projects list.
- Navigate to the location that you cloned the project, and import the `/project.godot` file.

Having problems with importing Helixteus 3 into Godot? Feel free to ask for help in an [issue](https://github.com/Apple0726/helixteus-3/issues), or the `#development` channel of our [Discord server](https://discord.com/invite/gDHcDA3).

## Contributing

This project is community-driven, which means that anyone is able to help with the development of it. Here are some ways that you can contribute:

- Localization
- Graphics
- Audio
- Code
- Bug reports

### Localization
Want to add your language to the game, or improve existing translations? Localization is managed through [this localization spreadsheet](https://docs.google.com/spreadsheets/d/1-7KJ8WkyXwVS9X2XTegfZ0Sxl3_Dpvcu7ixid8FgKbw/edit?usp=sharing), so feel free to edit it if you have any changes that you want to make.

### Graphics
Does something in the game look a little ugly? All of the sprites/textures are stored within the `/Graphics` directory. Simply replace any image file for whatever graphic you want to change. Consider maintaining the image dimensions to ensure that the graphic is aligned properly within the game.

### Audio
Are you a music producer, or sound designer? All of the game's music is stored in `/Audio`, while the sound effects are in `/Audio/SFX`. There is currently not an easy way to automatically add music into the game, so you can just drop audio files into these directories to be added in at a later date. 
**Note:** All audio must be encoded in OGG format to be used.

### Code
Helixteus 3 is built using the [Godot 3](https://godotengine.org/download) game engine. The biggest benefit of this is that it allows for Helixteus 3 to be easily cross-platform and portable.
Refer to the **Quick start for contributers** section above for information on how to import the game into the game engine to test your code.

**Game logic**
All of the game logic is written in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html), which is very easy to learn (inspired by Python). You will find all of this code in `/Scripts`.
Refactoring the code to look nicer is a great way to start with contributing code. Beautiful code is more likely to attract future contributers. If you are familar with GDScript's [built-in functions](https://docs.godotengine.org/en/stable/classes/class_%40gdscript.html#), then consider finding some inefficient algorithms to improve. New features are also welcome, but try to coordinate with other developers before you start working on anything big.

*Please test your code for bugs before you commit any changes!*

**Shaders**
This game utilizes the [OpenGL Shader Language](https://www.khronos.org/registry/OpenGL/specs/gl/GLSLangSpec.3.30.pdf) (Version 3.30) to add visual effects. All of these shaders are in the `/Shaders` directory. If you are a GLSL wizard, then feel free to improve any existing shaders, or add new ones!

### Bug reports
Found something that should probably not be happening? Please make a detailed [issue](https://github.com/Apple0726/helixteus-3/issues) which contains any logs, and information on how to reproduce the unintended behavior. You may also make a report in the `#bug-reports` channel of our [Discord server](https://discord.com/invite/gDHcDA3).

## Support
All contributions and kind words are very appreciated! This game will always be available for free. If you want to financially support the development, you may donate here:
- [PayPal](https://paypal.me/apple0726)
- [Itch.io](https://apple0726.itch.io/helixteus-3)

