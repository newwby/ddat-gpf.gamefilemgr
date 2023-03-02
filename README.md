# ddat-gpf.gamefilemgr
Game file and progression tracking module for (DDAT) Godot Prototyping Framework

The GameFileManager allows for writing save files to the user data folder, loading save files into memory, tracking user stats during a game, and deleting user files from disk. It utilises backup writing and reading functionality from ddat_gpf.core.GlobalData. Included is a file loading scene that includes an exit signal and start method for easy close/open, and a non-hardcoded save file class that can be extended for user purposes (allowing simple future updating).

By default player saves will keep a track of when the save was created, when it was last saved, and how long it has been open for. You can extend the save file class to add properties relevant to your own game.

---

# How to Use

### Installing
1) Download the latest stable release of the repository under 'releases'.
2) Copy the entire 'src' folder into your root project directory.*
3) Open your project so all the files can be automatically imported by Godot.
4) Add to your project autoloads (*project/project settings/AutoLoad*) the script '*res://src/file_manager/autoload/global_progression.gd*'. Give it the node name '*GlobalProgression*' (this should be the default but double-check it).

\* You should preserve the directory and file structure in the repository, at least until you open it inside Godot. Afterwards you can move files and folders via the editor, and Godot will automatically adjust references appropriately.
However I don't recommend you do this if you have any intention of updating this module in future, unless you are confident you can find and replace dependencies as need be, or you keep a record of where you moved things.

### Utilising inside your Project

1) From the point in your project you wish the player to load saves, instance the GameFileLoadDialog scene (*res://src/file_manager/game_file_load_dialog/game_file_load_dialog.tscn*).
2) In a parent scene's code, call the method '*open_game_file_dialog()*' on the GameFileLoadDialog.
3) Connect the signal '*begin_game_load*' from the GameFileLoadDialog back to the parent scene you wish to return control 
4) Access the chosen save file from '*GlobalProgression.loaded_save_file*' anywhere in your project.

From this point you can extend the GlobalProgressFile class (make sure to replace the GAME_SAVE_CLASS constant in GlobalProgression, see below) to create your own save file class, and add whatever properties you wish to keep track of between player game sessions. Make sure to include logic in your game (after the player loads a save file) to actually pass this information to the relevant objects or game managers.

You can leave the autosave option on (see below) or developers add manual calls to save the player game file by calling the '*save_active_game_file()*' method on GlobalProgression.


---

# Developer Options

You can access developer options in the GlobalProgression autoload (res://src/file_manager/autoload/global_progression.gd).

#### OPTION_ENABLE_GAME_FILE_MANAGER
This flag entirely disables the game file manager, preventing key methods from firing at all. If you are just downloading the game file manager probably best to leave this one enabled. In future this module will also be part of other modules, so I wanted to include a simple way to disable it incase users don't want its functionality when it comes packaged with something else they did want.

#### GAME_SAVE_CLASS
A reference to the GameProgressFile (GPF) class, the default save file class. If you extend GPF into your own save file class (recommended as if you wish to update the GameFileManager in future you'll potentially overwrite the GPF class), change this reference to your own save file class. All parameters and type casts in the GameFileManager reference this constant.

#### OPTION_SHOW_SAVE_ICON_CANVAS
When data is being saved an animated save icon texture (from https://www.kenney.nl/) is (very) briefly shown. You can disable this feature by setting this flag to false.

#### OPTION_TRACK_TOTAL_PLAY_TIME
Game files track playtime via a timer whilst one is active. You can disable this feature by setting this flag to false.

#### OPTION_AUTOSAVE_INTERVAL
Game files are automatically saved every x (default 15) minutes. You can disable this feature by setting this flag to nil (0) or negative (less than 0).

#### OPTION_MAXIMUM_SAVE_FILES
There is a cap on save files that can be written (default 100). You can set this cap as low or high as you like, but setting it nil or negative may produce unexpected behaviour, and setting it too high (coupled with allowing the player to save thousands or more save files) may cause performance hits when the game attempts to gather all save files on disk.

---

# Missing and Planned Features

Currently player saves are not automatically saved on exiting the game process (this is a planned feature), so be aware of this.

Players unloading a save and returning to the save selection screen is not currently supported. You can call the GameFileLoadDialog again, and choosing a save should change the loaded_save, but utilising this feature in this fashion is untested so may produce bugs. Test thoroughly if you allow the player to do this in your game flow (and I'd love to hear how it goes if you do)!

---

# Bug Reporting

Please report any bugs you encounter directly to me on GitHub (https://github.com/newwby). If you could also include the player.log file (located at user://logs, open Godot and click 'Open User Data Folder' under the 'Project' tab) from where you encountered the bug, a description of what you were doing when the bug occured and how to reproduce the bug, it would go a long way to helping me fix it.
