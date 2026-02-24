# ============================================================
#  WinTools - installer.ps1
#  TUI Installer: search by name or category
#  github.com/merybist/WinTools
# ============================================================

#Requires -RunAsAdministrator

$Host.UI.RawUI.WindowTitle = "WinTools - Installer"
[Console]::CursorVisible = $false

# ════════════════════════════════════════════════════════════
#  APP DATABASE
#  FallbackURL = DIRECT link to .exe/.msi installer
#                (not a webpage — used for silent fallback)
# ════════════════════════════════════════════════════════════
$ALL_APPS = @(
    # ── Browser ─────────────────────────────────────────────
    [pscustomobject]@{ Name="Brave";                  ID="Brave.Brave";                            Cat="Browser"; FallbackURL="https://laptop-updates.brave.com/latest/winx64" }
    [pscustomobject]@{ Name="Google Chrome";          ID="Google.Chrome";                          Cat="Browser"; FallbackURL="https://dl.google.com/chrome/install/ChromeSetup.exe" }
    [pscustomobject]@{ Name="LibreWolf";              ID="LibreWolf.LibreWolf";                    Cat="Browser"; FallbackURL="https://gitlab.com/api/v4/projects/24386000/packages/generic/librewolf/latest/librewolf-latest-windows-x86_64-setup.exe" }
    [pscustomobject]@{ Name="Mozilla Firefox";        ID="Mozilla.Firefox";                        Cat="Browser"; FallbackURL="https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" }
    [pscustomobject]@{ Name="Opera";                  ID="Opera.Opera";                            Cat="Browser"; FallbackURL="https://net.geo.opera.com/opera/stable/windows" }
    [pscustomobject]@{ Name="Opera GX";               ID="Opera.OperaGX";                          Cat="Browser"; FallbackURL="https://net.geo.opera.com/opera_gx/stable/windows" }
    [pscustomobject]@{ Name="Tor Browser";            ID="TorProject.TorBrowser";                  Cat="Browser"; FallbackURL="https://www.torproject.org/dist/torbrowser/13.0.15/torbrowser-install-win64-13.0.15_ALL.exe" }
    [pscustomobject]@{ Name="Vivaldi";                ID="Vivaldi.Vivaldi";                        Cat="Browser"; FallbackURL="https://downloads.vivaldi.com/stable/Vivaldi.latest.x64.exe" }
    [pscustomobject]@{ Name="Waterfox";               ID="Waterfox.Waterfox";                      Cat="Browser"; FallbackURL="https://cdn1.waterfox.net/waterfox/releases/latest/WINNT_x86_64/Waterfox%20Setup.exe" }
    # ── Chat ────────────────────────────────────────────────
    [pscustomobject]@{ Name="Discord";                ID="Discord.Discord";                        Cat="Chat";    FallbackURL="https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x64" }
    [pscustomobject]@{ Name="Element";                ID="Element.Element";                        Cat="Chat";    FallbackURL="https://packages.element.io/desktop/install/win32/x64/Element%20Setup.exe" }
    [pscustomobject]@{ Name="Microsoft Teams";        ID="Microsoft.Teams";                        Cat="Chat";    FallbackURL="https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&managedInstaller=true&download=true" }
    [pscustomobject]@{ Name="mIRC";                   ID="mIRC.mIRC";                              Cat="Chat";    FallbackURL="https://www.mirc.com/get.php?product=mIRC" }
    [pscustomobject]@{ Name="Signal";                 ID="OpenWhisperSystems.Signal";              Cat="Chat";    FallbackURL="https://updates.signal.org/desktop/nsis/SignalSetup.exe" }
    [pscustomobject]@{ Name="Skype";                  ID="Microsoft.Skype";                        Cat="Chat";    FallbackURL="https://go.skype.com/windows.desktop.download" }
    [pscustomobject]@{ Name="Slack";                  ID="SlackTechnologies.Slack";                Cat="Chat";    FallbackURL="https://slack.com/ssb/download-win64" }
    [pscustomobject]@{ Name="Telegram";               ID="Telegram.TelegramDesktop";               Cat="Chat";    FallbackURL="https://telegram.org/dl/desktop/win64" }
    [pscustomobject]@{ Name="Viber";                  ID="Viber.Viber";                            Cat="Chat";    FallbackURL="https://download.cdn.viber.com/cdn/desktop/Windows/ViberSetup.exe" }
    [pscustomobject]@{ Name="WhatsApp";               ID="9NKSQGP7F2NH";                           Cat="Chat";    FallbackURL="https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe" }
    [pscustomobject]@{ Name="Zoom";                   ID="Zoom.Zoom";                              Cat="Chat";    FallbackURL="https://zoom.us/client/latest/ZoomInstallerFull.exe?archType=x64" }
    # ── Design ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Blender";                ID="BlenderFoundation.Blender";              Cat="Design";  FallbackURL="https://mirrors.dotsrc.org/blender/release/Blender4.2/blender-4.2.0-windows-x64.msi" }
    [pscustomobject]@{ Name="DaVinci Resolve";        ID="Blackmagic.DaVinciResolve";              Cat="Design";  FallbackURL="https://www.blackmagicdesign.com/api/support/us/downloads.json" }
    [pscustomobject]@{ Name="Figma";                  ID="Figma.Figma";                            Cat="Design";  FallbackURL="https://desktop.figma.com/win/FigmaSetup.exe" }
    [pscustomobject]@{ Name="GIMP";                   ID="GIMP.GIMP";                              Cat="Design";  FallbackURL="https://download.gimp.org/gimp/v2.10/windows/gimp-2.10.38-setup.exe" }
    [pscustomobject]@{ Name="Inkscape";               ID="Inkscape.Inkscape";                      Cat="Design";  FallbackURL="https://media.inkscape.org/dl/resources/file/inkscape-1.3.2_2023-11-25_091e20e-x64.exe" }
    [pscustomobject]@{ Name="Krita";                  ID="KDE.Krita";                              Cat="Design";  FallbackURL="https://download.kde.org/stable/krita/5.2.2/krita-x64-5.2.2-setup.exe" }
    [pscustomobject]@{ Name="Paint.NET";              ID="dotPDN.PaintDotNet";                     Cat="Design";  FallbackURL="https://www.dotpdn.com/files/paint.net.5.0.13.install.anycpu.web.zip" }
    [pscustomobject]@{ Name="Pencil2D";               ID="Pencil2D.Pencil2D";                      Cat="Design";  FallbackURL="https://github.com/pencil2d/pencil/releases/download/v0.6.6/pencil2d-win64-0.6.6.exe" }
    [pscustomobject]@{ Name="ScreenToGif";            ID="NickeManarin.ScreenToGif";               Cat="Design";  FallbackURL="https://github.com/NickeManarin/ScreenToGif/releases/download/2.40.4/ScreenToGif.2.40.4.Setup.msi" }
    [pscustomobject]@{ Name="ShareX";                 ID="ShareX.ShareX";                          Cat="Design";  FallbackURL="https://github.com/ShareX/ShareX/releases/download/v16.0.1/ShareX-16.0.1-setup.exe" }
    [pscustomobject]@{ Name="Storyboarder";           ID="wonderunit.Storyboarder";                Cat="Design";  FallbackURL="https://github.com/wonderunit/storyboarder/releases/download/v2.7.0/Storyboarder-Setup-2.7.0.exe" }
    [pscustomobject]@{ Name="Vectr";                  ID="Vectr.Vectr";                            Cat="Design";  FallbackURL="https://vectr.com/download/vectr-win.exe" }
    # ── Dev ─────────────────────────────────────────────────
    [pscustomobject]@{ Name="Android Studio";         ID="Google.AndroidStudio";                   Cat="Dev";     FallbackURL="https://redirector.gvt1.com/edgedl/android/studio/install/2024.1.1.12/android-studio-2024.1.1.12-windows.exe" }
    [pscustomobject]@{ Name="Dbeaver";                ID="dbeaver.dbeaver";                        Cat="Dev";     FallbackURL="https://dbeaver.io/files/dbeaver-ce-latest-x86_64-setup.exe" }
    [pscustomobject]@{ Name="Docker Desktop";         ID="Docker.DockerDesktop";                   Cat="Dev";     FallbackURL="https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" }
    [pscustomobject]@{ Name="Filezilla";              ID="TimKosse.FileZilla.Client";              Cat="Dev";     FallbackURL="https://dl3.cdn.filezilla-project.org/client/FileZilla_3.67.1_win64_sponsored-setup.exe" }
    [pscustomobject]@{ Name="Git";                    ID="Git.Git";                                Cat="Dev";     FallbackURL="https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe" }
    [pscustomobject]@{ Name="GitHub Desktop";         ID="GitHub.GitHubDesktop";                   Cat="Dev";     FallbackURL="https://central.github.com/deployments/desktop/desktopapp/latest/win32?format=msi" }
    [pscustomobject]@{ Name="Go";                     ID="GoLang.Go";                              Cat="Dev";     FallbackURL="https://go.dev/dl/go1.22.5.windows-amd64.msi" }
    [pscustomobject]@{ Name="HeidiSQL";               ID="HeidiSQL.HeidiSQL";                      Cat="Dev";     FallbackURL="https://www.heidisql.com/downloads/releases/HeidiSQL_12.8_Setup.exe" }
    [pscustomobject]@{ Name="Insomnia";               ID="Insomnia.Insomnia";                      Cat="Dev";     FallbackURL="https://github.com/Kong/insomnia/releases/download/core%402024.7.0/Insomnia.Setup.2024.7.0.exe" }
    [pscustomobject]@{ Name="JetBrains Toolbox";      ID="JetBrains.Toolbox";                      Cat="Dev";     FallbackURL="https://data.services.jetbrains.com/products/download?platform=windows&code=TBA" }
    [pscustomobject]@{ Name="MobaXterm";              ID="Mobatek.MobaXterm";                      Cat="Dev";     FallbackURL="https://download.mobatek.net/2402024052305253/MobaXterm_Installer_v24.0.zip" }
    [pscustomobject]@{ Name="Node.js LTS";            ID="OpenJS.NodeJS.LTS";                      Cat="Dev";     FallbackURL="https://nodejs.org/dist/v20.17.0/node-v20.17.0-x64.msi" }
    [pscustomobject]@{ Name="Notepad++";              ID="Notepad++.Notepad++";                    Cat="Dev";     FallbackURL="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.x64.exe" }
    [pscustomobject]@{ Name="oh-my-posh";             ID="JanDeDobbeleer.OhMyPosh";               Cat="Dev";     FallbackURL="https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v23.6.3/install-amd64.exe" }
    [pscustomobject]@{ Name="Postman";                ID="Postman.Postman";                        Cat="Dev";     FallbackURL="https://dl.pstmn.io/download/latest/win64" }
    [pscustomobject]@{ Name="PyCharm Community";      ID="JetBrains.PyCharm.Community";            Cat="Dev";     FallbackURL="https://download.jetbrains.com/python/pycharm-community-2024.1.5.exe" }
    [pscustomobject]@{ Name="Python 3";               ID="Python.Python.3";                        Cat="Dev";     FallbackURL="https://www.python.org/ftp/python/3.12.5/python-3.12.5-amd64.exe" }
    [pscustomobject]@{ Name="Ruby";                   ID="RubyInstallerTeam.Ruby";                 Cat="Dev";     FallbackURL="https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.3.4-1/rubyinstaller-devkit-3.3.4-1-x64.exe" }
    [pscustomobject]@{ Name="Rust";                   ID="Rustlang.Rustup";                        Cat="Dev";     FallbackURL="https://win.rustup.rs/x86_64" }
    [pscustomobject]@{ Name="TablePlus";              ID="TablePlus.TablePlus";                    Cat="Dev";     FallbackURL="https://tableplus.com/release/windows/tableplus_latest.exe" }
    [pscustomobject]@{ Name="Visual Studio Code";     ID="Microsoft.VisualStudioCode";             Cat="Dev";     FallbackURL="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user" }
    [pscustomobject]@{ Name="Visual Studio 2022";     ID="Microsoft.VisualStudio.2022.Community";  Cat="Dev";     FallbackURL="https://aka.ms/vs/17/release/vs_community.exe" }
    [pscustomobject]@{ Name="Windows Terminal";       ID="Microsoft.WindowsTerminal";              Cat="Dev";     FallbackURL="https://github.com/microsoft/terminal/releases/download/v1.20.11781.0/Microsoft.WindowsTerminal_1.20.11781.0_8wekyb3d8bbwe.msixbundle" }
    [pscustomobject]@{ Name="WinSCP";                 ID="WinSCP.WinSCP";                          Cat="Dev";     FallbackURL="https://cdn.winscp.net/files/WinSCP-6.3.4-Setup.exe" }
    # ── Gaming ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Battle.net";             ID="Blizzard.BattleNet";                     Cat="Gaming";  FallbackURL="https://www.blizzard.com/download/confirmation?product=bnetdesk" }
    [pscustomobject]@{ Name="Cemu (Wii U)";           ID="Cemu.Cemu";                              Cat="Gaming";  FallbackURL="https://github.com/cemu-project/Cemu/releases/download/v2.0-89/cemu_2.0-89_windows_x64.exe" }
    [pscustomobject]@{ Name="Dolphin Emulator";       ID="DolphinEmu.Dolphin";                     Cat="Gaming";  FallbackURL="https://dl.dolphin-emu.org/builds/dolphin-master-latest-x64.7z" }
    [pscustomobject]@{ Name="DS4Windows";             ID="Ryochan7.DS4Windows";                    Cat="Gaming";  FallbackURL="https://github.com/Ryochan7/DS4Windows/releases/download/v3.3.3/DS4Windows_v3.3.3_x64.zip" }
    [pscustomobject]@{ Name="EA App";                 ID="ElectronicArts.EADesktop";               Cat="Gaming";  FallbackURL="https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" }
    [pscustomobject]@{ Name="Epic Games";             ID="EpicGames.EpicGamesLauncher";            Cat="Gaming";  FallbackURL="https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi" }
    [pscustomobject]@{ Name="GOG Galaxy";             ID="GOG.Galaxy";                             Cat="Gaming";  FallbackURL="https://content-system.gog.com/open_link/download?path=/open/galaxy/client/setup/setup.exe" }
    [pscustomobject]@{ Name="Heroic Games Launcher";  ID="HeroicGamesLauncher.HeroicGamesLauncher"; Cat="Gaming"; FallbackURL="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.14.0/Heroic-2.14.0-Setup.exe" }
    [pscustomobject]@{ Name="Itch.io";                ID="itch.io";                                Cat="Gaming";  FallbackURL="https://broth.itch.ovh/itch-setup/windows-amd64/ItchSetup.exe" }
    [pscustomobject]@{ Name="MAME";                   ID="MAMEDEV.MAME";                           Cat="Gaming";  FallbackURL="https://github.com/mamedev/mame/releases/download/mame0271/mame0271b_64bit.exe" }
    [pscustomobject]@{ Name="PCSX2 (PS2)";            ID="PCSX2.PCSX2";                            Cat="Gaming";  FallbackURL="https://github.com/PCSX2/pcsx2/releases/download/v2.1.82/pcsx2-v2.1.82-windows-x64-Qt-installer.exe" }
    [pscustomobject]@{ Name="PPSSPP (PSP)";           ID="PPSSPP.PPSSPP";                          Cat="Gaming";  FallbackURL="https://www.ppsspp.org/files/1_17_3/PPSSPPWindowsAmd64.zip" }
    [pscustomobject]@{ Name="Playnite";               ID="Playnite.Playnite";                      Cat="Gaming";  FallbackURL="https://github.com/JosefNemec/Playnite/releases/download/10.32/Playnite1032.exe" }
    [pscustomobject]@{ Name="RetroArch";              ID="Libretro.RetroArch";                     Cat="Gaming";  FallbackURL="https://buildbot.libretro.com/stable/1.19.1/windows/x86_64/RetroArch-x86_64-setup.exe" }
    [pscustomobject]@{ Name="Ryujinx (Switch)";       ID="Ryujinx.Ryujinx";                        Cat="Gaming";  FallbackURL="https://github.com/Ryujinx/release-channel-master/releases/download/1.1.1374/ryujinx-1.1.1374-win_x64.zip" }
    [pscustomobject]@{ Name="Steam";                  ID="Valve.Steam";                            Cat="Gaming";  FallbackURL="https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe" }
    [pscustomobject]@{ Name="Ubisoft Connect";        ID="Ubisoft.Connect";                        Cat="Gaming";  FallbackURL="https://ubi.li/4vxt9" }
    [pscustomobject]@{ Name="Xbox";                   ID="9MV0B5HZVK9Z";                           Cat="Gaming";  FallbackURL="https://www.microsoft.com/store/productId/9MV0B5HZVK9Z" }
    # ── Media ───────────────────────────────────────────────
    [pscustomobject]@{ Name="Audacity";               ID="Audacity.Audacity";                      Cat="Media";   FallbackURL="https://github.com/audacity/audacity/releases/download/Audacity-3.6.4/audacity-win-3.6.4-64bit.exe" }
    [pscustomobject]@{ Name="Clementine";             ID="Clementine-Player.Clementine";           Cat="Media";   FallbackURL="https://github.com/clementine-player/Clementine/releases/download/1.4.0/ClementineSetup-1.4.0.exe" }
    [pscustomobject]@{ Name="foobar2000";             ID="PeterPawlowski.foobar2000";              Cat="Media";   FallbackURL="https://www.foobar2000.org/files/foobar2000_v2.1.5.exe" }
    [pscustomobject]@{ Name="HandBrake";              ID="HandBrake.HandBrake";                    Cat="Media";   FallbackURL="https://github.com/HandBrake/HandBrake/releases/download/1.8.1/HandBrake-1.8.1-x86_64-Win_GUI.exe" }
    [pscustomobject]@{ Name="iTunes";                 ID="Apple.iTunes";                           Cat="Media";   FallbackURL="https://www.apple.com/itunes/download/win64" }
    [pscustomobject]@{ Name="K-Lite Codec Pack";      ID="CodecGuide.K-LiteCodecPack.Full";        Cat="Media";   FallbackURL="https://files2.codecguide.com/K-Lite_Codec_Pack_1870_Full.exe" }
    [pscustomobject]@{ Name="Kdenlive";               ID="KDE.Kdenlive";                           Cat="Media";   FallbackURL="https://download.kde.org/stable/kdenlive/24.05/windows/kdenlive-24.05.2.exe" }
    [pscustomobject]@{ Name="MPC-HC";                 ID="clsid2.mpc-hc";                         Cat="Media";   FallbackURL="https://github.com/clsid2/mpc-hc/releases/download/2.1.4/MPC-HC.2.1.4.x64.exe" }
    [pscustomobject]@{ Name="MPV";                    ID="mpv-player.mpv";                         Cat="Media";   FallbackURL="https://sourceforge.net/projects/mpv-player-windows/files/64bit/mpv-x86_64-20240825-git-b7f2a0e.7z" }
    [pscustomobject]@{ Name="MusicBee";               ID="MusicBee.MusicBee";                      Cat="Media";   FallbackURL="https://www.getmusicbee.com/files/MusicBeeSetup_3_6.exe" }
    [pscustomobject]@{ Name="OBS Studio";             ID="OBSProject.OBSStudio";                  Cat="Media";   FallbackURL="https://github.com/obsproject/obs-studio/releases/download/30.2.2/OBS-Studio-30.2.2-Windows.exe" }
    [pscustomobject]@{ Name="Plex";                   ID="Plex.Plexamp";                           Cat="Media";   FallbackURL="https://plex.tv/plexamp/app/download?platform=windows" }
    [pscustomobject]@{ Name="Shotcut";                ID="Meltytech.Shotcut";                      Cat="Media";   FallbackURL="https://github.com/mltframework/shotcut/releases/download/v24.06.26/shotcut-win64-240626.exe" }
    [pscustomobject]@{ Name="Spotify";                ID="Spotify.Spotify";                        Cat="Media";   FallbackURL="https://download.scdn.co/SpotifySetup.exe" }
    [pscustomobject]@{ Name="Stremio";                ID="Stremio.Stremio";                        Cat="Media";   FallbackURL="https://dl.strem.io/shell-win/v4.4.168/Stremio+4.4.168.exe" }
    [pscustomobject]@{ Name="VLC";                    ID="VideoLAN.VLC";                           Cat="Media";   FallbackURL="https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe" }
    [pscustomobject]@{ Name="Winamp";                 ID="Winamp.Winamp";                          Cat="Media";   FallbackURL="https://www.winamp.com/winamp-download/" }
    [pscustomobject]@{ Name="YouTube Music";          ID="th-ch.YouTubeMusic";                     Cat="Media";   FallbackURL="https://github.com/th-ch/youtube-music/releases/download/v3.3.9/YouTube-Music-Setup-3.3.9.exe" }
    # ── Office ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Bitwarden";              ID="Bitwarden.Bitwarden";                    Cat="Office";  FallbackURL="https://vault.bitwarden.com/download/?app=desktop&platform=windows" }
    [pscustomobject]@{ Name="CherryTree";             ID="giuspen.cherrytree";                     Cat="Office";  FallbackURL="https://www.giuspen.net/software/cherrytree_1.1.0_amd64.exe" }
    [pscustomobject]@{ Name="Drawio";                 ID="JGraph.Draw";                            Cat="Office";  FallbackURL="https://github.com/jgraph/drawio-desktop/releases/download/v24.7.5/draw.io-24.7.5-windows-installer.exe" }
    [pscustomobject]@{ Name="Joplin";                 ID="Joplin.Joplin";                          Cat="Office";  FallbackURL="https://github.com/laurent22/joplin/releases/download/v3.0.15/Joplin-Setup-3.0.15.exe" }
    [pscustomobject]@{ Name="KeePassXC";              ID="KeePassXCTeam.KeePassXC";               Cat="Office";  FallbackURL="https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi" }
    [pscustomobject]@{ Name="LibreOffice";            ID="TheDocumentFoundation.LibreOffice";      Cat="Office";  FallbackURL="https://download.documentfoundation.org/libreoffice/stable/24.8.0/win/x86_64/LibreOffice_24.8.0_Win_x86-64.msi" }
    [pscustomobject]@{ Name="Logseq";                 ID="Logseq.Logseq";                          Cat="Office";  FallbackURL="https://github.com/logseq/logseq/releases/download/0.10.9/Logseq-installer-0.10.9.exe" }
    [pscustomobject]@{ Name="Notion";                 ID="Notion.Notion";                          Cat="Office";  FallbackURL="https://www.notion.so/desktop/windows/download" }
    [pscustomobject]@{ Name="Obsidian";               ID="Obsidian.Obsidian";                      Cat="Office";  FallbackURL="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.6.7/Obsidian-1.6.7.exe" }
    [pscustomobject]@{ Name="PDF24 Creator";          ID="geek-software.PDF24Creator";             Cat="Office";  FallbackURL="https://creator.pdf24.org/releases/PDF24Creator-latest-x64.exe" }
    [pscustomobject]@{ Name="Sumatra PDF";            ID="SumatraPDF.SumatraPDF";                  Cat="Office";  FallbackURL="https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64-install.exe" }
    [pscustomobject]@{ Name="Thunderbird";            ID="Mozilla.Thunderbird";                    Cat="Office";  FallbackURL="https://download.mozilla.org/?product=thunderbird-latest&os=win64&lang=en-US" }
    [pscustomobject]@{ Name="Todoist";                ID="Doist.Todoist";                          Cat="Office";  FallbackURL="https://todoist.com/windows_app" }
    [pscustomobject]@{ Name="Zotero";                 ID="Zotero.Zotero";                          Cat="Office";  FallbackURL="https://www.zotero.org/download/client/dl?channel=release&platform=win32-x64" }
    # ── Security ────────────────────────────────────────────
    [pscustomobject]@{ Name="Bitwarden";              ID="Bitwarden.Bitwarden";                    Cat="Security"; FallbackURL="https://vault.bitwarden.com/download/?app=desktop&platform=windows" }
    [pscustomobject]@{ Name="KeePassXC";              ID="KeePassXCTeam.KeePassXC";               Cat="Security"; FallbackURL="https://github.com/keepassxreboot/keepassxc/releases/download/2.7.9/KeePassXC-2.7.9-Win64.msi" }
    [pscustomobject]@{ Name="Malwarebytes";           ID="Malwarebytes.Malwarebytes";              Cat="Security"; FallbackURL="https://downloads.malwarebytes.com/file/mb-windows" }
    [pscustomobject]@{ Name="Nmap";                   ID="Insecure.Nmap";                          Cat="Security"; FallbackURL="https://nmap.org/dist/nmap-7.95-setup.exe" }
    [pscustomobject]@{ Name="OpenVPN";                ID="OpenVPNTechnologies.OpenVPN";            Cat="Security"; FallbackURL="https://openvpn.net/downloads/openvpn-connect-v3-windows.msi" }
    [pscustomobject]@{ Name="Revo Uninstaller";       ID="RevoUninstaller.RevoUninstaller";        Cat="Security"; FallbackURL="https://download.revouninstaller.com/download/revosetup.exe" }
    [pscustomobject]@{ Name="Veracrypt";              ID="IDRIX.VeraCrypt";                        Cat="Security"; FallbackURL="https://launchpad.net/veracrypt/trunk/1.26.14/+download/VeraCrypt_Setup_x64_1.26.14.exe" }
    [pscustomobject]@{ Name="Wireshark";              ID="WiresharkFoundation.Wireshark";          Cat="Security"; FallbackURL="https://2.na.dl.wireshark.org/win64/Wireshark-4.4.0-x64.exe" }
    [pscustomobject]@{ Name="WireGuard";              ID="WireGuard.WireGuard";                    Cat="Security"; FallbackURL="https://download.wireguard.com/windows-client/wireguard-installer.exe" }
    # ── Utils ───────────────────────────────────────────────
    [pscustomobject]@{ Name="7-Zip";                  ID="7zip.7zip";                              Cat="Utils";   FallbackURL="https://www.7-zip.org/a/7z2407-x64.exe" }
    [pscustomobject]@{ Name="Autoruns";               ID="Microsoft.Sysinternals.Autoruns";        Cat="Utils";   FallbackURL="https://download.sysinternals.com/files/Autoruns.zip" }
    [pscustomobject]@{ Name="Bulk Rename Utility";    ID="TGRMNSoftware.BulkRenameUtility";        Cat="Utils";   FallbackURL="https://www.bulkrenameutility.co.uk/Downloads/BRU_Setup.exe" }
    [pscustomobject]@{ Name="CPU-Z";                  ID="CPUID.CPU-Z";                            Cat="Utils";   FallbackURL="https://download.cpuid.com/cpu-z/cpu-z_2.11-en.exe" }
    [pscustomobject]@{ Name="CrystalDiskInfo";        ID="CrystalDewWorld.CrystalDiskInfo";        Cat="Utils";   FallbackURL="https://crystalmark.info/redirect.php?product=CrystalDiskInfo" }
    [pscustomobject]@{ Name="CrystalDiskMark";        ID="CrystalDewWorld.CrystalDiskMark";        Cat="Utils";   FallbackURL="https://crystalmark.info/redirect.php?product=CrystalDiskMark" }
    [pscustomobject]@{ Name="Ditto (clipboard)";      ID="Ditto.Ditto";                            Cat="Utils";   FallbackURL="https://github.com/sabrogden/Ditto/releases/download/3.24.234.0/DittoSetup_64bit_3_24_234_0.exe" }
    [pscustomobject]@{ Name="Everything";             ID="voidtools.Everything";                   Cat="Utils";   FallbackURL="https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe" }
    [pscustomobject]@{ Name="GPU-Z";                  ID="TechPowerUp.GPU-Z";                      Cat="Utils";   FallbackURL="https://download.techpowerup.com/files/GPU-Z.2.59.0.exe" }
    [pscustomobject]@{ Name="HWiNFO";                 ID="REALiX.HWiNFO";                         Cat="Utils";   FallbackURL="https://www.hwinfo.com/files/hwi_latest.exe" }
    [pscustomobject]@{ Name="HWMonitor";              ID="CPUID.HWMonitor";                        Cat="Utils";   FallbackURL="https://download.cpuid.com/hwmonitor/hwmonitor_1.54-setup.exe" }
    [pscustomobject]@{ Name="MSI Afterburner";        ID="MSI.Afterburner";                        Cat="Utils";   FallbackURL="https://download.msi.com/uti_exe/vga/MSIAfterburnerSetup.zip" }
    [pscustomobject]@{ Name="NirSoft NirLauncher";    ID="Nirsoft.NirLauncher";                    Cat="Utils";   FallbackURL="https://www.nirsoft.net/utils/nirlauncher.zip" }
    [pscustomobject]@{ Name="PowerToys";              ID="Microsoft.PowerToys";                    Cat="Utils";   FallbackURL="https://github.com/microsoft/PowerToys/releases/download/v0.83.0/PowerToysSetup-0.83.0-x64.exe" }
    [pscustomobject]@{ Name="Process Hacker";         ID="wj32.ProcessHacker";                     Cat="Utils";   FallbackURL="https://github.com/processhacker/processhacker/releases/download/v2.39/processhacker-2.39-setup.exe" }
    [pscustomobject]@{ Name="Rufus";                  ID="Rufus.Rufus";                            Cat="Utils";   FallbackURL="https://github.com/pbatard/rufus/releases/download/v4.5/rufus-4.5.exe" }
    [pscustomobject]@{ Name="Speccy";                 ID="Piriform.Speccy";                        Cat="Utils";   FallbackURL="https://download.ccleaner.com/spsetup132.exe" }
    [pscustomobject]@{ Name="TreeSize Free";          ID="JAMSoftware.TreeSize.Free";              Cat="Utils";   FallbackURL="https://downloads.jam-software.de/treesize_free/TreeSizeFreeSetup.exe" }
    [pscustomobject]@{ Name="Ventoy";                 ID="Ventoy.Ventoy";                          Cat="Utils";   FallbackURL="https://github.com/ventoy/Ventoy/releases/download/v1.0.99/ventoy-1.0.99-windows.zip" }
    [pscustomobject]@{ Name="WinDirStat";             ID="WinDirStat.WinDirStat";                  Cat="Utils";   FallbackURL="https://windirstat.net/wds_current_setup.exe" }
    [pscustomobject]@{ Name="WinRAR";                 ID="RARLab.WinRAR";                          Cat="Utils";   FallbackURL="https://www.rarlab.com/rar/winrar-x64-701.exe" }
    [pscustomobject]@{ Name="WizTree";                ID="AntibodySoftware.WizTree";               Cat="Utils";   FallbackURL="https://diskanalyzer.com/files/wiztree_4_16_setup.exe" }
) | Sort-Object Name

