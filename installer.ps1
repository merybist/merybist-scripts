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
#  FallbackURL = direct download used if winget fails
# ════════════════════════════════════════════════════════════

$ALL_APPS = @(
    # ── Browser ─────────────────────────────────────────────
    [pscustomobject]@{ Name="Brave";                  ID="Brave.Brave";                            Cat="Browser"; FallbackURL="https://laptop-updates.brave.com/latest/winx64"                         }
    [pscustomobject]@{ Name="Google Chrome";          ID="Google.Chrome";                          Cat="Browser"; FallbackURL="https://dl.google.com/chrome/install/ChromeSetup.exe"                   }
    [pscustomobject]@{ Name="LibreWolf";              ID="LibreWolf.LibreWolf";                    Cat="Browser"; FallbackURL="https://gitlab.com/api/v4/projects/24386000/packages/generic/librewolf/latest/librewolf-latest-windows-x86_64-setup.exe" }
    [pscustomobject]@{ Name="Mozilla Firefox";        ID="Mozilla.Firefox";                        Cat="Browser"; FallbackURL="https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US" }
    [pscustomobject]@{ Name="Opera";                  ID="Opera.Opera";                            Cat="Browser"; FallbackURL="https://net.geo.opera.com/opera/stable/windows"                          }
    [pscustomobject]@{ Name="Opera GX";               ID="Opera.OperaGX";                          Cat="Browser"; FallbackURL="https://net.geo.opera.com/opera_gx/stable/windows"                       }
    [pscustomobject]@{ Name="Tor Browser";            ID="TorProject.TorBrowser";                  Cat="Browser"; FallbackURL="https://www.torproject.org/download/"                                    }
    [pscustomobject]@{ Name="Vivaldi";                ID="Vivaldi.Vivaldi";                        Cat="Browser"; FallbackURL="https://downloads.vivaldi.com/stable/Vivaldi.latest.x64.exe"             }
    [pscustomobject]@{ Name="Waterfox";               ID="Waterfox.Waterfox";                      Cat="Browser"; FallbackURL="https://www.waterfox.net/download/"                                      }
    # ── Chat ────────────────────────────────────────────────
    [pscustomobject]@{ Name="Discord";                ID="Discord.Discord";                        Cat="Chat";    FallbackURL="https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x86" }
    [pscustomobject]@{ Name="Element";                ID="Element.Element";                        Cat="Chat";    FallbackURL="https://packages.element.io/desktop/install/win32/x64/Element%20Setup.exe" }
    [pscustomobject]@{ Name="Microsoft Teams";        ID="Microsoft.Teams";                        Cat="Chat";    FallbackURL="https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&managedInstaller=true&download=true" }
    [pscustomobject]@{ Name="mIRC";                   ID="mIRC.mIRC";                              Cat="Chat";    FallbackURL="https://www.mirc.com/get.php?product=mIRC"                                }
    [pscustomobject]@{ Name="Signal";                 ID="OpenWhisperSystems.Signal";              Cat="Chat";    FallbackURL="https://updates.signal.org/desktop/latest.yml"                            }
    [pscustomobject]@{ Name="Skype";                  ID="Microsoft.Skype";                        Cat="Chat";    FallbackURL="https://go.skype.com/windows.desktop.download"                            }
    [pscustomobject]@{ Name="Slack";                  ID="SlackTechnologies.Slack";                Cat="Chat";    FallbackURL="https://slack.com/downloads/windows"                                      }
    [pscustomobject]@{ Name="Telegram";               ID="Telegram.TelegramDesktop";               Cat="Chat";    FallbackURL="https://telegram.org/dl/desktop/win64"                                    }
    [pscustomobject]@{ Name="Viber";                  ID="Viber.Viber";                            Cat="Chat";    FallbackURL="https://download.cdn.viber.com/cdn/desktop/Windows/ViberSetup.exe"         }
    [pscustomobject]@{ Name="WhatsApp";               ID="9NKSQGP7F2NH";                           Cat="Chat";    FallbackURL="https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe"   }
    [pscustomobject]@{ Name="Zoom";                   ID="Zoom.Zoom";                              Cat="Chat";    FallbackURL="https://zoom.us/client/latest/ZoomInstaller.exe"                           }
    # ── Design ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Blender";                ID="BlenderFoundation.Blender";              Cat="Design";  FallbackURL="https://www.blender.org/download/"                                        }
    [pscustomobject]@{ Name="DaVinci Resolve";        ID="Blackmagic.DaVinciResolve";              Cat="Design";  FallbackURL="https://www.blackmagicdesign.com/products/davinciresolve"                  }
    [pscustomobject]@{ Name="Figma";                  ID="Figma.Figma";                            Cat="Design";  FallbackURL="https://desktop.figma.com/win/FigmaSetup.exe"                              }
    [pscustomobject]@{ Name="GIMP";                   ID="GIMP.GIMP";                              Cat="Design";  FallbackURL="https://download.gimp.org/gimp/v2.10/windows/gimp-2.10.36-setup.exe"       }
    [pscustomobject]@{ Name="Inkscape";               ID="Inkscape.Inkscape";                      Cat="Design";  FallbackURL="https://inkscape.org/release/current/windows/64-bit/"                      }
    [pscustomobject]@{ Name="Krita";                  ID="KDE.Krita";                              Cat="Design";  FallbackURL="https://krita.org/en/download/krita-desktop/"                              }
    [pscustomobject]@{ Name="Paint.NET";              ID="dotPDN.PaintDotNet";                     Cat="Design";  FallbackURL="https://www.getpaint.net/download.html"                                    }
    [pscustomobject]@{ Name="Pencil2D";               ID="Pencil2D.Pencil2D";                      Cat="Design";  FallbackURL="https://www.pencil2d.org/download/"                                        }
    [pscustomobject]@{ Name="ScreenToGif";            ID="NickeManarin.ScreenToGif";               Cat="Design";  FallbackURL="https://github.com/NickeManarin/ScreenToGif/releases/latest"               }
    [pscustomobject]@{ Name="ShareX";                 ID="ShareX.ShareX";                          Cat="Design";  FallbackURL="https://github.com/ShareX/ShareX/releases/latest"                         }
    [pscustomobject]@{ Name="Storyboarder";           ID="wonderunit.Storyboarder";                Cat="Design";  FallbackURL="https://github.com/wonderunit/storyboarder/releases/latest"                }
    [pscustomobject]@{ Name="Vectr";                  ID="Vectr.Vectr";                            Cat="Design";  FallbackURL="https://vectr.com/download/"                                               }
    # ── Dev ─────────────────────────────────────────────────
    [pscustomobject]@{ Name="Android Studio";         ID="Google.AndroidStudio";                   Cat="Dev";     FallbackURL="https://developer.android.com/studio"                                      }
    [pscustomobject]@{ Name="Dbeaver";                ID="dbeaver.dbeaver";                        Cat="Dev";     FallbackURL="https://dbeaver.io/download/"                                              }
    [pscustomobject]@{ Name="Docker Desktop";         ID="Docker.DockerDesktop";                   Cat="Dev";     FallbackURL="https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" }
    [pscustomobject]@{ Name="Filezilla";              ID="TimKosse.FileZilla.Client";              Cat="Dev";     FallbackURL="https://filezilla-project.org/download.php?type=client"                    }
    [pscustomobject]@{ Name="Git";                    ID="Git.Git";                                Cat="Dev";     FallbackURL="https://github.com/git-for-windows/git/releases/latest"                    }
    [pscustomobject]@{ Name="GitHub Desktop";         ID="GitHub.GitHubDesktop";                   Cat="Dev";     FallbackURL="https://central.github.com/deployments/desktop/desktopapp/latest/win32"    }
    [pscustomobject]@{ Name="Go";                     ID="GoLang.Go";                              Cat="Dev";     FallbackURL="https://go.dev/dl/"                                                         }
    [pscustomobject]@{ Name="HeidiSQL";               ID="HeidiSQL.HeidiSQL";                      Cat="Dev";     FallbackURL="https://www.heidisql.com/download.php"                                      }
    [pscustomobject]@{ Name="Insomnia";               ID="Insomnia.Insomnia";                      Cat="Dev";     FallbackURL="https://github.com/Kong/insomnia/releases/latest"                          }
    [pscustomobject]@{ Name="JetBrains Toolbox";      ID="JetBrains.Toolbox";                      Cat="Dev";     FallbackURL="https://www.jetbrains.com/toolbox-app/"                                    }
    [pscustomobject]@{ Name="MobaXterm";              ID="Mobatek.MobaXterm";                      Cat="Dev";     FallbackURL="https://mobaxterm.mobatek.net/download-home-edition.html"                   }
    [pscustomobject]@{ Name="Node.js LTS";            ID="OpenJS.NodeJS.LTS";                      Cat="Dev";     FallbackURL="https://nodejs.org/en/download/"                                           }
    [pscustomobject]@{ Name="Notepad++";              ID="Notepad++.Notepad++";                    Cat="Dev";     FallbackURL="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/latest"    }
    [pscustomobject]@{ Name="oh-my-posh";             ID="JanDeDobbeleer.OhMyPosh";               Cat="Dev";     FallbackURL="https://ohmyposh.dev/docs/installation/windows"                            }
    [pscustomobject]@{ Name="Postman";                ID="Postman.Postman";                        Cat="Dev";     FallbackURL="https://dl.pstmn.io/download/latest/win64"                                 }
    [pscustomobject]@{ Name="PyCharm Community";      ID="JetBrains.PyCharm.Community";            Cat="Dev";     FallbackURL="https://www.jetbrains.com/pycharm/download/"                               }
    [pscustomobject]@{ Name="Python 3";               ID="Python.Python.3";                        Cat="Dev";     FallbackURL="https://www.python.org/downloads/windows/"                                 }
    [pscustomobject]@{ Name="Ruby";                   ID="RubyInstallerTeam.Ruby";                 Cat="Dev";     FallbackURL="https://rubyinstaller.org/downloads/"                                      }
    [pscustomobject]@{ Name="Rust";                   ID="Rustlang.Rustup";                        Cat="Dev";     FallbackURL="https://win.rustup.rs/x86_64"                                              }
    [pscustomobject]@{ Name="TablePlus";              ID="TablePlus.TablePlus";                    Cat="Dev";     FallbackURL="https://tableplus.com/windows"                                              }
    [pscustomobject]@{ Name="Visual Studio Code";     ID="Microsoft.VisualStudioCode";             Cat="Dev";     FallbackURL="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"  }
    [pscustomobject]@{ Name="Visual Studio 2022 Community"; ID="Microsoft.VisualStudio.2022.Community"; Cat="Dev"; FallbackURL="https://aka.ms/vs/17/release/vs_community.exe"                           }
    [pscustomobject]@{ Name="Windows Terminal";       ID="Microsoft.WindowsTerminal";              Cat="Dev";     FallbackURL="https://github.com/microsoft/terminal/releases/latest"                     }
    [pscustomobject]@{ Name="WinSCP";                 ID="WinSCP.WinSCP";                          Cat="Dev";     FallbackURL="https://winscp.net/download/WinSCP-latest-Setup.exe"                       }
    # ── Gaming ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Battle.net";             ID="Blizzard.BattleNet";                     Cat="Gaming";  FallbackURL="https://www.blizzard.com/download/confirmation?product=bnetdesk"           }
    [pscustomobject]@{ Name="Cemu (Wii U)";           ID="Cemu.Cemu";                              Cat="Gaming";  FallbackURL="https://github.com/cemu-project/Cemu/releases/latest"                      }
    [pscustomobject]@{ Name="Dolphin Emulator";       ID="DolphinEmu.Dolphin";                     Cat="Gaming";  FallbackURL="https://dolphin-emu.org/download/"                                         }
    [pscustomobject]@{ Name="DS4Windows";             ID="Ryochan7.DS4Windows";                    Cat="Gaming";  FallbackURL="https://github.com/Ryochan7/DS4Windows/releases/latest"                    }
    [pscustomobject]@{ Name="EA App";                 ID="ElectronicArts.EADesktop";               Cat="Gaming";  FallbackURL="https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe" }
    [pscustomobject]@{ Name="Epic Games";             ID="EpicGames.EpicGamesLauncher";            Cat="Gaming";  FallbackURL="https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi" }
    [pscustomobject]@{ Name="GOG Galaxy";             ID="GOG.Galaxy";                             Cat="Gaming";  FallbackURL="https://content-system.gog.com/open_link/download?path=/open/galaxy/client/setup/setup.exe" }
    [pscustomobject]@{ Name="Heroic Games Launcher";  ID="HeroicGamesLauncher.HeroicGamesLauncher"; Cat="Gaming"; FallbackURL="https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest" }
    [pscustomobject]@{ Name="Itch.io";                ID="itch.io";                                Cat="Gaming";  FallbackURL="https://itch.io/app/download?platform=windows"                              }
    [pscustomobject]@{ Name="MAME";                   ID="MAMEDEV.MAME";                           Cat="Gaming";  FallbackURL="https://github.com/mamedev/mame/releases/latest"                           }
    [pscustomobject]@{ Name="PCSX2 (PS2)";            ID="PCSX2.PCSX2";                            Cat="Gaming";  FallbackURL="https://github.com/PCSX2/pcsx2/releases/latest"                            }
    [pscustomobject]@{ Name="PPSSPP (PSP)";           ID="PPSSPP.PPSSPP";                          Cat="Gaming";  FallbackURL="https://www.ppsspp.org/downloads.html"                                     }
    [pscustomobject]@{ Name="Playnite";               ID="Playnite.Playnite";                      Cat="Gaming";  FallbackURL="https://github.com/JosefNemec/Playnite/releases/latest"                    }
    [pscustomobject]@{ Name="RetroArch";              ID="Libretro.RetroArch";                     Cat="Gaming";  FallbackURL="https://buildbot.libretro.com/stable/latest/windows/RetroArch_update.zip"  }
    [pscustomobject]@{ Name="Ryujinx (Switch)";       ID="Ryujinx.Ryujinx";                        Cat="Gaming";  FallbackURL="https://github.com/Ryujinx/release-channel-master/releases/latest"         }
    [pscustomobject]@{ Name="Steam";                  ID="Valve.Steam";                            Cat="Gaming";  FallbackURL="https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"         }
    [pscustomobject]@{ Name="Ubisoft Connect";        ID="Ubisoft.Connect";                        Cat="Gaming";  FallbackURL="https://ubi.li/4vxt9"                                                       }
    [pscustomobject]@{ Name="Xbox";                   ID="9MV0B5HZVK9Z";                           Cat="Gaming";  FallbackURL="https://www.microsoft.com/store/productId/9MV0B5HZVK9Z"                    }
    # ── Media ───────────────────────────────────────────────
    [pscustomobject]@{ Name="Audacity";               ID="Audacity.Audacity";                      Cat="Media";   FallbackURL="https://github.com/audacity/audacity/releases/latest"                      }
    [pscustomobject]@{ Name="Clementine";             ID="Clementine-Player.Clementine";           Cat="Media";   FallbackURL="https://github.com/clementine-player/Clementine/releases/latest"           }
    [pscustomobject]@{ Name="foobar2000";             ID="PeterPawlowski.foobar2000";              Cat="Media";   FallbackURL="https://www.foobar2000.org/download"                                        }
    [pscustomobject]@{ Name="HandBrake";              ID="HandBrake.HandBrake";                    Cat="Media";   FallbackURL="https://handbrake.fr/downloads.php"                                         }
    [pscustomobject]@{ Name="iTunes";                 ID="Apple.iTunes";                           Cat="Media";   FallbackURL="https://www.apple.com/itunes/download/win64"                                }
    [pscustomobject]@{ Name="K-Lite Codec Pack";      ID="CodecGuide.K-LiteCodecPack.Full";        Cat="Media";   FallbackURL="https://www.codecguide.com/download_k-lite_codec_pack_full.htm"             }
    [pscustomobject]@{ Name="Kdenlive";               ID="KDE.Kdenlive";                           Cat="Media";   FallbackURL="https://kdenlive.org/en/download/"                                          }
    [pscustomobject]@{ Name="MPC-HC";                 ID="clsid2.mpc-hc";                         Cat="Media";   FallbackURL="https://github.com/clsid2/mpc-hc/releases/latest"                          }
    [pscustomobject]@{ Name="MPV";                    ID="mpv-player.mpv";                         Cat="Media";   FallbackURL="https://mpv.io/installation/"                                               }
    [pscustomobject]@{ Name="MusicBee";               ID="MusicBee.MusicBee";                      Cat="Media";   FallbackURL="https://www.getmusicbee.com/download/"                                      }
    [pscustomobject]@{ Name="OBS Studio";             ID="OBSProject.OBSStudio";                  Cat="Media";   FallbackURL="https://github.com/obsproject/obs-studio/releases/latest"                   }
    [pscustomobject]@{ Name="Plex";                   ID="Plex.Plexamp";                           Cat="Media";   FallbackURL="https://www.plex.tv/media-server-downloads/"                                }
    [pscustomobject]@{ Name="Shotcut";                ID="Meltytech.Shotcut";                      Cat="Media";   FallbackURL="https://github.com/mltframework/shotcut/releases/latest"                   }
    [pscustomobject]@{ Name="Spotify";                ID="Spotify.Spotify";                        Cat="Media";   FallbackURL="https://download.scdn.co/SpotifySetup.exe"                                  }
    [pscustomobject]@{ Name="Stremio";                ID="Stremio.Stremio";                        Cat="Media";   FallbackURL="https://www.stremio.com/downloads"                                          }
    [pscustomobject]@{ Name="VLC";                    ID="VideoLAN.VLC";                           Cat="Media";   FallbackURL="https://get.videolan.org/vlc/last/win64/"                                   }
    [pscustomobject]@{ Name="Winamp";                 ID="Winamp.Winamp";                          Cat="Media";   FallbackURL="https://www.winamp.com/winamp-download/"                                    }
    [pscustomobject]@{ Name="YouTube Music";          ID="th-ch.YouTubeMusic";                     Cat="Media";   FallbackURL="https://github.com/th-ch/youtube-music/releases/latest"                    }
    # ── Office ──────────────────────────────────────────────
    [pscustomobject]@{ Name="Bitwarden";              ID="Bitwarden.Bitwarden";                    Cat="Office";  FallbackURL="https://vault.bitwarden.com/download/?app=desktop&platform=windows"         }
    [pscustomobject]@{ Name="CherryTree";             ID="giuspen.cherrytree";                     Cat="Office";  FallbackURL="https://www.giuspen.net/software/CherryTree-installer.exe"                  }
    [pscustomobject]@{ Name="Drawio";                 ID="JGraph.Draw";                            Cat="Office";  FallbackURL="https://github.com/jgraph/drawio-desktop/releases/latest"                  }
    [pscustomobject]@{ Name="Joplin";                 ID="Joplin.Joplin";                          Cat="Office";  FallbackURL="https://github.com/laurent22/joplin/releases/latest"                       }
    [pscustomobject]@{ Name="KeePassXC";              ID="KeePassXCTeam.KeePassXC";               Cat="Office";  FallbackURL="https://github.com/keepassxreboot/keepassxc/releases/latest"                }
    [pscustomobject]@{ Name="LibreOffice";            ID="TheDocumentFoundation.LibreOffice";      Cat="Office";  FallbackURL="https://www.libreoffice.org/download/download-libreoffice/"                 }
    [pscustomobject]@{ Name="Logseq";                 ID="Logseq.Logseq";                          Cat="Office";  FallbackURL="https://github.com/logseq/logseq/releases/latest"                          }
    [pscustomobject]@{ Name="Notion";                 ID="Notion.Notion";                          Cat="Office";  FallbackURL="https://www.notion.so/desktop/windows/download"                             }
    [pscustomobject]@{ Name="Obsidian";               ID="Obsidian.Obsidian";                      Cat="Office";  FallbackURL="https://github.com/obsidianmd/obsidian-releases/releases/latest"            }
    [pscustomobject]@{ Name="PDF24 Creator";          ID="geek-software.PDF24Creator";             Cat="Office";  FallbackURL="https://creator.pdf24.org/releases/PDF24Creator-latest-x64.exe"             }
    [pscustomobject]@{ Name="Sumatra PDF";            ID="SumatraPDF.SumatraPDF";                  Cat="Office";  FallbackURL="https://www.sumatrapdfreader.org/download-free-pdf-viewer"                  }
    [pscustomobject]@{ Name="Thunderbird";            ID="Mozilla.Thunderbird";                    Cat="Office";  FallbackURL="https://download.mozilla.org/?product=thunderbird-latest&os=win64&lang=en-US" }
    [pscustomobject]@{ Name="Todoist";                ID="Doist.Todoist";                          Cat="Office";  FallbackURL="https://todoist.com/windows_app"                                             }
    [pscustomobject]@{ Name="Zotero";                 ID="Zotero.Zotero";                          Cat="Office";  FallbackURL="https://www.zotero.org/download/"                                           }
    # ── Security ────────────────────────────────────────────
    [pscustomobject]@{ Name="Bitwarden";              ID="Bitwarden.Bitwarden";                    Cat="Security"; FallbackURL="https://vault.bitwarden.com/download/?app=desktop&platform=windows"        }
    [pscustomobject]@{ Name="KeePassXC";              ID="KeePassXCTeam.KeePassXC";               Cat="Security"; FallbackURL="https://github.com/keepassxreboot/keepassxc/releases/latest"               }
    [pscustomobject]@{ Name="Malwarebytes";           ID="Malwarebytes.Malwarebytes";              Cat="Security"; FallbackURL="https://downloads.malwarebytes.com/file/mb-windows"                        }
    [pscustomobject]@{ Name="Nmap";                   ID="Insecure.Nmap";                          Cat="Security"; FallbackURL="https://nmap.org/dist/nmap-latest-setup.exe"                               }
    [pscustomobject]@{ Name="OpenVPN";                ID="OpenVPNTechnologies.OpenVPN";            Cat="Security"; FallbackURL="https://openvpn.net/downloads/openvpn-connect-v3-windows.msi"              }
    [pscustomobject]@{ Name="Revo Uninstaller";       ID="RevoUninstaller.RevoUninstaller";        Cat="Security"; FallbackURL="https://download.revouninstaller.com/download/revosetup.exe"               }
    [pscustomobject]@{ Name="Veracrypt";              ID="IDRIX.VeraCrypt";                        Cat="Security"; FallbackURL="https://www.veracrypt.fr/en/Downloads.html"                                }
    [pscustomobject]@{ Name="Wireshark";              ID="WiresharkFoundation.Wireshark";          Cat="Security"; FallbackURL="https://www.wireshark.org/download.html"                                   }
    [pscustomobject]@{ Name="WireGuard";              ID="WireGuard.WireGuard";                    Cat="Security"; FallbackURL="https://download.wireguard.com/windows-client/wireguard-installer.exe"     }
    # ── Utils ───────────────────────────────────────────────
    [pscustomobject]@{ Name="7-Zip";                  ID="7zip.7zip";                              Cat="Utils";   FallbackURL="https://www.7-zip.org/a/7z2301-x64.exe"                                     }
    [pscustomobject]@{ Name="Autoruns";               ID="Microsoft.Sysinternals.Autoruns";        Cat="Utils";   FallbackURL="https://download.sysinternals.com/files/Autoruns.zip"                       }
    [pscustomobject]@{ Name="Bulk Rename Utility";    ID="TGRMNSoftware.BulkRenameUtility";        Cat="Utils";   FallbackURL="https://www.bulkrenameutility.co.uk/Downloads/BRU_Setup.exe"                 }
    [pscustomobject]@{ Name="CPU-Z";                  ID="CPUID.CPU-Z";                            Cat="Utils";   FallbackURL="https://download.cpuid.com/cpu-z/cpu-z_2.09-en.exe"                         }
    [pscustomobject]@{ Name="CrystalDiskInfo";        ID="CrystalDewWorld.CrystalDiskInfo";        Cat="Utils";   FallbackURL="https://crystalmark.info/redirect.php?product=CrystalDiskInfo"              }
    [pscustomobject]@{ Name="CrystalDiskMark";        ID="CrystalDewWorld.CrystalDiskMark";        Cat="Utils";   FallbackURL="https://crystalmark.info/redirect.php?product=CrystalDiskMark"              }
    [pscustomobject]@{ Name="Ditto (clipboard)";      ID="Ditto.Ditto";                            Cat="Utils";   FallbackURL="https://github.com/sabrogden/Ditto/releases/latest"                         }
    [pscustomobject]@{ Name="Everything";             ID="voidtools.Everything";                   Cat="Utils";   FallbackURL="https://www.voidtools.com/Everything-latest.x64-Setup.exe"                  }
    [pscustomobject]@{ Name="GPU-Z";                  ID="TechPowerUp.GPU-Z";                      Cat="Utils";   FallbackURL="https://download.techpowerup.com/files/GPU-Z.exe"                           }
    [pscustomobject]@{ Name="HWiNFO";                 ID="REALiX.HWiNFO";                         Cat="Utils";   FallbackURL="https://www.hwinfo.com/files/hwi_latest.exe"                                }
    [pscustomobject]@{ Name="HWMonitor";              ID="CPUID.HWMonitor";                        Cat="Utils";   FallbackURL="https://download.cpuid.com/hwmonitor/hwmonitor_1.52-setup.exe"               }
    [pscustomobject]@{ Name="MSI Afterburner";        ID="MSI.Afterburner";                        Cat="Utils";   FallbackURL="https://download.msi.com/uti_exe/vga/MSIAfterburnerSetup.zip"               }
    [pscustomobject]@{ Name="NirSoft NirLauncher";    ID="Nirsoft.NirLauncher";                    Cat="Utils";   FallbackURL="https://www.nirsoft.net/utils/nirlauncher.zip"                              }
    [pscustomobject]@{ Name="PowerToys";              ID="Microsoft.PowerToys";                    Cat="Utils";   FallbackURL="https://github.com/microsoft/PowerToys/releases/latest"                     }
    [pscustomobject]@{ Name="Process Hacker";         ID="wj32.ProcessHacker";                     Cat="Utils";   FallbackURL="https://github.com/processhacker/processhacker/releases/latest"             }
    [pscustomobject]@{ Name="Rufus";                  ID="Rufus.Rufus";                            Cat="Utils";   FallbackURL="https://github.com/pbatard/rufus/releases/latest"                           }
    [pscustomobject]@{ Name="Speccy";                 ID="Piriform.Speccy";                        Cat="Utils";   FallbackURL="https://www.ccleaner.com/speccy/download/standard"                          }
    [pscustomobject]@{ Name="TreeSize Free";          ID="JAMSoftware.TreeSize.Free";              Cat="Utils";   FallbackURL="https://downloads.jam-software.de/treesize_free/TreeSizeFreeSetup.exe"       }
    [pscustomobject]@{ Name="Ventoy";                 ID="Ventoy.Ventoy";                          Cat="Utils";   FallbackURL="https://github.com/ventoy/Ventoy/releases/latest"                           }
    [pscustomobject]@{ Name="WinDirStat";             ID="WinDirStat.WinDirStat";                  Cat="Utils";   FallbackURL="https://windirstat.net/wds_current_setup.exe"                               }
    [pscustomobject]@{ Name="WinRAR";                 ID="RARLab.WinRAR";                          Cat="Utils";   FallbackURL="https://www.rarlab.com/rar/winrar-x64-701.exe"                              }
    [pscustomobject]@{ Name="WizTree";                ID="AntibodySoftware.WizTree";               Cat="Utils";   FallbackURL="https://diskanalyzer.com/files/wiztree_4_16_setup.exe"                      }
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
#  Maps exit code → @{ symbol; color; message; useFallback }
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
    -1978335135  = @{ S = "x"; C = $FG.Red;    M = "Install failed — trying fallback";                FB = $true  }
    -1978335239  = @{ S = "x"; C = $FG.Red;    M = "Package not found — trying fallback";             FB = $true  }
    -1978335227  = @{ S = "x"; C = $FG.Red;    M = "No applicable installer found — trying fallback"; FB = $true  }
}

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

    $sb = [System.Text.StringBuilder]::new($W * ($H + 2) * 8)
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

        $app       = $filtered[$i]
        $isChecked = $checked.Contains($i)
        $isCursor  = ($i -eq $cursor)
        $catFg     = if ($CAT_FG[$app.Cat]) { $CAT_FG[$app.Cat] } else { $FG.Gray }
        $box       = if ($isChecked) { " [*] " } else { " [ ] " }
        $dispName  = if ($app.Name.Length -gt $nameW) { $app.Name.Substring(0,$nameW-1) + "~" } else { $app.Name }
        $namePad   = $dispName.PadRight($nameW)
        $catPad    = ("[" + $app.Cat + "]").PadRight($catW)

        if ($isCursor) {
            $bg = $BG.DarkGray
            $boxFg  = if ($isChecked) { $FG.Green } else { $FG.Gray }
            $nameFg = if ($isChecked) { $FG.White } else { $FG.Gray }
            [void]$sb.Append("${bg}${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
        } else {
            $boxFg  = if ($isChecked) { $FG.Green } else { $FG.DarkGray }
            $nameFg = if ($isChecked) { $FG.White } else { $FG.Gray }
            [void]$sb.Append("${boxFg}${box}${nameFg} ${namePad} ${catFg}${catPad}$RESET`n")
        }
    }

    # Status bar
    [void]$sb.Append("$($FG.DarkGray)$('─' * $W)$RESET`n")
    $selCnt = $checked.Count
    $pct = if ($total -le $listH -or $total -eq 0) { 100 } else {
        [int](($scrollTop / ([Math]::Max(1, $total - $listH))) * 100)
    }
    $sl = "  $total shown   $selCnt selected   Enter=install   Space=check   Tab=all"
    $sr = "$($cursor+1)/$total  $pct%  "
    [void]$sb.Append("$($FG.DarkGray)$($sl.PadRight($W - $sr.Length) + $sr)$RESET")

    [Console]::Write($sb.ToString())
}

