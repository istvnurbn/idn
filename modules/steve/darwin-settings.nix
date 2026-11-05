{
  den.aspects.steve.provides.darwin-settings.homeManager = {
    programs.nix-plist-manager = {
      enable = true;
      options.applications = {
        finder = {
          menuBar = {
            view = {
              showPathBar = true;
              showSidebar = true;
            };
          };
          settings = {
            advanced = {
              keepFoldersOnTop = {
                inWindowsWhenSortingByName = true;
                onDesktop = true;
              };
              removeItemsFromTheTrashAfter30Days = true;
              showAllFilenameExtensions = true;
              whenPerformingASearch = "Search the Current Folder";
            };
            general = {
              showTheseItemsOnTheDesktop = {
                cdsDvdsAndiPods = true;
                connectedServers = true;
                externalDisks = true;
                hardDisks = false;
              };
            };
          };
        };
        systemSettings = {
          accessibility = {
            audio = {
              backgroundSoundsOptions = {
                timer = false;
              };
            };
            display = {
              reduceTransparency = true;
              textSize = {
                preferredReadingSize = "DEFAULT";
              };
            };
            hoverText = {
              hoverTypingOptions = {
                textFont = "Default";
              };
              options = {
                textFont = "Default";
              };
            };
            keyboard = {
              slowKeys = false;
              stickyKeys = false;
              stickyKeysOptions = {
                pressTheShiftKeyFiveTimesToToggleStickyKeys = false;
              };
            };
            liveCaptions = {
              fontFamily = "Default";
            };
            motion = {
              reduceMotion = true;
            };
            pointerControl = {
              trackpadOptions = {
                dragging = "Off";
                useTrackpadForScrolling = true;
              };
            };
            readAndSpeak = {
              typingFeedback = {
                characters = true;
                modifierKeys = false;
                selectionChanges = false;
                words = true;
              };
            };
            voiceControl = {
              showHints = false;
            };
            zoom = {
              useKeyboardShortcutsToZoom = false;
            };
          };
          appearance = {
            clickInTheScrollBarTo = "Jump to the spot that's clicked";
            liquidGlass = 1.0;
            showScrollBars = "When scrolling";
          };
          appleIntelligenceAndSiri = {
            siri = {
              enable = false;
            };
          };
          desktopAndDock = {
            desktopAndStageManager = {
              clickWallpaperToRevealDesktop = "Only in Stage Manager";
            };
            dock = {
              animateOpeningApplications = false;
              automaticallyHideAndShowTheDock = {
                delay = 0.0;
                duration = 0.0;
                enabled = true;
              };
              minimizeWindowsIntoApplicationIcon = true;
              showSuggestedAndRecentAppsInDock = false;
              size = 64;
            };
            hotCorners = {
              bottomLeft = {
                modifiers = {
                  command = false;
                  control = false;
                  option = false;
                  shift = false;
                };
              };
              bottomRight = {
                modifiers = {
                  command = false;
                  control = false;
                  option = false;
                  shift = false;
                };
              };
              topLeft = {
                modifiers = {
                  command = false;
                  control = false;
                  option = false;
                  shift = false;
                };
              };
              topRight = {
                modifiers = {
                  command = false;
                  control = false;
                  option = false;
                  shift = false;
                };
              };
            };
            missionControl = {
              automaticallyRearrangeSpacesBasedOnMostRecentUse = false;
              shortcuts = {
                applicationWindows = "-";
                missionControl = "-";
                showDesktop = "-";
              };
            };
            widgets = {
              showWidgets = {
                inStageManager = false;
                onDesktop = false;
              };
            };
            windows = {
              dragWindowsToLeftOrRightEdgeOfScreenToTile = false;
              dragWindowsToMenuBarToFillScreen = false;
            };
          };
          general = {
            airDropAndContinuity = {
              iPhoneWidgets = false;
            };
            autoFillAndPasswords = {
              deleteVerificationCodesAfterUse = true;
            };
            languageAndRegion = {
              preferredLanguages = [
                "en-US"
                "hu-HU"
              ];
              region = "en_US@rg=huzzzz";
            };
            sharing = {
              mediaSharing = {
                shareMediaWithGuests = false;
              };
            };
          };
          keyboard = {
            keyboardShortcuts = {
              accessibility = {
                decreaseContrast = false;
                increaseContrast = false;
                invertColors = false;
              };
              appShortcuts = {
                menuItems = {};
              };
              inputSources = {
                selectNextSourceInInputMenu = false;
                selectThePreviousInputSource = false;
              };
              keyboard = {
                moveFocusToNextWindow = "⌥Tab";
              };
              missionControl = {
                moveLeftASpace = true;
                moveRightASpace = true;
              };
            };
            textInput = {
              addPeriodWithDoubleSpace = true;
              capitalizeWordsAutomatically = true;
              correctSpellingAutomatically = false;
              inputSources = [
                "com.apple.keylayout.Hungarian"
              ];
            };
          };
          menuBar = {
            clock = {
              showAmPm = true;
              showTheDayOfTheWeek = true;
            };
          };
          notifications = {
            notificationCenter = {
              summarizeNotifications = false;
            };
          };
          sound = {
            soundEffects = {
              # 50% on the slider
              alertVolume = 0.606531;
            };
          };
          spotlight = {
            searchResults = {
              appStore = true;
              apps = true;
              books = true;
              calculator = true;
              calendar = true;
              contacts = true;
              dictionary = true;
              files = true;
              folders = true;
              games = true;
              iPhoneApps = true;
              mail = true;
              menuItems = true;
              messages = true;
              music = true;
              notes = true;
              phone = true;
              photos = true;
              podcasts = true;
              reminders = true;
              safari = true;
              shortcuts = true;
              systemSettings = true;
              tips = true;
              voiceMemos = true;
            };
          };
          trackpad = {
            pointAndClick = {
              click = "Medium";
              tapToClick = true;
            };
            scrollAndZoom = {
              rotate = true;
              zoomInOrOut = true;
            };
          };
          wallpaper = {
            startScreenSaver = "After 5 minutes";
          };
        };
      };
    };

    targets.darwin.defaults = {
      NSGlobalDomain = {
        # Close windows when quitting an app
        NSQuitAlwaysKeepsWindows = false;
      };

      # Mail: show attachments as icons instead of inline previews
      "com.apple.mail" = {
        DisableInlineAttachmentViewing = true;
      };

      # TextEdit
      "com.apple.TextEdit" = {
        # Start with an empty file.
        NSShowAppCentricOpenPanelInsteadOfUntitledFile = false;
        # Plain text editing.
        RichText = 0;
        PlainTextEncoding = 4;
        PlainTextEncodingForWrite = 4;
      };
    };
  };
}