# ════════════════════════════════════════════════════════════
#  ANSI COLOR MAP
# ════════════════════════════════════════════════════════════
$ESC   = [char]27
$RESET = "$ESC[0m"

$FG = @{
    Black       = "$ESC[30m"; DarkRed     = "$ESC[31m"; DarkGreen   = "$ESC[32m"
    DarkYellow  = "$ESC[33m"; DarkBlue    = "$ESC[34m"; DarkMagenta = "$ESC[35m"
    DarkCyan    = "$ESC[36m"; Gray        = "$ESC[37m"; DarkGray    = "$ESC[90m"
    Red         = "$ESC[91m"; Green       = "$ESC[92m"; Yellow      = "$ESC[93m"
    Blue        = "$ESC[94m"; Magenta     = "$ESC[95m"; Cyan        = "$ESC[96m"
    White       = "$ESC[97m"
}
$BG = @{
    Cyan     = "$ESC[46m"
    DarkBlue = "$ESC[44m"
    DarkGray = "$ESC[100m"
}

$CAT_FG = @{
    Browser  = $FG.Cyan;    Chat     = $FG.Magenta; Design   = $FG.Yellow
    Dev      = $FG.Green;   Gaming   = $FG.Red;     Media    = $FG.Blue
    Office   = $FG.White;   Security = $FG.DarkYellow; Utils = $FG.DarkCyan
}