# ════════════════════════════════════════════════════════════
#  WINGET PROGRESS BAR
#  Runs winget and parses its stdout for a live progress bar.
#  winget outputs lines like:
#    "Downloading  https://..."
#    "  ██████░░░░  60%"
#    "Installing ..."
#  We capture these and re-render a single bar line in-place.
# ════════════════════════════════════════════════════════════
function Invoke-WingetWithProgress {
    param(
        [string]$AppID,
        [string]$AppName
    )

    $W        = [Console]::WindowWidth
    $barWidth = 30

    # Reserve two lines: [1] status text, [2] progress bar
    [Console]::Write("  $($FG.DarkGray)Contacting winget...$RESET`n")
    [Console]::Write("  $($FG.Cyan)[$('.' * $barWidth)]   0%$RESET  `n")

    # Row of the progress bar (we'll overwrite it)
    $barRow = [Console]::CursorTop - 1

    $phase   = "Downloading"
    $percent = 0

    # -- parse a winget progress line like "  ██████░░  45%" -------
    function Parse-WingetLine([string]$line) {
        # percent number anywhere on line
        if ($line -match '(\d{1,3})\s*%') {
            return [int]$matches[1]
        }
        return -1
    }

    # -- redraw the progress bar row --------------------------------
    function Write-ProgressBar([int]$pct, [string]$phaseText) {
        $filled  = [int](($pct / 100) * $barWidth)
        $empty   = $barWidth - $filled
        $bar     = ("█" * $filled) + ("░" * $empty)
        $label   = "${phaseText}  $($pct.ToString().PadLeft(3))%"
        $line    = "  $($FG.Cyan)[${bar}]  $($FG.White)${label}$RESET"
        # move cursor to bar row, clear line, redraw
        [Console]::SetCursorPosition(0, $barRow)
        [Console]::Write("$ESC[2K" + $line)
        [Console]::SetCursorPosition(0, $barRow + 1)
    }

    # -- launch winget as a job so we can stream output --------------
    $job = Start-Job -ScriptBlock {
        param($id)
        & winget install --id $id --silent `
            --accept-package-agreements `
            --accept-source-agreements 2>&1
    } -ArgumentList $AppID

    # Poll the job output while it runs
    while ($job.State -eq 'Running') {
        $lines = Receive-Job $job -Keep 2>$null
        foreach ($ln in $lines) {
            $ln = "$ln".Trim()
            if ($ln -match 'Download') { $phase = "Downloading" }
            elseif ($ln -match 'Install|Verif|Configur') { $phase = "Installing " }
            elseif ($ln -match 'Hash|Validat') { $phase = "Verifying  " }

            $p = Parse-WingetLine $ln
            if ($p -ge 0 -and $p -ge $percent) { $percent = $p }
        }
        Write-ProgressBar $percent $phase
        Start-Sleep -Milliseconds 120
    }

    # Drain remaining output after job finishes
    $allLines = Receive-Job $job 2>$null
    foreach ($ln in $allLines) {
        $p = Parse-WingetLine "$ln"
        if ($p -ge 0 -and $p -ge $percent) { $percent = $p }
    }
    Remove-Job $job -Force

    # Show 100% bar briefly
    Write-ProgressBar 100 "Done       "
    Start-Sleep -Milliseconds 200

    return $LASTEXITCODE
}

