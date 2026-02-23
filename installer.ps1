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
# ════════════════════════════════════════════════════════════

$ALL_APPS = @(
    # ── Browser ─────────────────────────────────────────────
    [pscustomobject]@{ Name="Brave";                  ID="Brave.Brave";                            Cat="Browser"  }
    [pscustomobject]@{ Name="Google Chrome";          ID="Google.Chrome";                          Cat="Browser"  }
    [pscustomobject]@{ Name="LibreWolf";              ID="LibreWolf.LibreWolf";                    Cat="Browser"  }
    [pscustomobject]@{ Name="Mozilla Firefox";        ID="Mozilla.Firefox";                        Cat="Browser"  }
    [pscustomobject]@{ Name="Opera";                  ID="Opera.Opera";                            Cat="Browser"  }
    [pscustomobject]@{ Name="Opera GX";               ID="Opera.OperaGX";                          Cat="Browser"  }
    [pscustomobject]@{ Name="Tor Browser";            ID="TorProject.TorBrowser";                  Cat="Browser"  }
    [pscustomobject]@{ Name="Vivaldi";                ID="Vivaldi.Vivaldi";                        Cat="Browser"  }
    [pscustomobject]@{ Name="Waterfox";               ID="Waterfox.Waterfox";                      Cat="Browser"  }
    # ── Chat ────────────────────────────────────────────────
    [pscustomobject]@{ Name="Discord";                ID="Discord.Discord";                        Cat="Chat"     }
    [pscustomobject]@{ Name="Element";                ID="Element.Element";                        Cat="Chat"     }
    [pscustomobject]@{ Name="Microsoft Teams";        ID="Microsoft.Teams";                        Cat="Chat"     }
    [pscustomobject]@{ Name="mIRC";                   ID="mIRC.mIRC";                              Cat="Chat"     }
    [pscustomobject]@{ Name="Signal";                 ID="OpenWhisperSystems.Signal";              Cat="Chat"     }
    [pscustomobject]@{ Name="Skype";                  ID="Microsoft.Skype";                        Cat="Chat"     }
    [pscustomobject]@{ Name="Slack";                  ID="SlackTechnologies.Slack";                Cat="Chat"     }
    [pscustomobject]@{ Name="Telegram";               ID="Telegram.TelegramDesktop";               Cat="Chat"     }
    [pscustomobject]@{ Name="Viber";                  ID="Viber.Viber";                            Cat="Chat"     }
    [pscustomobject]@{ Name="WhatsApp";               ID="9NKSQGP7F2NH";                           Cat="Chat"     }
    [pscustomobject]@{ Name="Zoom";                   ID="Zoom.Zoom";                              Cat="Chat"     }
    # ── Design ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Blender";                ID="BlenderFoundation.Blender";              Cat="Design"   }
    [pscustomobject]@{ Name="DaVinci Resolve";        ID="Blackmagic.DaVinciResolve";              Cat="Design"   }
    [pscustomobject]@{ Name="Figma";                  ID="Figma.Figma";                            Cat="Design"   }
    [pscustomobject]@{ Name="GIMP";                   ID="GIMP.GIMP";                              Cat="Design"   }
    [pscustomobject]@{ Name="Inkscape";               ID="Inkscape.Inkscape";                      Cat="Design"   }
    [pscustomobject]@{ Name="Krita";                  ID="KDE.Krita";                              Cat="Design"   }
    [pscustomobject]@{ Name="Paint.NET";              ID="dotPDN.PaintDotNet";                     Cat="Design"   }
    [pscustomobject]@{ Name="Pencil2D";               ID="Pencil2D.Pencil2D";                      Cat="Design"   }
    [pscustomobject]@{ Name="ScreenToGif";            ID="NickeManarin.ScreenToGif";               Cat="Design"   }
    [pscustomobject]@{ Name="ShareX";                 ID="ShareX.ShareX";                          Cat="Design"   }
    [pscustomobject]@{ Name="Storyboarder";           ID="wonderunit.Storyboarder";                Cat="Design"   }
    [pscustomobject]@{ Name="Vectr";                  ID="Vectr.Vectr";                            Cat="Design"   }
    # ── Dev ─────────────────────────────────────────────────
    [pscustomobject]@{ Name="Android Studio";         ID="Google.AndroidStudio";                   Cat="Dev"      }
    [pscustomobject]@{ Name="Dbeaver";                ID="dbeaver.dbeaver";                        Cat="Dev"      }
    [pscustomobject]@{ Name="Docker Desktop";         ID="Docker.DockerDesktop";                   Cat="Dev"      }
    [pscustomobject]@{ Name="Filezilla";              ID="TimKosse.FileZilla.Client";              Cat="Dev"      }
    [pscustomobject]@{ Name="Git";                    ID="Git.Git";                                Cat="Dev"      }
    [pscustomobject]@{ Name="GitHub Desktop";         ID="GitHub.GitHubDesktop";                   Cat="Dev"      }
    [pscustomobject]@{ Name="Go";                     ID="GoLang.Go";                              Cat="Dev"      }
    [pscustomobject]@{ Name="HeidiSQL";               ID="HeidiSQL.HeidiSQL";                      Cat="Dev"      }
    [pscustomobject]@{ Name="Insomnia";               ID="Insomnia.Insomnia";                      Cat="Dev"      }
    [pscustomobject]@{ Name="JetBrains Toolbox";      ID="JetBrains.Toolbox";                      Cat="Dev"      }
    [pscustomobject]@{ Name="MobaXterm";              ID="Mobatek.MobaXterm";                      Cat="Dev"      }
    [pscustomobject]@{ Name="Node.js LTS";            ID="OpenJS.NodeJS.LTS";                      Cat="Dev"      }
    [pscustomobject]@{ Name="Notepad++";              ID="Notepad++.Notepad++";                    Cat="Dev"      }
    [pscustomobject]@{ Name="oh-my-posh";             ID="JanDeDobbeleer.OhMyPosh";               Cat="Dev"      }
    [pscustomobject]@{ Name="Postman";                ID="Postman.Postman";                        Cat="Dev"      }
    [pscustomobject]@{ Name="PyCharm Community";      ID="JetBrains.PyCharm.Community";            Cat="Dev"      }
    [pscustomobject]@{ Name="Python 3";               ID="Python.Python.3";                        Cat="Dev"      }
    [pscustomobject]@{ Name="Ruby";                   ID="RubyInstallerTeam.Ruby";                 Cat="Dev"      }
    [pscustomobject]@{ Name="Rust";                   ID="Rustlang.Rustup";                        Cat="Dev"      }
    [pscustomobject]@{ Name="TablePlus";              ID="TablePlus.TablePlus";                    Cat="Dev"      }
    [pscustomobject]@{ Name="Visual Studio Code";     ID="Microsoft.VisualStudioCode";             Cat="Dev"      }
    [pscustomobject]@{ Name="Visual Studio 2022 Community"; ID="Microsoft.VisualStudio.2022.Community"; Cat="Dev" }
    [pscustomobject]@{ Name="Windows Terminal";       ID="Microsoft.WindowsTerminal";              Cat="Dev"      }
    [pscustomobject]@{ Name="WinSCP";                 ID="WinSCP.WinSCP";                          Cat="Dev"      }
    # ── Gaming ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Battle.net";             ID="Blizzard.BattleNet";                     Cat="Gaming"   }
    [pscustomobject]@{ Name="Cemu (Wii U)";           ID="Cemu.Cemu";                              Cat="Gaming"   }
    [pscustomobject]@{ Name="Dolphin Emulator";       ID="DolphinEmu.Dolphin";                     Cat="Gaming"   }
    [pscustomobject]@{ Name="DS4Windows";             ID="Ryochan7.DS4Windows";                    Cat="Gaming"   }
    [pscustomobject]@{ Name="EA App";                 ID="ElectronicArts.EADesktop";               Cat="Gaming"   }
    [pscustomobject]@{ Name="Epic Games";             ID="EpicGames.EpicGamesLauncher";            Cat="Gaming"   }
    [pscustomobject]@{ Name="GOG Galaxy";             ID="GOG.Galaxy";                             Cat="Gaming"   }
    [pscustomobject]@{ Name="Heroic Games Launcher";  ID="HeroicGamesLauncher.HeroicGamesLauncher"; Cat="Gaming"  }
    [pscustomobject]@{ Name="Itch.io";                ID="itch.io";                                Cat="Gaming"   }
    [pscustomobject]@{ Name="MAME";                   ID="MAMEDEV.MAME";                           Cat="Gaming"   }
    [pscustomobject]@{ Name="PCSX2 (PS2)";            ID="PCSX2.PCSX2";                            Cat="Gaming"   }
    [pscustomobject]@{ Name="PPSSPP (PSP)";           ID="PPSSPP.PPSSPP";                          Cat="Gaming"   }
    [pscustomobject]@{ Name="Playnite";               ID="Playnite.Playnite";                      Cat="Gaming"   }
    [pscustomobject]@{ Name="RetroArch";              ID="Libretro.RetroArch";                     Cat="Gaming"   }
    [pscustomobject]@{ Name="Ryujinx (Switch)";       ID="Ryujinx.Ryujinx";                        Cat="Gaming"   }
    [pscustomobject]@{ Name="Steam";                  ID="Valve.Steam";                            Cat="Gaming"   }
    [pscustomobject]@{ Name="Ubisoft Connect";        ID="Ubisoft.Connect";                        Cat="Gaming"   }
    [pscustomobject]@{ Name="Xbox";                   ID="9MV0B5HZVK9Z";                           Cat="Gaming"   }
    # ── Media ───────────────────────────────────────────────
    [pscustomobject]@{ Name="Audacity";               ID="Audacity.Audacity";                      Cat="Media"    }
    [pscustomobject]@{ Name="Clementine";             ID="Clementine-Player.Clementine";           Cat="Media"    }
    [pscustomobject]@{ Name="foobar2000";             ID="PeterPawlowski.foobar2000";              Cat="Media"    }
    [pscustomobject]@{ Name="HandBrake";              ID="HandBrake.HandBrake";                    Cat="Media"    }
    [pscustomobject]@{ Name="iTunes";                 ID="Apple.iTunes";                           Cat="Media"    }
    [pscustomobject]@{ Name="K-Lite Codec Pack";      ID="CodecGuide.K-LiteCodecPack.Full";        Cat="Media"    }
    [pscustomobject]@{ Name="Kdenlive";               ID="KDE.Kdenlive";                           Cat="Media"    }
    [pscustomobject]@{ Name="MPC-HC";                 ID="clsid2.mpc-hc";                         Cat="Media"    }
    [pscustomobject]@{ Name="MPV";                    ID="mpv-player.mpv";                         Cat="Media"    }
    [pscustomobject]@{ Name="MusicBee";               ID="MusicBee.MusicBee";                      Cat="Media"    }
    [pscustomobject]@{ Name="OBS Studio";             ID="OBSProject.OBSStudio";                  Cat="Media"    }
    [pscustomobject]@{ Name="Plex";                   ID="Plex.Plexamp";                           Cat="Media"    }
    [pscustomobject]@{ Name="Shotcut";                ID="Meltytech.Shotcut";                      Cat="Media"    }
    [pscustomobject]@{ Name="Spotify";                ID="Spotify.Spotify";                        Cat="Media"    }
    [pscustomobject]@{ Name="Stremio";                ID="Stremio.Stremio";                        Cat="Media"    }
    [pscustomobject]@{ Name="VLC";                    ID="VideoLAN.VLC";                           Cat="Media"    }
    [pscustomobject]@{ Name="Winamp";                 ID="Winamp.Winamp";                          Cat="Media"    }
    [pscustomobject]@{ Name="YouTube Music";          ID="th-ch.YouTubeMusic";                     Cat="Media"    }
    # ── Office ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Bitwarden";              ID="Bitwarden.Bitwarden";                    Cat="Office"   }
    [pscustomobject]@{ Name="CherryTree";             ID="giuspen.cherrytree";                     Cat="Office"   }
    [pscustomobject]@{ Name="Drawio";                 ID="JGraph.Draw";                            Cat="Office"   }
    [pscustomobject]@{ Name="Joplin";                 ID="Joplin.Joplin";                          Cat="Office"   }
    [pscustomobject]@{ Name="KeePassXC";              ID="KeePassXCTeam.KeePassXC";               Cat="Office"   }
    [pscustomobject]@{ Name="LibreOffice";            ID="TheDocumentFoundation.LibreOffice";      Cat="Office"   }
    [pscustomobject]@{ Name="Logseq";                 ID="Logseq.Logseq";                          Cat="Office"   }
    [pscustomobject]@{ Name="Notion";                 ID="Notion.Notion";                          Cat="Office"   }
    [pscustomobject]@{ Name="Obsidian";               ID="Obsidian.Obsidian";                      Cat="Office"   }
    [pscustomobject]@{ Name="PDF24 Creator";          ID="geek-software.PDF24Creator";             Cat="Office"   }
    [pscustomobject]@{ Name="Sumatra PDF";            ID="SumatraPDF.SumatraPDF";                  Cat="Office"   }
    [pscustomobject]@{ Name="Thunderbird";            ID="Mozilla.Thunderbird";                    Cat="Office"   }
    [pscustomobject]@{ Name="Todoist";                ID="Doist.Todoist";                          Cat="Office"   }
    [pscustomobject]@{ Name="Zotero";                 ID="Zotero.Zotero";                          Cat="Office"   }
    # ── Security ────────────────────────────────────────────
    [pscustomobject]@{ Name="Bitwarden";              ID="Bitwarden.Bitwarden";                    Cat="Security" }
    [pscustomobject]@{ Name="KeePassXC";              ID="KeePassXCTeam.KeePassXC";               Cat="Security" }
    [pscustomobject]@{ Name="Malwarebytes";           ID="Malwarebytes.Malwarebytes";              Cat="Security" }
    [pscustomobject]@{ Name="Nmap";                   ID="Insecure.Nmap";                          Cat="Security" }
    [pscustomobject]@{ Name="OpenVPN";                ID="OpenVPNTechnologies.OpenVPN";            Cat="Security" }
    [pscustomobject]@{ Name="Revo Uninstaller";       ID="RevoUninstaller.RevoUninstaller";        Cat="Security" }
    [pscustomobject]@{ Name="Veracrypt";              ID="IDRIX.VeraCrypt";                        Cat="Security" }
    [pscustomobject]@{ Name="Wireshark";              ID="WiresharkFoundation.Wireshark";          Cat="Security" }
    [pscustomobject]@{ Name="WireGuard";              ID="WireGuard.WireGuard";                    Cat="Security" }
    # ── Utils ───────────────────────────────────────────────
    [pscustomobject]@{ Name="7-Zip";                  ID="7zip.7zip";                              Cat="Utils"    }
    [pscustomobject]@{ Name="Autoruns";               ID="Microsoft.Sysinternals.Autoruns";        Cat="Utils"    }
    [pscustomobject]@{ Name="Bulk Rename Utility";    ID="TGRMNSoftware.BulkRenameUtility";        Cat="Utils"    }
    [pscustomobject]@{ Name="CPU-Z";                  ID="CPUID.CPU-Z";                            Cat="Utils"    }
    [pscustomobject]@{ Name="CrystalDiskInfo";        ID="CrystalDewWorld.CrystalDiskInfo";        Cat="Utils"    }
    [pscustomobject]@{ Name="CrystalDiskMark";        ID="CrystalDewWorld.CrystalDiskMark";        Cat="Utils"    }
    [pscustomobject]@{ Name="Ditto (clipboard)";      ID="Ditto.Ditto";                            Cat="Utils"    }
    [pscustomobject]@{ Name="Everything";             ID="voidtools.Everything";                   Cat="Utils"    }
    [pscustomobject]@{ Name="GPU-Z";                  ID="TechPowerUp.GPU-Z";                      Cat="Utils"    }
    [pscustomobject]@{ Name="HWiNFO";                 ID="REALiX.HWiNFO";                         Cat="Utils"    }
    [pscustomobject]@{ Name="HWMonitor";              ID="CPUID.HWMonitor";                        Cat="Utils"    }
    [pscustomobject]@{ Name="MSI Afterburner";        ID="MSI.Afterburner";                        Cat="Utils"    }
    [pscustomobject]@{ Name="NirSoft NirLauncher";    ID="Nirsoft.NirLauncher";                    Cat="Utils"    }
    [pscustomobject]@{ Name="PowerToys";              ID="Microsoft.PowerToys";                    Cat="Utils"    }
    [pscustomobject]@{ Name="Process Hacker";         ID="wj32.ProcessHacker";                     Cat="Utils"    }
    [pscustomobject]@{ Name="Rufus";                  ID="Rufus.Rufus";                            Cat="Utils"    }
    [pscustomobject]@{ Name="Speccy";                 ID="Piriform.Speccy";                        Cat="Utils"    }
    [pscustomobject]@{ Name="TreeSize Free";          ID="JAMSoftware.TreeSize.Free";              Cat="Utils"    }
    [pscustomobject]@{ Name="Ventoy";                 ID="Ventoy.Ventoy";                          Cat="Utils"    }
    [pscustomobject]@{ Name="WinDirStat";             ID="WinDirStat.WinDirStat";                  Cat="Utils"    }
    [pscustomobject]@{ Name="WinRAR";                 ID="RARLab.WinRAR";                          Cat="Utils"    }
    [pscustomobject]@{ Name="WizTree";                ID="AntibodySoftware.WizTree";               Cat="Utils"    }
) | Sort-Object Name

