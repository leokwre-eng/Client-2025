# RecFlare game client

Automatic download and setup of a game client to play [RecFlare](https://github.com/djdevin/recflare).

The [Rec Room 2025 patch](https://github.com/recflare/patch-2025) is installed as part of the setup and configured to point at the RecFlare servers.

## Download/update and play

### Easy way: installer

Get `RecFlareSetup.exe` from the Actions tab (run the **Build installer** workflow, then download it from the run's Artifacts) or compile it yourself as described below. The installer always downloads the game client from the community mirror - no Steam account or DepotDownloader involved. It then installs the 2025 patch, points `2025patch.ini` at RecFlare, and creates Start menu/desktop shortcuts for desktop and VR mode.

If Windows SmartScreen shows "Windows protected your PC", click **More info** and then **Run anyway** (the installer is unsigned).

To build the installer yourself, compile `RecFlareSetup.iss` with [Inno Setup](https://jrsoftware.org/isinfo.php) 6.1 or later: `iscc RecFlareSetup.iss` (it needs `icon.ico` in the same folder).

### Manual way: scripts

1. Check out this repository or extract the ZIP: https://github.com/djdevin/recflare-client/archive/refs/heads/2025.zip
2. Run `download.bat`. It downloads the game client from the community mirror (no Steam account needed), installs the 2025 patch, and writes `2025patch.ini` pointing at RecFlare.
3. Run `RecRoomScreen.bat` or `RecRoomVR.bat`

## Custom server

Fork this project and change the `ApiHost` and `PhotonHost` values in `download.bat` (the `powershell` line) and `RecFlareSetup.iss` (the `ApiHost`/`PhotonHost` constants) to your own instance. You can also edit `2025patch.ini` in the game folder directly after installing.