# ════════════════════════════════════════════════════════════
#  FALLBACK INSTALLER — opens download page in browser
# ════════════════════════════════════════════════════════════
function Run-Fallback {
    param($app)

    if (-not $app.FallbackURL -or $app.FallbackURL -eq "") {
        [Console]::Write("  $($FG.Red)x No fallback available$RESET`n`n")
        return $false
    }

    $url = $app.FallbackURL
    $isDirectFile = $url -match '\.(exe|msi|zip|7z)(\?.*)?$'

    if ($isDirectFile) {
        $ext      = if ($url -match '\.msi') { ".msi" } elseif ($url -match '\.zip') { ".zip" } else { ".exe" }
        $tmpFile  = "$env:TEMP\wintools_fallback_$($app.Name -replace '[^a-zA-Z0-9]','_')$ext"

        [Console]::Write("  $($FG.Cyan)~ Downloading from fallback URL...$RESET`n")
        try {
            $wc = [System.Net.WebClient]::new()
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
            $wc.DownloadFile($url, $tmpFile)

            if (Test-Path $tmpFile) {
                [Console]::Write("  $($FG.Cyan)~ Launching installer...$RESET`n")
                if ($ext -eq ".msi") {
                    Start-Process msiexec.exe -ArgumentList "/i `"$tmpFile`" /passive /norestart" -Wait
                } elseif ($ext -eq ".zip") {
                    [Console]::Write("  $($FG.Yellow)~ ZIP archive — extracting to Desktop...$RESET`n")
                    Expand-Archive -Path $tmpFile -DestinationPath "$env:USERPROFILE\Desktop\$($app.Name)" -Force
                    [Console]::Write("  $($FG.Green)+ Extracted to Desktop\$($app.Name)$RESET`n`n")
                    return $true
                } else {
                    Start-Process $tmpFile -ArgumentList "/S /silent /quiet" -Wait
                }
                [Console]::Write("  $($FG.Green)+ Fallback install complete$RESET`n`n")
                return $true
            }
        } catch {
            [Console]::Write("  $($FG.Red)x Download failed: $($_.Exception.Message)$RESET`n")
        }
    }

    [Console]::Write("  $($FG.Yellow)~ Opening download page in browser...$RESET`n`n")
    Start-Process $url
    return $false
}

