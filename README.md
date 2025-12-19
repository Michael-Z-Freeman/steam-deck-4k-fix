# Steam Deck 4K Auto-Scaler

A background service for the Steam Deck (KDE Plasma 6) that automatically adjusts the UI scaling when connected to an external 4K display.

## Problem
The Steam Deck's Desktop Mode (KDE Plasma) often defaults to 100% scaling on external 4K monitors, making text and UI elements unreadably small. Conversely, if you manually set it to 200%, the internal screen becomes unusable when disconnected.

## Solution
This project provides a script and a systemd user service that:
1.  **Detects** when an external monitor (HDMI/DisplayPort) is connected.
2.  **Automatically switches** KDE Global Scale to **200%** and forces X11 DPI to **192**.
3.  **Fixes Desktop Area:** Turns off the internal screen to ensure the desktop fills the 4K display properly.
4.  **Fixes Mouse Visibility:** Automatically increases cursor size to **48** and enables high mouse acceleration (5x) for 4K usage.
5.  **Reverts** to **100%** scale, **96** DPI, and standard mouse settings when the external monitor is disconnected.
6.  **Restart-Proof:** Runs as a systemd service that survives reboots and SteamOS updates (since it lives in the home directory).

## Installation

1.  **Clone or Download** this repository to your Steam Deck.

2.  **Install Script & Service:**
    Run the following commands in Konsole from the project directory:

    ```bash
    # Make script executable
    chmod +x autoscale.sh

    # Copy script to home folder (recommended location)
    cp autoscale.sh ~/autoscale.sh

    # Create service directory if it doesn't exist
    mkdir -p ~/.config/systemd/user/

    # Copy service file
    cp autoscale.service ~/.config/systemd/user/

    # Reload systemd and enable the service
    systemctl --user daemon-reload
    systemctl --user enable --now autoscale.service
    ```

## Sunshine Setup (Optional)
For high-performance remote desktop access (Moonlight), a systemd service file for Sunshine is also included (`sunshine.service`). This fixes issues with starting Sunshine in Desktop mode.

1.  **Install Sunshine:**
    Install "Sunshine" from the Discover Store (Flatpak).

2.  **Install Service:**
    ```bash
    cp sunshine.service ~/.config/systemd/user/
    systemctl --user daemon-reload
    systemctl --user enable --now sunshine.service
    ```
    This service automatically handles the correct environment variables for X11 capture on the Deck.

## Uninstalling

To remove the auto-scaler:

```bash
systemctl --user disable --now autoscale.service
rm ~/.config/systemd/user/autoscale.service
rm ~/autoscale.sh
systemctl --user daemon-reload
```

## How It Works
*   The `autoscale.sh` script loops every 3 seconds to check `xrandr` for connected displays.
*   It modifies `~/.config/kdeglobals` and `~/.config/kcminputrc`.
*   It uses `xrdb` and `xset` to force DPI and mouse acceleration settings.
*   It restarts `plasmashell` to apply the changes dynamically.

## Compatibility
*   **OS:** SteamOS (Arch Linux)
*   **Desktop:** KDE Plasma 6
*   **Hardware:** Steam Deck LCD / OLED

## Remote Access Notes
### XRDP / FreeRDP
SteamOS includes `freerdp-shadow-cli` natively, which can be used for remote desktop access without disabling the read-only filesystem. However, note the following:
*   **Orientation:** The Steam Deck uses a native portrait panel. When using `freerdp-shadow-cli`, the remote view may appear upside down or inverted. Use the `/rotation:180` flag in the command to correct this.
*   **Color Inversion:** Due to how FreeRDP reads the Steam Deck's frame buffer, some users may experience inverted color channels (BGR vs RGB).
*   **Recommendation:** For high-performance remote access with correct color/orientation, **Sunshine** (available via Flatpak/Discover) is the recommended alternative to Steam Link or RDP.
