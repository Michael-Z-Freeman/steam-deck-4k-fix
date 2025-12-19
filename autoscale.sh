#!/bin/bash

# Configuration
# Internal screen usually starts with "eDP". External usually "DisplayPort" or "HDMI"
# We detect external if we see a connected screen that is NOT eDP.
INTERNAL_DISPLAY="eDP"

# Set DISPLAY variable to ensure xrandr works
export DISPLAY=:0
export XAUTHORITY=$(ls /run/user/1000/xauth* | head -n 1)

while true; do
 # 1. Detect if an external monitor is connected
 # We look for any connected display that is NOT the internal one.
 EXTERNAL_CONNECTED=$(xrandr | grep " connected" | grep -v "$INTERNAL_DISPLAY")

 # 2. Check the current Global Scale factor from KDE config
 # Returns 1 for 100%, 2 for 200%, etc.
 CURRENT_SCALE=$(kreadconfig6 --file kdeglobals --group KScreen --key ScaleFactor)
 
 # Check current DPI from XRDB (fallback to 96 if empty)
 CURRENT_DPI=$(xrdb -query | grep "Xft.dpi" | awk '{print $2}')
 if [ -z "$CURRENT_DPI" ]; then CURRENT_DPI=96; fi

 # If config is empty/missing, assume 1
 if [ -z "$CURRENT_SCALE" ]; then
 CURRENT_SCALE=1
 fi

 # Check current Xcursor.size from XRDB
 CURRENT_CURSOR=$(xrdb -query | grep "Xcursor.size" | awk '{print $2}')
 if [ -z "$CURRENT_CURSOR" ]; then CURRENT_CURSOR=24; fi

 # Check current Mouse Acceleration (KDE config)
 CURRENT_ACCEL=$(kreadconfig6 --file kcminputrc --group Mouse --key XLibInputPointerAcceleration)
 if [ -z "$CURRENT_ACCEL" ]; then CURRENT_ACCEL=0.0; fi

 # Check current Xset Acceleration
 CURRENT_XSET=$(xset q | grep "acceleration:" | awk '{print $2}')

 # 3. Logic: Switch Scale based on connection status
 
 # Case A: External Connected
 # We trigger if scale/dpi/cursor/accel is wrong OR if the internal display is still active
 INTERNAL_IS_ACTIVE=$(xrandr | grep "^$INTERNAL_DISPLAY connected" | grep "[0-9]x[0-9]")
 
 if [ -n "$EXTERNAL_CONNECTED" ] && ( [ "$CURRENT_SCALE" -ne 2 ] || [ "$CURRENT_DPI" -ne 192 ] || [ "$CURRENT_CURSOR" -ne 48 ] || [ "$CURRENT_ACCEL" != "1.0" ] || [ "$CURRENT_XSET" != "5/1" ] || [ -n "$INTERNAL_IS_ACTIVE" ] ); then
 echo "External Monitor Detected. Switching to 200% Scale and configuring displays..."
 
 # Turn OFF internal display to force desktop to fill external screen
 # Find the external display name
 EXT_NAME=$(echo "$EXTERNAL_CONNECTED" | awk '{print $1}')
 xrandr --output "$INTERNAL_DISPLAY" --off --output "$EXT_NAME" --auto --primary

 # Write 2 (200%) to config
 kwriteconfig6 --file kdeglobals --group KScreen --key ScaleFactor 2
 
 # Increase Cursor Size (Default is usually 24, making it 48)
 kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 48
 
 # Set Mouse Speed (Libinput) to Max (1.0)
 kwriteconfig6 --file kcminputrc --group Mouse --key XLibInputPointerAcceleration 1.0
 
 # Reload KWin settings
 qdbus6 org.kde.KWin /KWin reconfigure

 # Force X11 DPI (96 * 2 = 192)
 echo "Xft.dpi: 192" | xrdb -merge
 # Force immediate Cursor Size
 echo "Xcursor.size: 48" | xrdb -merge
 
 # Aggressive Mouse Acceleration using xset (since xinput is missing)
 # 5/1 means accelerate 5x when moving more than 1 pixel
 xset m 5 1

 # Restart Plasma to apply changes
 kquitapp6 plasmashell || killall plasmashell
 sleep 2
 export XCURSOR_SIZE=48
 export XCURSOR_THEME=Breeze
 kstart plasmashell &

 # Case B: External Disconnected AND (Scale is not 1 OR DPI is higher than 96)
 elif [ -z "$EXTERNAL_CONNECTED" ] && ( [ "$CURRENT_SCALE" -ne 1 ] || [ "$CURRENT_DPI" -gt 96 ] ); then
 echo "External Monitor Disconnected. Reverting to 100% Scale..."
 
 # Turn ON internal display
 xrandr --output "$INTERNAL_DISPLAY" --auto --primary
 
 # Write 1 (100%) to config
 kwriteconfig6 --file kdeglobals --group KScreen --key ScaleFactor 1
 
 # Reset Cursor Size
 kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 24
 
 # Reset Mouse Speed
 kwriteconfig6 --file kcminputrc --group Mouse --key XLibInputPointerAcceleration 0.0

 # Reload KWin settings
 qdbus6 org.kde.KWin /KWin reconfigure

 # Force X11 DPI (96 * 1 = 96)
 echo "Xft.dpi: 96" | xrdb -merge
 # Reset Cursor and Mouse
 echo "Xcursor.size: 24" | xrdb -merge

 # Restart Plasma to apply changes
 kquitapp6 plasmashell || killall plasmashell
 sleep 2
 export XCURSOR_SIZE=24
 kstart plasmashell &
 fi

 # Check every 3 seconds
 sleep 3
done