# ════════════════════════════════════════════════════════════
#  INSTALL SCREEN
# ════════════════════════════════════════════════════════════
function Run-Install {
    param($toInstall)

    [Console]::CursorVisible = $false
    Clear-Host

    $W       = [Console]::WindowWidth
    $total   = $toInstall.Count
    $done    = 0; $skipped = 0; $failed = 0; $fallback = 0; $i = 0

    [Console]::Write("`n$($FG.DarkGray)$('─' * $W)$RESET`n")
    [Console]::Write("  $($FG.Cyan)Installing $total app(s)...$RESET`n")
    [Console]::Write("$($FG.DarkGray)$('─' * $W)$RESET`n`n")

    foreach ($app in $toInstall) {
        $i++
        $pct    = [int](($i / $total) * 100)
        $filled = [int]($pct / 4)
        $bar    = ("=" * $filled).PadRight(25, "-")
        $catFg  = if ($CAT_FG[$app.Cat]) { $CAT_FG[$app.Cat] } else { $FG.Gray }

        [Console]::Write("  $($FG.DarkGray)[$i/$total] $($FG.White)$($app.Name)  $catFg[$($app.Cat)]$RESET`n")

        # ── Run winget with live progress bar ───────────────
        $code = Invoke-WingetWithProgress -AppID $app.ID -AppName $app.Name
        [Console]::Write("`n")

        $info = $WINGET_CODES[$code]

        if ($info) {
            [Console]::Write("  $($info.C)[$($info.S)] $($info.M)$RESET`n")

            if ($info.FB) {
                $ok = Run-Fallback $app
                if ($ok) { $fallback++ } else { $failed++ }
            } elseif ($code -eq 0) {
                $done++
                [Console]::Write("`n")
            } elseif ($code -eq -1978335153) {
                $failed++
                [Console]::Write("`n")
            } else {
                $skipped++
                [Console]::Write("`n")
            }
        } else {
            # Unknown exit code — try fallback
            [Console]::Write("  $($FG.Red)[x] Failed (code $code) — trying fallback$RESET`n")
            $ok = Run-Fallback $app
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
#  MAIN LOOP
# ════════════════════════════════════════════════════════════
Clear-Host

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