$CAT_LEGEND = "Browser * Chat * Design * Dev * Gaming * Media * Office * Security * Utils"

# ════════════════════════════════════════════════════════════
#  WINGET EXIT CODES
# ════════════════════════════════════════════════════════════
$WINGET_CODES = @{
    0            = @{ S = "+"; C = $FG.Green;  M = "Installed";                                        FB = $false }
    -1978335189  = @{ S = "o"; C = $FG.Yellow; M = "Already installed";                               FB = $false }
    -1978335215  = @{ S = "o"; C = $FG.Yellow; M = "Already installed";                               FB = $false }
    -1978335212  = @{ S = "o"; C = $FG.Yellow; M = "Already installed (newer version present)";       FB = $false }
    -1978335141  = @{ S = "o"; C = $FG.Yellow; M = "No available upgrade found";                      FB = $false }
    -1978335138  = @{ S = "!"; C = $FG.Yellow; M = "No applicable installer (trying fallback)";       FB = $true  }
    -1978335106  = @{ S = "!"; C = $FG.Yellow; M = "Needs interactive install (trying fallback)";     FB = $true  }
    -1978335153  = @{ S = "!"; C = $FG.Yellow; M = "App is running — close it and retry";             FB = $false }
    -1978335147  = @{ S = "~"; C = $FG.Cyan;   M = "Installed — reboot required";                    FB = $false }
    -1978335135  = @{ S = "x"; C = $FG.Red;    M = "Install failed (trying fallback)";                FB = $true  }
    -1978335239  = @{ S = "x"; C = $FG.Red;    M = "Package not found (trying fallback)";             FB = $true  }
    -1978335227  = @{ S = "x"; C = $FG.Red;    M = "No applicable installer found (trying fallback)"; FB = $true  }
}

