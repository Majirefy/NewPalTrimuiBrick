## Notes

NewPAL is a port of the iOS release of **新仙剑奇侠传** (*The Legend of Sword and Fairy*, also known as NewPAL), the classic Chinese RPG developed by **Softstar Entertainment (大宇資訊)** and its Kuangtu/Crazy Miracle team, first released on 2001-07-21 (iOS release 2015-06-18). Thanks to Softstar for creating the game and to the original H700 handheld porter whose machismo loader, Sword3 bridge and shims make this port possible. Thanks also to the PortMaster team and community for the runtime, tooling and documentation.

This port contains **only the runtime framework**. No copyrighted game data is bundled: you must supply your own legally acquired iOS `.ipa`. See the full documentation and source at <https://github.com/Majirefy/NewPalTrimuiBrick>.

## How to Install

- Install the port through PortMaster.
- Obtain a legal copy of the iOS version of 新仙剑奇侠传 (NewPAL) as an `.ipa` file.
- Copy the `.ipa` into the `newpal/` port folder (for example `Roms/Ports (PORTS)/.ports/newpal/` on NX-Redux).
- Start **NewPal** from the Ports menu. The first run displays an on-screen extraction progress indicator, then verifies the extracted files and automatically removes the `.ipa`.
- If extraction fails or no `.ipa` is found, the on-screen message explains what to do; a failed `.ipa` is kept for retry.
- Requires an aarch64 device with glibc. Tested on TrimUI Brick running NX-Redux.

## Controls

Button names are mapped through SDL GameController, so the layout follows your CFW's controller database (a CFW with swapped face buttons is handled automatically).

| Button | Action |
|---|---|
| D-pad | Move the mouse pointer (touch-drag walking) |
| A | Mouse left click — confirm, advance dialogue, touch menu items |
| B | ESC — cancel |
| X | Space |
| Y | Page Up |
| START | Enter |
| L1 / R1 | Right Shift / Right Ctrl |
| L2 | Hold left mouse button (drag to walk) |
| R3 | Mouse left click |
| Right stick | Mouse movement |
| SELECT + START | Force quit (PortMaster/gptokeyb standard kill switch) |

The title and in-game menus are touch-oriented and require a mouse click, hence A = left click. The firmware's global exit hotkey also works.

## Notes on the port

- The game runs natively at 640x480 and is scaled 1.6x to a 1024x768 panel; `XJ_FILL` and resolution variables can be adjusted in the launch script.
- Sound effects and music/video use two independent ALSA streams via the system dmix. `XJ_AUDIO_SHARE=1` enables the original in-process mixer as a fallback.
- The iOS virtual dpad/A-button hint graphics are hidden by default with same-size transparent PNGs; originals are kept as `Resource/dpad*.png.xjbak`. Set `XJ_HIDE_VPAD=0` to restore them.
- Saves live in the port folder's `saves/` directory; logs are in `logs/`.
- Full setup details, troubleshooting and screenshots: <https://github.com/Majirefy/NewPalTrimuiBrick>

## Licenses

See `newpal/licenses/` for the licenses of the bundled runtime libraries and components, and `newpal/licenses/NOTICE.txt` for component provenance.