# ════════════════════════════════════════════════════════════
#  ANSI COLOR MAP  — raw escape codes, zero Write-Host overhead
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
#  STATE
# ════════════════════════════════════════════════════════════
$checked   = [System.Collections.Generic.HashSet[int]]::new()
$cursor    = 0
$searchStr = ""

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
#  DRAW  — builds entire frame in a StringBuilder, then ONE Console::Write
#          eliminates flicker and is ~10x faster than per-line Write-Host
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

    # Pre-allocate buffer
    $sb = [System.Text.StringBuilder]::new($W * ($H + 2) * 8)

    # Move to top-left (no Clear-Host = no flicker)
    [void]$sb.Append("$ESC[H")

    # ── Title bar ───────────────────────────────────────────
    $tl  = "  merybist-scripts  *  Installer  "
    $tr  = "  F5=update-all   Esc=exit  "
    $gap = [Math]::Max(1, $W - $tl.Length - $tr.Length)
    $titleLine = ($tl + (" " * $gap) + $tr).PadRight($W)
    [void]$sb.Append("$($BG.Cyan)$($FG.Black)${titleLine}$RESET`n")

    # ── Search bar ──────────────────────────────────────────
    $srchText = "  [?]  ${searchStr}> "
    $srchHint = "  name or category  |  cat:dev  cat:gaming  |  arrows Space Tab Enter  "
    $gap2     = [Math]::Max(1, $W - $srchText.Length - $srchHint.Length)
    $srchLine = ($srchText + (" " * $gap2) + $srchHint).PadRight($W)
    if ($searchStr.Length -gt 0) {
        [void]$sb.Append("$($BG.DarkBlue)$($FG.White)${srchLine}$RESET`n")
    } else {
        [void]$sb.Append("$($FG.DarkGray)${srchLine}$RESET`n")
    }

    # ── Legend ──────────────────────────────────────────────
    [void]$sb.Append("$($FG.DarkGray)  $($CAT_LEGEND.PadRight($W - 2))$RESET`n")

    # ── Column headers ──────────────────────────────────────
    $catW  = 10
    $nameW = $W - $catW - 7
    $hdr   = ("     " + "NAME".PadRight($nameW) + "CATEGORY  ").PadRight($W)
    [void]$sb.Append("$($FG.DarkGray)${hdr}$RESET`n")
    [void]$sb.Append("$($FG.DarkGray)$("─" * $W)$RESET`n")

    # ── App rows ────────────────────────────────────────────
    for ($row = 0; $row -lt $listH; $row++) {
        $i = $scrollTop + $row

        if ($i -ge $total) {
            [void]$sb.Append("$ESC[2K`n")
            continue
        }

        $app       = $filtered[$i]
        $isChecked = $checked.Contains($i)
        $isCursor  = ($i -eq $cursor)
        $catFg     = if ($CAT_FG[$app.Cat]) { $CAT_FG[$app.Cat] } else { $FG.Gray }

        $box      = if ($isChecked) { " [*] " } else { " [ ] " }
        $dispName = if ($app.Name.Length -gt $nameW) { $app.Name.Substring(0,$nameW-1) + "~" } else { $app.Name }
        $namePad  = $dispName.PadRight($nameW)
        $catPad   = ("[" + $app.Cat + "]").PadRight($catW)

        if ($isCursor) {
            $bg     = $BG.DarkGray
            $boxFg  = if ($isChecked) { $FG.Green } else { $FG.Gray }
            $nameFg = if ($isChecked) { $FG.White } else { $FG.Gray }
            [void]$sb.Append("${bg}${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
        } else {
            $boxFg  = if ($isChecked) { $FG.Green } else { $FG.DarkGray }
            $nameFg = if ($isChecked) { $FG.White } else { $FG.Gray }
            [void]$sb.Append("${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
        }
    }

    # ── Status bar ──────────────────────────────────────────
    [void]$sb.Append("$($FG.DarkGray)$("─" * $W)$RESET`n")

    $selCnt = $checked.Count
    $pct = if ($total -le $listH -or $total -eq 0) { 100 } else {
        [int](($scrollTop / ([Math]::Max(1, $total - $listH))) * 100)
    }
    $sl = "  $total shown   $selCnt selected   Enter=install selected (or current)"
    $sr = "$($cursor+1)/$total  $pct%  "
    $statusLine = $sl.PadRight($W - $sr.Length) + $sr
    [void]$sb.Append("$($FG.DarkGray)${statusLine}$RESET")

    # ONE write call — renders entire frame atomically, no flicker
    [Console]::Write($sb.ToString())
}

# ════════════════════════════════════════════════════════════
#  INSTALL SCREEN
# ════════════════════════════════════════════════════════════
function Run-Install {
    param($toInstall)

    [Console]::CursorVisible = $true
    Clear-Host

    $W     = [Console]::WindowWidth
    $total = $toInstall.Count
    $done  = 0; $skipped = 0; $failed = 0; $i = 0

    [Console]::Write("`n$($FG.DarkGray)$("─" * $W)$RESET`n")
    [Console]::Write("  $($FG.Cyan)Installing $total app(s)...$RESET`n")
    [Console]::Write("$($FG.DarkGray)$("─" * $W)$RESET`n`n")

    foreach ($app in $toInstall) {
        $i++
        $pct   = [int](($i / $total) * 100)
        $filled = [int]($pct / 4)
        $bar   = ("=" * $filled).PadRight(25, "-")
        $catFg = if ($CAT_FG[$app.Cat]) { $CAT_FG[$app.Cat] } else { $FG.Gray }

        [Console]::Write("  $($FG.DarkGray)[$i/$total] $($FG.White)$($app.Name)  $catFg[$($app.Cat)]$RESET`n")
        [Console]::Write("  $($FG.Cyan)[$bar] $pct%$RESET`n")

        winget install --id $app.ID --silent `
            --accept-package-agreements `
            --accept-source-agreements 2>&1 | Out-Null

        switch ($LASTEXITCODE) {
            0           { $done++;    [Console]::Write("  $($FG.Green)+ Installed$RESET`n`n") }
            -1978335189 { $skipped++; [Console]::Write("  $($FG.Yellow)o Already installed$RESET`n`n") }
            -1978335215 { $skipped++; [Console]::Write("  $($FG.Yellow)o Already installed$RESET`n`n") }
            default     { $failed++;  [Console]::Write("  $($FG.Red)x Failed (code $LASTEXITCODE)$RESET`n`n") }
        }
    }

    [Console]::Write("$($FG.DarkGray)$("─" * $W)$RESET`n")
    [Console]::Write("  $($FG.Cyan)+ $done installed   o $skipped skipped   x $failed failed$RESET`n`n")
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
#  MAIN LOOP
# ════════════════════════════════════════════════════════════
Clear-Host

while ($true) {
    $filtered = @(Get-Filtered)

    if     ($filtered.Count -eq 0)           { $cursor = 0 }
    elseif ($cursor -ge $filtered.Count)     { $cursor = $filtered.Count - 1 }
    elseif ($cursor -lt 0)                   { $cursor = 0 }

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

        32 {   # Space — toggle check
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
                $checked.Clear()
                $searchStr = ""
                $cursor    = 0
            }
        }
        8 {    # Backspace
            if ($searchStr.Length -gt 0) {
                $searchStr = $searchStr.Substring(0, $searchStr.Length-1)
                $cursor = 0
            }
        }
        27 {   # Escape — clear search or exit
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