# ════════════════════════════════════════════════════════════
#  STATE
# ════════════════════════════════════════════════════════════
$checked      = New-Object 'System.Collections.Generic.HashSet[int]'
$cursor       = 0
$searchStr    = ""
$installedIDs = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$script:dlPercent  = 0
$script:wgBarRow   = 0
$script:wgBarWidth = 30
$script:dlBarRow   = 0
$script:dlBarWidth = 30

# ════════════════════════════════════════════════════════════
#  PROGRESS BAR HELPERS  (top-level for PS5.1 compatibility)
# ════════════════════════════════════════════════════════════
function Write-WingetBar {
    param([int]$pct, [string]$phaseText)
    $filled = [int](($pct / 100) * $script:wgBarWidth)
    $empty  = $script:wgBarWidth - $filled
    $bar    = ("$([char]0x2588)" * $filled) + ("$([char]0x2591)" * $empty)
    $label  = "${phaseText}  $($pct.ToString().PadLeft(3))%"
    [Console]::SetCursorPosition(0, $script:wgBarRow)
    [Console]::Write("$ESC[2K  $($FG.Cyan)[${bar}]  $($FG.White)${label}$RESET")
    [Console]::SetCursorPosition(0, $script:wgBarRow + 1)
}

function Write-DownloadBar {
    param([int]$pct)
    $filled = [int](($pct / 100) * $script:dlBarWidth)
    $bar    = ("$([char]0x2588)" * $filled) + ("$([char]0x2591)" * ($script:dlBarWidth - $filled))
    [Console]::SetCursorPosition(0, $script:dlBarRow)
    [Console]::Write("$ESC[2K  $($FG.Cyan)[${bar}]  $($FG.White)$($pct.ToString().PadLeft(3))% downloading...$RESET")
    [Console]::SetCursorPosition(0, $script:dlBarRow + 1)
}

