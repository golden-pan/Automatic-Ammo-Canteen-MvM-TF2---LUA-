# Canteener by golden pan [TF2-Lua-MvM]
This is a very simple Lua. It will use ANY canteen you currently have when your ammo count reaches 1 or less.

> Use at your own risk and responsibility!

## Note

Please read the full instructions before commenting on why something doesn’t work.

This is a very simple Lua script. It will use **any canteen** you currently have when your ammo count reaches **1 or less**.

**Known limitation:**  
At the moment, it cannot be limited to ammo canteens only.

You can make the square UI transparent and change the hotkey by right-clicking the square UI.

If anything breaks, the UI gets stuck, or settings behave unexpectedly, use:

- `gp_cant_ui_reset` to reset the UI position to the center of the screen
- `gp_cant_cfg_reset` to fully reset all configuration values and clear stored messages

## Config Location

The config is located in a subfolder called `gp_cant` inside your **Team Fortress 2** folder.

## Features

- Automatically uses any canteen when ammo reaches 1 or less (when toggled)
- Transparent UI feature
- Configurable toggle hotkey

## Installation

1. Download the Lua file.
2. Place it into your Lua scripts folder.
3. Load the Lua.

## Usage

### Toggle

- Left-click the square UI **or** press the default toggle key (`J`) to activate/deactivate it.
- When active, the UI turns golden.

### Misc

- Right-click the square UI to:
  - Change the toggle hotkey
  - Enable transparent mode

### Main Menu

- In the main menu, press `Insert` to show the square UI.
- Make sure the console is closed.

## Commands

### Toggle

| Command | Description |
|---|---|
| `gp_cant_toggle on/off` | Activates or deactivates the toggle. |

### Utility

| Command | Description |
|---|---|
| `gp_cant_ui_reset` | Resets the UI position to the center of the screen. |
| `gp_cant_cfg_reset` | Resets all configuration values to default. |

## Warnings

- Use at your own risk and responsibility.
- You may get banned if you misuse this Lua.
