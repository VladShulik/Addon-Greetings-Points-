# Greetings Points Addon

This Garry's Mod addon greets players and awards them points for joining your server.

## Features
- Sends a welcome message in chat whenever a player connects.
- Awards a configurable amount of greeting points.
- Tracks each player's point total, viewable via chat commands.
- Shows a popup on spawn so clients can claim points.

## Prerequisites
- A running **Garry's Mod** server with access to modify files.
- Permission to add files under `garrysmod/addons`.
- (Optional) A local Lua interpreter if you want to test scripts manually.

## Setup
1. Download or clone this repository.
2. Create a folder in your server's `garrysmod/addons` directory, e.g. `greetings_points`.
3. Copy the contents of this repository into that folder. Keep the `lua` directory structure so the files sit at:
   - `garrysmod/addons/greetings_points/lua/autorun/cl_points.lua`
   - `garrysmod/addons/greetings_points/lua/autorun/sv_points.lua`
4. Restart your server to load the addon.

## Usage
Players receive a popup when they spawn. Clicking the button gives them 10 points. They can check their points at any time with the chat command:

```
!points
```

The server will reply in chat with their current total.

### Example
A user named `Citizen` might see the following after claiming points:

```
[Server] Welcome Citizen! You now have 10 greeting points.
```

## Development
If you would like to run the Lua files locally, install Lua and verify it is available:

```bash
apt-get update && apt-get install -y lua5.4
lua -v
```