# ════════════════════════════════════════════════════════════
#  STARTUP SCAN — detect already-installed apps via winget
# ════════════════════════════════════════════════════════════
function Start-InstalledScan {
    [Console]::CursorVisible = $false
    Clear-Host
    $W = [Console]::WindowWidth
    [Console]::Write("`n$($BG.Cyan)$($FG.Black)$("  WinTools  *  Scanning installed packages...".PadRight($W))$RESET`n`n")
    [Console]::Write("  $($FG.DarkGray)Please wait while winget checks installed software...$RESET`n`n")

    $spinChars = @('|','/','-','\')
    $spinIdx   = 0

    $job = Start-Job -ScriptBlock {
        & winget list --accept-source-agreements 2>$null
    }

    while ($job.State -eq 'Running') {
        [Console]::SetCursorPosition(2, 4)
        [Console]::Write("$($FG.Cyan)$($spinChars[$spinIdx % 4]) Querying winget...            $RESET")
        $spinIdx++
        Start-Sleep -Milliseconds 80
    }

    $lines   = Receive-Job $job 2>$null
    Remove-Job $job -Force
    $rawText = $lines -join "`n"

    # Parse winget list as a fixed-width table — find the Id column position
    # and extract exact IDs to avoid false positives from substring matching.
    $parsedIDs = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    $headerIdx  = -1
    $idColStart = -1
    $idColEnd   = -1

    for ($li = 0; $li -lt $lines.Count; $li++) {
        $ln = "$($lines[$li])"
        # Header line contains both "Name" and "Id" and "Version"
        if ($ln -match '\bName\b' -and $ln -match '\bId\b' -and $ln -match '\bVersion\b') {
            $headerIdx  = $li
            $idColStart = $ln.IndexOf('Id')
            $versionPos = $ln.IndexOf('Version')
            if ($versionPos -gt $idColStart) { $idColEnd = $versionPos }
            break
        }
    }

    if ($headerIdx -ge 0 -and $idColStart -ge 0) {
        # Skip header row and separator (dashes) row
        for ($li = $headerIdx + 2; $li -lt $lines.Count; $li++) {
            $ln = "$($lines[$li])"
            if ($ln.Length -le $idColStart) { continue }
            $extracted = if ($idColEnd -gt 0 -and $ln.Length -gt $idColEnd) {
                $ln.Substring($idColStart, $idColEnd - $idColStart).Trim()
            } else {
                $ln.Substring($idColStart).Trim().Split(' ')[0]
            }
            if ($extracted -ne '') { [void]$parsedIDs.Add($extracted) }
        }
        # Match parsed IDs exactly against our app database
        foreach ($app in $ALL_APPS) {
            if ($parsedIDs.Contains($app.ID)) { [void]$installedIDs.Add($app.ID) }
        }
    } else {
        # Fallback if table parse failed: word-boundary match (better than bare substring)
        foreach ($app in $ALL_APPS) {
            $escaped = [regex]::Escape($app.ID)
            if ($rawText -match "(?i)(^|\s)${escaped}(\s|$)") {
                [void]$installedIDs.Add($app.ID)
            }
        }
    }

    $count = $installedIDs.Count
    [Console]::SetCursorPosition(2, 4)
    [Console]::Write("  $($FG.Green)+ Found $count installed app(s) from the list$RESET                     `n")
    Start-Sleep -Milliseconds 500
    Clear-Host
}

# ════════════════════════════════════════════════════════════
#  SEARCH
# ════════════════════════════════════════════════════════════
function Get-Filtered {
    if ($searchStr -eq "") { return $ALL_APPS }
    $q = $searchStr.ToLower().Trim()
    if ($q -match '^(?:category|cat:?)\s+(.+)$') {
        $catQ = $matches[1].Trim()
        return $ALL_APPS | Where-Object { $_.Cat.ToLower() -eq $catQ }
    }
    return $ALL_APPS | Where-Object {
        $_.Name.ToLower().Contains($q) -or $_.Cat.ToLower().Contains($q)
    }
}

# ════════════════════════════════════════════════════════════
#  DRAW — single Console::Write per frame
# ════════════════════════════════════════════════════════════
function Draw {
    param($filtered)

    $W     = [Console]::WindowWidth
    $H     = [Console]::WindowHeight
    $listH = $H - 7
    $total = $filtered.Count

    $half      = [int]($listH / 2)
    $scrollTop = [Math]::Max(0, $cursor - $half)
    $scrollTop = [Math]::Min($scrollTop, [Math]::Max(0, $total - $listH))

    $sb = New-Object System.Text.StringBuilder ($W * ($H + 2) * 8)
    [void]$sb.Append("$ESC[H")

    # Title
    $tl  = "  WinTools  *  Installer  "
    $tr  = "  F5=update-all   Esc=exit  "
    $gap = [Math]::Max(1, $W - $tl.Length - $tr.Length)
    [void]$sb.Append("$($BG.Cyan)$($FG.Black)$(($tl + (' ' * $gap) + $tr).PadRight($W))$RESET`n")

    # Search bar
    $srchText = "  [?]  ${searchStr}> "
    $srchHint = "  name or category  |  cat:dev  cat:gaming  |  arrows Space Tab Enter  "
    $gap2     = [Math]::Max(1, $W - $srchText.Length - $srchHint.Length)
    $srchLine = ($srchText + (" " * $gap2) + $srchHint).PadRight($W)
    if ($searchStr.Length -gt 0) {
        [void]$sb.Append("$($BG.DarkBlue)$($FG.White)${srchLine}$RESET`n")
    } else {
        [void]$sb.Append("$($FG.DarkGray)${srchLine}$RESET`n")
    }

    # Legend
    [void]$sb.Append("$($FG.DarkGray)  $($CAT_LEGEND.PadRight($W - 2))$RESET`n")

    # Headers
    $catW  = 10
    $nameW = $W - $catW - 7
    [void]$sb.Append("$($FG.DarkGray)$(('     ' + 'NAME'.PadRight($nameW) + 'CATEGORY  ').PadRight($W))$RESET`n")
    [void]$sb.Append("$($FG.DarkGray)$('─' * $W)$RESET`n")

    # Rows
    for ($row = 0; $row -lt $listH; $row++) {
        $i = $scrollTop + $row
        if ($i -ge $total) { [void]$sb.Append("$ESC[2K`n"); continue }

        $app         = $filtered[$i]
        $isChecked   = $checked.Contains($i)
        $isCursor    = ($i -eq $cursor)
        $isInstalled = $installedIDs.Contains($app.ID)
        $catFg       = if ($CAT_FG[$app.Cat]) { $CAT_FG[$app.Cat] } else { $FG.Gray }

        # Box icon: checked=[*]  installed=[ ✓ ]  plain=[ ]
        $box = if ($isChecked)   { " [*] " }
               elseif ($isInstalled) { " [+] " }
               else { " [ ] " }

        $dispName = if ($app.Name.Length -gt $nameW) { $app.Name.Substring(0,$nameW-1) + "~" } else { $app.Name }
        $namePad  = $dispName.PadRight($nameW)
        $catPad   = ("[" + $app.Cat + "]").PadRight($catW)

        if ($isInstalled) {
            # Installed: full green row
            $boxFg  = if ($isChecked) { $FG.Yellow } else { $FG.Green }
            $nameFg = $FG.Green
            if ($isCursor) {
                [void]$sb.Append("$($BG.DarkGray)${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
            } else {
                [void]$sb.Append("${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
            }
        } elseif ($isCursor) {
            $boxFg  = if ($isChecked) { $FG.Green } else { $FG.Gray }
            $nameFg = if ($isChecked) { $FG.White } else { $FG.Gray }
            [void]$sb.Append("$($BG.DarkGray)${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
        } else {
            $boxFg  = if ($isChecked) { $FG.Green } else { $FG.DarkGray }
            $nameFg = if ($isChecked) { $FG.White } else { $FG.Gray }
            [void]$sb.Append("${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
        }
    }

    # Status bar
    [void]$sb.Append("$($FG.DarkGray)$('─' * $W)$RESET`n")
    $selCnt    = $checked.Count
    $instCount = $installedIDs.Count
    $pct = if ($total -le $listH -or $total -eq 0) { 100 } else {
        [int](($scrollTop / ([Math]::Max(1, $total - $listH))) * 100)
    }
    $sl = "  $total shown   $selCnt selected   $($FG.Green)[+] $instCount installed$($FG.DarkGray)   Enter=install  Space=check  Tab=all"
    $sr = "$($cursor+1)/$total  $pct%  "
    [void]$sb.Append("$($FG.DarkGray)$($sl.PadRight($W - $sr.Length) + $sr)$RESET")

    [Console]::Write($sb.ToString())
}

# ════════════════════════════════════════════════════════════
#  WINGET PROGRESS BAR
# ════════════════════════════════════════════════════════════
function Invoke-WingetWithProgress {
    param([string]$AppID)

    $script:wgBarWidth = 30
    [Console]::Write("  $($FG.DarkGray)Starting winget...$RESET`n")
    [Console]::Write("  $($FG.Cyan)[$('.' * $script:wgBarWidth)]   0%$RESET  `n")
    $script:wgBarRow = [Console]::CursorTop - 1
    $phase   = "Downloading"
    $percent = 0

    $job = Start-Job -ScriptBlock {
        param($id)
        & winget install --id $id --silent `
            --accept-package-agreements `
            --accept-source-agreements 2>&1
    } -ArgumentList $AppID

    while ($job.State -eq 'Running') {
        $lines = Receive-Job $job -Keep 2>$null
        foreach ($ln in $lines) {
            $s = "$ln".Trim()
            if ($s -match 'Download')             { $phase = "Downloading" }
            elseif ($s -match 'Install|Configur') { $phase = "Installing " }
            elseif ($s -match 'Hash|Validat')     { $phase = "Verifying  " }
            if ($s -match '(\d{1,3})\s*%') {
                $p = [int]$matches[1]
                if ($p -ge $percent) { $percent = $p }
            }
        }
        Write-WingetBar $percent $phase
        Start-Sleep -Milliseconds 120
    }

    $allLines = Receive-Job $job 2>$null
    Remove-Job $job -Force
    foreach ($ln in $allLines) {
        if ("$ln" -match '(\d{1,3})\s*%') {
            $p = [int]$matches[1]
            if ($p -ge $percent) { $percent = $p }
        }
    }
    Write-WingetBar 100 "Done       "
    Start-Sleep -Milliseconds 150

    return $LASTEXITCODE
}

# ════════════════════════════════════════════════════════════
#  SMART FALLBACK
#
#  Three-stage strategy (silent → silent → GUI last resort):
#   1. Download installer from FallbackURL with progress bar
#   2. Try fully silent install (/VERYSILENT or /qn for MSI)
#   3. If silent fails → launch GUI installer and wait for user
# ════════════════════════════════════════════════════════════
function Invoke-SmartFallback {
    param($app)

    $url = $app.FallbackURL

    if (-not $url -or $url -eq "") {
        [Console]::Write("  $($FG.Red)x No fallback URL defined$RESET`n`n")
        return $false
    }

    # Detect extension from URL
    $ext = ".exe"
    if ($url -match '\.msi(\?|$)')        { $ext = ".msi" }
    elseif ($url -match '\.zip(\?|$)')    { $ext = ".zip" }
    elseif ($url -match '\.7z(\?|$)')     { $ext = ".7z" }
    elseif ($url -match '\.msixbundle(\?|$)') { $ext = ".msixbundle" }

    $safeAppName = $app.Name -replace '[^a-zA-Z0-9_]', '_'
    $tmpFile     = "$env:TEMP\wintools_${safeAppName}${ext}"

    # ── Stage 1: Download with progress bar ───────────────
    [Console]::Write("  $($FG.Cyan)>> Fallback: downloading installer...$RESET`n")

    $script:dlBarWidth = 30
    [Console]::Write("  $($FG.DarkGray)[$('.' * $script:dlBarWidth)]   0%$RESET`n")
    $script:dlBarRow = [Console]::CursorTop - 1

    $dlSuccess = $false
    $script:dlPercent = 0

    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

        $null = Register-ObjectEvent -InputObject $wc -EventName DownloadProgressChanged `
            -SourceIdentifier "WTDLProg" -Action {
                $script:dlPercent = $Event.SourceEventArgs.ProgressPercentage
            }

        $wc.DownloadFileAsync([uri]$url, $tmpFile)

        while ($wc.IsBusy) {
            Write-DownloadBar ([int]$script:dlPercent)
            Start-Sleep -Milliseconds 100
        }

        # Draw 100%
        $bar = "$([char]0x2588)" * $script:dlBarWidth
        [Console]::SetCursorPosition(0, $script:dlBarRow)
        [Console]::Write("$ESC[2K  $($FG.Green)[${bar}]  100% downloaded $RESET")
        [Console]::SetCursorPosition(0, $script:dlBarRow + 1)

        Unregister-Event -SourceIdentifier "WTDLProg" -ErrorAction SilentlyContinue
        Remove-Event      -SourceIdentifier "WTDLProg" -ErrorAction SilentlyContinue

        $dlSuccess = (Test-Path $tmpFile) -and ((Get-Item $tmpFile).Length -gt 8192)
    }
    catch {
        Unregister-Event -SourceIdentifier "WTDLProg" -ErrorAction SilentlyContinue
        [Console]::Write("`n  $($FG.Red)x Download error: $($_.Exception.Message)$RESET`n")
    }

    if (-not $dlSuccess) {
        [Console]::Write("  $($FG.Yellow)~ Download failed — opening download page in browser$RESET`n`n")
        Start-Process $url
        return $false
    }

    [Console]::Write("`n  $($FG.Cyan)>> Running silent install...$RESET`n")

    # ── Stage 2: Silent install ────────────────────────────
    $exitCode = -1
    try {
        if ($ext -eq ".msi") {
            $proc     = Start-Process "msiexec.exe" `
                -ArgumentList "/i `"$tmpFile`" /qn /norestart" `
                -Wait -PassThru -NoNewWindow
            $exitCode = $proc.ExitCode
        }
        elseif ($ext -eq ".msixbundle") {
            Add-AppxPackage -Path $tmpFile -ErrorAction Stop
            $exitCode = 0
        }
        elseif ($ext -eq ".zip") {
            [Console]::Write("  $($FG.Yellow)~ Archive — extracting to Desktop\$($app.Name)...$RESET`n")
            Expand-Archive -Path $tmpFile `
                -DestinationPath "$env:USERPROFILE\Desktop\$($app.Name)" `
                -Force -ErrorAction Stop
            [Console]::Write("  $($FG.Green)+ Extracted to Desktop\$($app.Name)$RESET`n`n")
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
            [void]$installedIDs.Add($app.ID)
            return $true
        }
        elseif ($ext -eq ".7z") {
            # 7z archives: try 7-Zip CLI first, fallback to Expand-Archive won't work
            $szCmd  = Get-Command "7z.exe" -ErrorAction SilentlyContinue
            $szPath = if ($szCmd) { $szCmd.Source } else { $null }
            if ($szPath) {
                & $szPath x "$tmpFile" -o"$env:USERPROFILE\Desktop\$($app.Name)" -y | Out-Null
            } else {
                [Console]::Write("  $($FG.Yellow)~ 7z archive — 7-Zip not found; opening file location...$RESET`n")
                Start-Process "explorer.exe" "/select,`"$tmpFile`""
            }
            [Console]::Write("  $($FG.Green)+ Extracted to Desktop\$($app.Name)$RESET`n`n")
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
            [void]$installedIDs.Add($app.ID)
            return $true
        }
        else {
            # .exe — try Inno Setup style first (/VERYSILENT)
            $proc = Start-Process $tmpFile `
                -ArgumentList "/VERYSILENT /NORESTART /SP-" `
                -Wait -PassThru -NoNewWindow
            $exitCode = $proc.ExitCode

            # If that failed, try NSIS-style (/S)
            if ($exitCode -notin @(0, 1641, 3010)) {
                $proc = Start-Process $tmpFile `
                    -ArgumentList "/S /norestart" `
                    -Wait -PassThru -NoNewWindow
                $exitCode = $proc.ExitCode
            }
        }
    }
    catch {
        [Console]::Write("  $($FG.Yellow)~ Silent install exception: $($_.Exception.Message)$RESET`n")
        $exitCode = -99
    }

    # ── Stage 3: Check — if OK done, else show GUI ─────────
    if ($exitCode -in @(0, 1641, 3010)) {
        [Console]::Write("  $($FG.Green)+ Silent install complete$RESET`n`n")
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        [void]$installedIDs.Add($app.ID)
        return $true
    }

    # Last resort: run installer GUI and wait
    [Console]::Write("  $($FG.Yellow)! Silent flags failed (exit $exitCode) — showing installer GUI$RESET`n")
    [Console]::Write("  $($FG.DarkGray)Finish the wizard, then press any key here...$RESET`n")
    Start-Process $tmpFile
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    [void]$installedIDs.Add($app.ID)
    [Console]::Write("`n")
    return $true
}

# ════════════════════════════════════════════════════════════
#  INSTALL SCREEN
# ════════════════════════════════════════════════════════════
function Run-Install {
    param($toInstall)

    [Console]::CursorVisible = $false
    Clear-Host

    $W     = [Console]::WindowWidth
    $total = $toInstall.Count
    $done  = 0; $skipped = 0; $failed = 0; $fallback = 0; $i = 0

    [Console]::Write("`n$($FG.DarkGray)$('─' * $W)$RESET`n")
    [Console]::Write("  $($FG.Cyan)Installing $total app(s)...$RESET`n")
    [Console]::Write("$($FG.DarkGray)$('─' * $W)$RESET`n`n")

    foreach ($app in $toInstall) {
        $i++
        $catFg = if ($CAT_FG[$app.Cat]) { $CAT_FG[$app.Cat] } else { $FG.Gray }
        [Console]::Write("  $($FG.DarkGray)[$i/$total] $($FG.White)$($app.Name)  $catFg[$($app.Cat)]$RESET`n")

        # winget with live progress
        $code = Invoke-WingetWithProgress -AppID $app.ID
        [Console]::Write("`n")

        $info = $WINGET_CODES[$code]

        if ($info) {
            [Console]::Write("  $($info.C)[$($info.S)] $($info.M)$RESET`n")

            if ($info.FB) {
                $ok = Invoke-SmartFallback $app
                if ($ok) { $fallback++ } else { $failed++ }
            }
            elseif ($code -eq 0) {
                [void]$installedIDs.Add($app.ID)
                $done++
                [Console]::Write("`n")
            }
            elseif ($code -eq -1978335153) {
                $failed++
                [Console]::Write("`n")
            }
            else {
                $skipped++
                [Console]::Write("`n")
            }
        }
        else {
            [Console]::Write("  $($FG.Red)[x] Failed (code $code) — trying smart fallback$RESET`n")
            $ok = Invoke-SmartFallback $app
            if ($ok) { $fallback++ } else { $failed++ }
        }
    }

    [Console]::Write("$($FG.DarkGray)$('─' * $W)$RESET`n")
    [Console]::Write("  $($FG.Cyan)+ $done installed   ~ $fallback via fallback   o $skipped skipped   x $failed failed$RESET`n`n")
    [Console]::Write("  $($FG.DarkGray)Press any key to go back...$RESET`n")
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [Console]::CursorVisible = $false
    Clear-Host
}

# ════════════════════════════════════════════════════════════
#  WINGET CHECK
# ════════════════════════════════════════════════════════════
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    [Console]::CursorVisible = $true
    Write-Host "`n  [!] winget not found." -ForegroundColor Red
    Write-Host "      Install App Installer from the Microsoft Store: https://aka.ms/getwinget`n"
    exit 1
}

# ════════════════════════════════════════════════════════════
#  STARTUP — scan installed, then main loop
# ════════════════════════════════════════════════════════════
Start-InstalledScan

while ($true) {
    $filtered = @(Get-Filtered)

    if     ($filtered.Count -eq 0)       { $cursor = 0 }
    elseif ($cursor -ge $filtered.Count) { $cursor = $filtered.Count - 1 }
    elseif ($cursor -lt 0)               { $cursor = 0 }

    Draw $filtered

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $vk  = $key.VirtualKeyCode
    $ch  = $key.Character

    switch ($vk) {
        40 { if ($cursor -lt $filtered.Count-1) { $cursor++ } }
        38 { if ($cursor -gt 0) { $cursor-- } }
        34 { $cursor = [Math]::Min($cursor+10, [Math]::Max(0,$filtered.Count-1)) }
        33 { $cursor = [Math]::Max($cursor-10, 0) }
        36 { $cursor = 0 }
        35 { $cursor = [Math]::Max(0,$filtered.Count-1) }
        32 {   # Space — toggle
            if ($checked.Contains($cursor)) { $checked.Remove($cursor) | Out-Null }
            else { $checked.Add($cursor) | Out-Null }
        }
        9 {    # Tab — select/deselect all visible
            if ($checked.Count -gt 0) { $checked.Clear() }
            else { for ($idx=0; $idx -lt $filtered.Count; $idx++) { $checked.Add($idx) | Out-Null } }
        }
        13 {   # Enter — install
            $toInstall = @()
            if ($checked.Count -gt 0) {
                foreach ($idx in ($checked | Sort-Object)) {
                    if ($idx -lt $filtered.Count) { $toInstall += $filtered[$idx] }
                }
            } elseif ($filtered.Count -gt 0) {
                $toInstall = @($filtered[$cursor])
            }
            if ($toInstall.Count -gt 0) {
                Run-Install $toInstall
                $checked.Clear(); $searchStr = ""; $cursor = 0
            }
        }
        8 {    # Backspace
            if ($searchStr.Length -gt 0) {
                $searchStr = $searchStr.Substring(0, $searchStr.Length-1)
                $cursor = 0
            }
        }
        27 {   # Escape
            if ($searchStr -ne "") { $searchStr = ""; $cursor = 0 }
            else {
                [Console]::CursorVisible = $true
                Clear-Host
                Write-Host "`n  Bye!`n" -ForegroundColor Cyan
                exit
            }
        }
        116 {  # F5 — update all
            [Console]::CursorVisible = $true
            Clear-Host
            Write-Host "`n  Updating all installed apps via winget...`n" -ForegroundColor Cyan
            winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
            Write-Host "`n  Done! Press any key..." -ForegroundColor Green
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            [Console]::CursorVisible = $false
            Clear-Host
        }
        default {
            if ($ch -ge ' ' -and $ch -le '~') {
                $searchStr += $ch
                $cursor     = 0
            }
        }
    }
}
