# DragonDoor
### An easy to use door script with plenty of customization!

**Features:**
- Set swing angle, time to open, locked state, and more!
- Unidirectional or automatically determine swing direction!
- Tween settings!
- Built in audio handling!

Download the example project to give it a try or see how the different settings are used, or just take the script at [scripts/dragon_door.gd](/scripts/dragon_door.gd) and put it on your door!

## Basic Usage

The script should be placed on whatever you want to act as a door, which can be any Node3D. The only caveat is that you need to be able to call `interact(...)` on the door object in some way, whether thats a raycast based interaction system, a click, etc, so make sure your setup allows that!

The image below shows an example of using an inherited door scene created from an imported GLTF model. A transform parent that holds the door is recommended as that allows you to work with the assumption that the closed door starts at 0 degrees, since the parent should be whats rotated and transformed, but it should work without a parent as well.
<img width="509" height="auto" alt="image" src="https://github.com/user-attachments/assets/18b98722-de19-4422-a7bb-0d676c59f72e" />

Look at the example project for more.


## Video Example
Below is a video of the different doors in the example scene

https://github.com/user-attachments/assets/89845308-874a-434f-9675-5586801e7cd7



## Special thanks
Included models are from Kay Lousberg's [Dungeon Pack Remastered](https://kaylousberg.itch.io/kaykit-dungeon-remastered) under the CC0 license

Included sounds are from Kenney's [RPG Audio](https://kenney.nl/assets/rpg-audio) pack under the CC0 license
