{inputs, ...}: {
  flake-file.inputs = {
    betterfox-userjs.url = "github:istvnurbn/betterfox-userjs-nix";
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
  };

  den.aspects.firefox = {user, ...}: let
    # Shared with the home-manager profile below (provides.to-users.homeManager)
    # so the same policies apply on nixos and darwin alike. The nixos facet
    # layers a KDE-specific extension setting on top via `//` further down.
    policies = {
      EnterprisePoliciesEnabled = true;

      # Updates & Background Services
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;
      ManualAppUpdateOnly = true;

      # Features
      DisableDeveloperTools = false;
      DisableFeedbackCommands = true;
      EncryptedMediaExtensions = true;
      DisableFirefoxStudies = true;
      DisableFirefoxScreenshots = true;
      DisableFormHistory = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableTelemetry = true;

      # UI and Behavior
      DontCheckDefaultBrowser = true;
      FirefoxHome = {
        SponsoredStories = false;
        SponsoredTopSites = false;
        Stories = false;
      };
      GenerativeAI = {
        Enabled = false;
      };
      NoDefaultBookmarks = true;

      # Additional search engines
      SearchEngines = {
        PreventInstalls = false;
        Remove = [
          "Amazon.com"
          "eBay"
          "Perplexity"
        ];
      };
    };
  in {
    nixos = {pkgs, ...}: {
      programs.firefox = {
        enable = true;

        nativeMessagingHosts.packages = with pkgs; [
          kdePackages.plasma-browser-integration
        ];

        # Shared policies, plus the KDE integration extension (nixos-only).
        policies = policies // {
          ExtensionSettings = {
            "plasma-browser-integration@kde.org" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/plasma-integration/latest.xpi";
            };
          };
        };

        preferences = {
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };
      };
    };

    darwin = {
      homebrew.casks = [
        "firefox"
      ];
    };

    impermanence = {
      users.${user.name} = {
        directories = [
          ".config/mozilla"
        ];
      };
    };

    provides.to-users.homeManager = {pkgs, ...}: {
      programs.firefox = {
        enable = true;

        # The actual browser is already installed system-wide (nixos facet)
        # or via the Homebrew cask (darwin facet); this block only manages
        # the profile (settings/extensions/search), so skip installing a
        # second, redundant nixpkgs Firefox into the user profile.
        package = null;

        # Same enterprise policies as the nixos facet. On darwin these are
        # written to ~/Library/Preferences/org.mozilla.firefox.plist, which
        # the Homebrew-installed Firefox reads regardless of `package`.
        inherit policies;

        profiles.personal = {
          id = 0;
          isDefault = true;
          settings = inputs.betterfox-userjs.lib.mkSettings {
            enable = ["user" "smoothfox-zen-smooth-scrolling"];
            overrides = {
              # Disable Firefox Sync
              "identity.fxaccounts.enabled" = false;

              # Disable translation
              "browser.translations.enable" = false;
              "browser.translations.autoTranslate" = false;

              # Disable Password, credit card, and address management
              "signon.rememberSignons" = false;
              "extensions.formautofill.addresses.enabled" = false;
              "extensions.formautofill.creditCards.enabled" = false;

              # Sanitize on close
              "privacy.sanitize.sanitizeOnShutdown" = true;
              "privacy.clearOnShutdown_v2.cache" = true;
              "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
              "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
              "privacy.clearOnShutdown_v2.downloads" = true;
              "privacy.clearOnShutdown_v2.formdata" = true;
              "browser.sessionstore.privacy_level" = 2;

              # Disable service workers
              "dom.serviceWorkers.enabled" = false;
              "dom.serviceWorkers.privateBrowsing.enabled" = false;

              # Disable JIT optimization
              "javascript.options.ion" = false;
              "javascript.options.wasm_optimizingjit" = false;

              # Disable captive portal detection
              "captivedetect.canonicalURL" = "";
              "network.captive-portal-service.enabled" = false;
              "network.connectivity-service.enabled" = false;

              # No top sites on new tab page
              "browser.newtabpage.activity-stream.feeds.topsites" = false;
            };
          };
          extensions = {
            packages = with inputs.nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.repos.rycee.firefox-addons; [
              proton-pass
              raindropio
              ublock-origin
            ];
            force = true;
            settings = let
              # uBlock treats URL lists as unknown until they are imported;
              # selecting them without importing silently drops them.
              externalFilterLists = [
                "https://raw.githubusercontent.com/DandelionSprout/adfilt/refs/heads/master/LegitimateURLShortener.txt"
                "https://raw.githubusercontent.com/yokoffing/filterlists/refs/heads/main/click2load.txt"
              ];
            in {
              "uBlock0@raymondhill.net".settings = {
                importedLists = externalFilterLists;
                # Legacy mirror of importedLists, kept in sync by uBlock itself
                externalLists = builtins.concatStringsSep "\n" externalFilterLists;
                selectedFilterLists =
                  [
                    "ublock-filters"
                    "ublock-badware"
                    "ublock-privacy"
                    "ublock-quick-fixes"
                    "ublock-unbreak"
                    "easylist"
                    "easyprivacy"
                    "adguard-spyware-url"
                    "urlhaus-1"
                    "plowe-0"
                    "fanboy-cookiemonster"
                    "ublock-cookies-easylist"
                    "fanboy-social"
                    "fanboy-ai-suggestions"
                    "easylist-chat"
                    "easylist-newsletters"
                    "easylist-notifications"
                    "easylist-annoyances"
                    "ublock-annoyances"
                    "HUN-0"
                  ]
                  ++ externalFilterLists;
              };
            };
          };
          search = {
            force = true;
            default = "brave";
            engines = {
              brave = {
                name = "Brave Search";
                urls = [
                  {template = "https://search.brave.com/search?q={searchTerms}";}
                  {
                    template = "https://search.brave.com/api/suggest?q={searchTerms}";
                    type = "application/x-suggestions+json";
                  }
                ];
                icon = "data:image/png;base64,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";
              };

              ddg-lite = {
                name = "DuckDuckGo Lite";
                urls = [
                  {
                    template = "https://duckduckgo.com/lite/";
                    method = "POST";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "data:image/x-icon;base64,AAABAAIAEBAAAAEAIABoBAAAJgAAACAgAAABACAAqBAAAI4EAAAoAAAAEAAAACAAAAABACAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVZ4Ss0Wd+PM1nf1Tpd4PM6XeDzM1nf1TRZ3481WeErAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVYD/BjRa3pRQcOP9tMLy/83q2f/m9uv//f7+//L0/P+qu+7/UHDj/TRa3pRVgP8GAAAAAAAAAAAAAAAAVYD/BjNZ372Jnuv/9/j9/8nT9v+D0pj/R71m/02+a/9Kr3z/XreM//f4/f+Jnuv/M1nfvVWA/wYAAAAAAAAAADRa3pSJnuv/4Ob6/1h25P+8yPT/ntyv/6zhuv+Fvrj/PpKY/0Cbjf9YduT/4Ob6/4me6/80Wt6UAAAAADVZ4StQcOP99/j9/1h25P8zWN7/5+z7////////////Z4Lm/zNY3v8zWd3/M1je/1h25P/3+P3/UHDj/TVZ4Ss0Wd+PrLvx/5ut7v8zWN7/Rmfh/////////////////0Jo4P8neuf/IY/s/yZ85/8yXN//m63u/6y78f80Wd+PM1nf1ert+/9ObuL/M1je/3CK5////////////9j4//8RyPv/J3vn/ytx5P8lg+n/KHjm/05u4v/p7fv/M1nf1Tpd4PP4+f3/M1je/zNY3v+bre7////////////X+P//JNL8/yDJ+v8Utvb/II/t/y9j4P8zWN7/+Pn9/zpd4PM6XeDz+Pn9/zNY3v8zWN7/w871///////////////////////k+v//T5zt/xyc7/8UtPX/L2Ph//j5/f86XeDzM1nf1ert+/9ObuL/M1je/9vi+f//////oXZf////////////oXZf/2N/5f8zWN7/M1je/05u4v/q7fv/M1nf1TRZ34+su/H/m63u/zNY3v/H0fX//////////////////////+js+/83W97/M1je/zNY3v+bre7/rLvx/zRZ3481WeErUHDj/ff4/f9YduT/X3zl//Hz/P////////////j5/f9yi+j/M1je/zNY3v9YduT/9/j9/1Bw4/01WeErAAAAADRa3pSJnuv/4Ob6/1h25P9MbOL/2N/4/73J9P9DZeD/M1je/zNY3v9YduT/4Ob6/4me6/80Wt6UAAAAAAAAAABVgP8GM1nfvYme6//3+P3/m63u/05u4v8zWN7/M1je/05u4v+bre7/9/j9/4me6/8zWd+9VYD/BgAAAAAAAAAAAAAAAFWA/wY0Wt6UUHDj/ay78f/p7fv/+Pn9//j5/f/p7fv/rLvx/1Bw4/00Wt6UVYD/BgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVZ4Ss0Wd+PM1nf1Tpd4PM6XeDzM1nf1TRZ3481WeErAAAAAAAAAAAAAAAAAAAAAPAPAADAAwAAgAEAAIABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIABAACAAQAAwAMAAPAPAAAoAAAAIAAAAEAAAAABACAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFWA/wY2Wt9HM1nelTRY3780WN7ZM1je8zNY3vM0WN7ZNFjfvzNZ3pU2Wt9HVYD/BgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVg3xgzWN+WNFne8TNY3v9ceuT/iJ7r/52v7/+ywPL/ssDy/52v7/+Inuv/XHrk/zNY3v80Wd7xM1jfljVg3xgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAElt/wczWOCCM1nf9Ets4v+ouPH/6e37/+vv+//a4Pj/2eD4/9zi+f/c4vn/2eD4/9rg+P/m6vv/6e37/6i48f9LbOL/M1nf9DNY4IJJbf8HAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1YN8YM1jfxz9i4P+js/D/8fP8/6Cx7/+7x/P/5fbp/1zEd/+o4Lb/9vz4////////////3+T5/zVZ3v9Xed3/obPu//Hz/P+js/D/P2Hf/zNY38c1YN8YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAN1njLjRZ3uNTcuP/4eb6/7PB8v9IaeH/M1je/9rg+f/H69D/Rrxl/0a8Zf9NtV//RrRa/063Yv9fpqf/QqWA/0a8Zf87gqv/SGnh/7TC8v/h5vr/U3Lj/zRZ3uMzW+MtAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVg3xg0Wd7jZ4Pm/+/x/P+Emuv/M1je/zNY3v87Xt///P3+/7rmxv9GvGX/Rrxl/0azWv9GvGX/Rrxl/0a8ZP9GvGX/Rrxl/zyIo/8zWN7/M1je/4Sa6//v8fz/Z4Lm/zRZ3uM1YN8YAAAAAAAAAAAAAAAAAAAAAAAAAABJbf8HM1jfx1Ny4//v8fz/aoXm/zNY3v8zWN7/M1je/2N/5f//////tOTB/0a8Zf9HvWb/c8mH/1W+bv9IuWj/Qqp7/0a8Zf9GvGX/PIWo/zNY3v8zWN7/M1je/2qF5v/v8fz/U3Lj/zNY38dJbf8HAAAAAAAAAAAAAAAAAAAAADNY4II/YuD/4eb6/4Sa6/8zWN7/M1je/zNY3v8zWN7/j6Ps///////W8d3/pt+1/+X26v//////8/X9/zhc3v80Wdz/PIek/0a4av85d7j/M1je/zNY3v8zWN7/M1je/4Sa6//h5vr/P2Hf/zNY4IIAAAAAAAAAAAAAAAA1YN8YM1nf9KOz8P+0wvL/M1je/zNY3v8zWN7/M1je/zNY3v+6xvP///////////////////////////+zwfL/M1je/zNY3v8zWN7/NFzY/zNZ3f8zWN7/M1je/zNY3v8zWN7/M1je/7TC8v+js/D/M1nf9DVg3xgAAAAAAAAAADNY35ZLbOL/8fP8/0hp4f8zWN7/M1je/zNY3v8zWN7/M1je/+Xq+v///////////////////////////32U6v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/SGnh//Hz/P9LbOL/M1jflgAAAABVgP8GNFne8ai48f+hsu//M1je/zNY3v8zWN7/M1je/zNY3v9DZeD/////////////////////////////////V3bj/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/obLv/6i48f80Wd7xVYD/BjZa30czWN7/6e37/1Z04/8zWN7/M1je/zNY3v8zWN7/M1je/2+J5/////////////////////////////////9RcOL/Lmfi/yKN7P8XrPP/EML5/w3K+/8Suvf/HZnu/y5n4v8zWN7/M1je/zNY3v9WdOP/6e37/zNY3v82Wt9HM1nelVx65P/j6Pr/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/mavu////////////////////////////7/z//yK79v8K0v3/Fq/0/yKN7P8iiev/IY7s/xqh8P8Suff/Dcr7/y5o4v8zWN7/M1je/zNY3v/j6Pr/XHrk/zNZ3pU0WN+/iJ7r/6++8v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v/DzvX///////////////////////////9k4/7/CtL9/xK59/8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/6++8v+Inuv/NFjfvzRY3tmdr+//mqzu/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/+7x/P///////////////////////////2Xj/v8K0v3/C9D9/xmm8f8YqfP/Gafy/yKN7P8vZuH/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/mqzu/52v7/80WN7ZM1je87LA8v+Fm+v/M1je/zNY3v8zWN7/M1je/zNY3v9La+H/////////////////////////////////+P7//3Pm/v8P0/3/CtL9/wrS/f8K0v3/CtL9/wrR/f8VsvX/JYPp/zNb3v8zWN7/M1je/zNY3v+Fm+v/ssDy/zRZ3vIzWN7zssDy/4Wb6/8zWN7/M1je/zNY3v8zWN7/M1je/3SN6P////////////////////////////////////////////b+///T9///vPP//1q/9v8WrfT/DMv8/wrS/f8K0v3/DsX6/yl25v8zWN7/M1je/4Wb6/+ywPL/M1je8zRY3tmdr+//mqzu/zNY3v8zWN7/M1je/zNY3v8zWN7/m63u////////////0LWn/7qTfv/////////////////////////////+/v//////s8Dy/zNY3v8zWt7/KXbm/x2b7v8bn/D/KnPl/zNY3v8zWN7/mqzu/52v7/80WN7ZNFjfv4me6/+vvvL/M1je/zNY3v8zWN7/M1je/zNY3v+zwPL///////////+sfWT/om5R//v59///////////////////////pHFV/8Cdiv+ruvH/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v+vvvL/iJ7r/zRY378zWd6VXHrk/+Po+v8zWN7/M1je/zNY3v8zWN7/M1je/7/K9P////////////z6+f/38u/////////////////////////////NsKH/4dDH/3uT6f8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/+Po+v9ceuT/M1nelTZa30czWN7/6e37/1Z04/8zWN7/M1je/zNY3v8zWN7/p7fw///////k1c3////////////////////////////////////////////3+f3/Q2Xg/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v9WdOP/6e37/zNY3v82Wt9HVYD/BjRZ3vGouPH/oLHv/zNY3v8zWN7/M1je/zNY3v92j+j//////+7l3//gz8b/+/j2///////////////////////p3db/2MK2/6mz5P8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/6Gy7/+ouPH/NFne8VWA/wYAAAAAM1jflkts4v/x8/z/SGnh/zNY3v8zWN7/M1je/zNY3v/U3Pj////////////////////////////////////////////s7/z/RWfg/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v9IaeH/8fP8/0ts4v8zWN+WAAAAAAAAAAA1YN8YM1nf9KOz8P+zwfL/M1je/zNY3v8zWN7/M1je/0Fj4P/DzvX/////////////////////////////////8PP8/2WB5v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/7TC8v+js/D/M1nf9DVg3xgAAAAAAAAAAAAAAAAzWOCCP2Lg/+Hm+v+Emuv/M1je/zNY3v8zWN7/R2jh/0do4f97k+n/1dz4////////////7/L8/4Oa6/9CZOD/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v+Fm+v/4eb6/z9i4P8zWOCCAAAAAAAAAAAAAAAAAAAAAElt/wczWN/HU3Lj/+/x/P9qheb/M1je/zNY3v+Xqe7/7vH8/////////////////87X9/9TcuP/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/aoXm/+/x/P9TcuP/M1jfx0lt/wcAAAAAAAAAAAAAAAAAAAAAAAAAADVg3xg0Wd7jZ4Lm/+/x/P+Emuv/M1je/2J+5f+puPH/rrzx/5Kl7f9PbuL/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/4Sa6//v8fz/Z4Lm/zRZ3uM1YN8YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADdZ4y40Wd7jU3Lj/+Hm+v+0wvL/SGnh/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/0hp4f+0wvL/4eb6/1Ny4/80Wd7jM1vjLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVg3xgzWN/HP2Lg/6Oz8P/x8/z/obLv/1Z04/8zWN7/M1je/zNY3v8zWN7/M1je/zNY3v8zWN7/M1je/1Z04/+hsu//8fP8/6Oz8P8/Yd//M1jfxzVg3xgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAElt/wczWOCCM1nf9Ets4v+ouPH/6e37/+Po+v+vvvL/mqzu/4Wb6/+Fm+v/mqzu/6++8v/j6Pr/6e37/6i48f9LbOL/M1nf9DNY4IJJbf8HAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1YN8YM1jfljRZ3vEzWN7/XHrk/4ie6/+dr+//ssDy/7LA8v+dr+//iJ7r/1x65P8zWN7/NFne8TNY35Y1YN8YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVYD/BjZa30czWd6VNFjfvzRY3tkzWN7zM1je8zRY3tk0WN+/M1nelTZa30dVgP8GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/AA///AAD//AAAP/gAAB/wAAAP4AAAB8AAAAPAAAADgAAAAYAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAABgAAAAcAAAAPAAAAD4AAAB/AAAA/4AAAf/AAAP/8AAP//wAP/";
              };

              startpage = {
                name = "StartPage";
                urls = [{template = "https://www.startpage.com/sp/search?query={searchTerms}";}];
                icon = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAADb0lEQVRYhb2VXWgUVxiGv2gtWHrXBqExO2d2z5leWC80ilRKDTHunAPWhEi0gYY2mZkorYm7Z260oCiiFaQ3/RNqG/CvqAheKLSUUgpWqBdCKdbc+XMji4mhmk2MXTdvL9r4U+dsZtasH3x3877v852/IapUuzDHz6HF0/jU1/g10CgEIUq+xoMgxLAf4qIX4ksvj3c6O/FiRa8k1dyMF4IQm/0QV4MQiNkFP4+P+/rw0jOFewN4I9D4PUHwk61xrSePVVWF9+agAo2xqsMfdcnLwU8U7ufQHGhMzkL4dJe9EN3xwrdiga9xq4LZXV/jkK+xsTePZT05LPXzaPvvcBZMOj/EvQ/yWDwzgMZRo4nG0a4+vGrSduYxP9DYF4QoG/QXKoa/349M8O+1ippgb6wlJCIvh25fY8rgs6bS9LuiRJ7GT0SoiwtARORpfG5YhWNGURDifJSoR2NlknAiop5+1Psh7kdczYJR5IcYiRAMJw1/OJDGL1EDdYWGc7R9LyY/+QzlLwYxdfgkcPoscO5H/FYtwMQ9HBmfAMaKwOhfwPBt4GYBuH4ddqQAQBFP1+VqAQCcifADgAaT4HLExyXAfPXM1TSvvTNX6NiQH29bPzC2tr2/uLZ9y/i6joERAHMjJVeGrn79/Q/ncejb09i95yA2fbQHbeu3YsmKjTuTxltc9dqOwv+bOfJno6iRq2ykSKiJVCbbFDc8lWpNM0eORHlZXH5YSVtnO+oPA/mIlVEtMSZfYgt1I8rDFvJWfX3zy5UNMqqFCVU2rESZCXU8lZZvEdHj+1hncXcpE+qg7ci/I8MdBYu78f6KjLv7TSaPYOQ4E3KICfWnLdSdGb935KlY4dMTMaEGZzJN0kzI74hoTiIIW7g7bEeVZg/C/SoJABERNablcsbdC7MFYXEV+6/6JIjIvs2EGmRCFcz7rEYZd0+kuHyPOfKmESLjhlVBTJdlZe1GvibLHPkuE7LLymTVa7Z8nR7b44Xp1sXMUaOG8zBl8WzvM0HEAuXyTebIomElSpaQHTWHaOTStR113wAxmUq7rTWHSHF3AxPqQTSEHGMiu6LmECwjNzEhpwyP1O0UdxfVHoLLbRUeqks1ByAisoQ8YNiK0nMBICKyufzmqbdByHPPDYCI5jIu99lCDTNHFhl3TzQ0rH7lHy2g5RVQKFbLAAAAAElFTkSuQmCC";
              };

              searxng = {
                name = "SearXNG";
                urls = [
                  {
                    template = "https://searx.be/";
                    method = "POST";
                    params = [
                      {
                        name = "q";
                        value = "{searchTerms}";
                      }
                      {
                        name = "time_range";
                        value = "";
                      }
                      {
                        name = "language";
                        value = "en-US";
                      }
                      {
                        name = "category_general";
                        value = "on";
                      }
                    ];
                  }
                ];
                icon = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI5Mm1tIiBoZWlnaHQ9IjkybW0iIHZpZXdCb3g9IjAgMCA5MiA5MiI+PGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTQwLjkyMSAtMTcuNDE3KSI+PGNpcmNsZSBjeD0iNzUuOTIxIiBjeT0iNTMuOTAzIiByPSIzMCIgc3R5bGU9ImZpbGw6bm9uZTtmaWxsLW9wYWNpdHk6MTtzdHJva2U6IzMwNTBmZjtzdHJva2Utd2lkdGg6MTA7c3Ryb2tlLW1pdGVybGltaXQ6NDtzdHJva2UtZGFzaGFycmF5Om5vbmU7c3Ryb2tlLW9wYWNpdHk6MSIvPjxwYXRoIGQ9Ik02Ny41MTUgMzcuOTE1YTE4IDE4IDAgMCAxIDIxLjA1MSAzLjMxMyAxOCAxOCAwIDAgMSAzLjEzOCAyMS4wNzgiIHN0eWxlPSJmaWxsOm5vbmU7ZmlsbC1vcGFjaXR5OjE7c3Ryb2tlOiMzMDUwZmY7c3Ryb2tlLXdpZHRoOjU7c3Ryb2tlLW1pdGVybGltaXQ6NDtzdHJva2UtZGFzaGFycmF5Om5vbmU7c3Ryb2tlLW9wYWNpdHk6MSIvPjxyZWN0IHdpZHRoPSIxOC44NDYiIGhlaWdodD0iMzkuOTYzIiB4PSIzLjcwNiIgeT0iMTIyLjA5IiByeT0iMCIgc3R5bGU9Im9wYWNpdHk6MTtmaWxsOiMzMDUwZmY7ZmlsbC1vcGFjaXR5OjE7c3Ryb2tlOm5vbmU7c3Ryb2tlLXdpZHRoOjg7c3Ryb2tlLW1pdGVybGltaXQ6NDtzdHJva2UtZGFzaGFycmF5Om5vbmU7c3Ryb2tlLW9wYWNpdHk6MSIgdHJhbnNmb3JtPSJyb3RhdGUoLTQ2LjIzNSkiLz48L2c+PC9zdmc+";
              };

              metager = {
                name = "MetaGer";
                urls = [{template = "https://metager.org/meta/meta.ger3?eingabe={searchTerms}";}];
                icon = "data:image/x-icon;base64,AAABAAEAQEAAAAEACAAoFgAAFgAAACgAAABAAAAAgAAAAAEACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgP4AAYD+AACA/wADgf4ABIH+AAWC/gAGgv4ACYT+AAuF/gAMhf4ADYb+AA6G/gAPh/4AEIf+ABGI/gATif4AFIn+ABWK/gAWiv4AF4v+ABmM/gAajP4AG43+AByN/gAejv4AIZD+ACSR/gAmkv4AJ5L+ACmU/gAqlP4ALJX+AC2W/gAulv4AMpj+ADSZ/gA5m/4AO5z+AD6e/gA/n/4AQJ/+AEKg/gBDof4ARKH+AEWi/gBGov4ASKP+AEyl/gBPpv4AU6j+AFWq/gBXq/4AWKv+AFut/gBcrf4AX6/+AGGw/gBksf4AZ7L+AGq0/gBvtv4Acbf+AHO4/gB0uf4Adrr+AHe6/gB4u/4Afr7+AIC//gCBwP4Ah8P+AIjD/gCJxP4AisT+AIvF/gCNxv4AkMf+AJHI/gCSyP4Ak8n+AJTJ/gCVyv4Alsr+AJjL/gCazP4AnM3+AJ7O/gCgz/4AodD+AKLQ/gCk0f4AptL+AKjT/gCq1P4ArdX+AK7W/gCv1v4AsNf+ALXZ/gC22v4At9r+ALjb/gC52/4AvN3+AMPg/gDE4f4AxuL+AMrk/gDM5f4Azub+AM/m/gDQ5/4A0ef+ANLo/gDU6f4A1ur+ANnr/gDb7P4A3+7+AOHv/gDk8f4A5fH+AOby/gDn8v4A6PP+AOnz/gDq9P4A6/T+AO31/gDv9v4A8/j+APX5/gD2+v4A9/r+APj7/gD5+/4A+vz+APv8/gD8/f4A/f3+AP///wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAnyMjIyMHgICAgICAgICAgICAgIDhYyMjIwSAgICAgICAgIEMlVxfoiEfXJeRSYDAgICAgICAgICAgICAgICAgJmjIyMjDQCAgICAgICAgICAgICAm2MjIyMKwICAgICAgIzeIyMjIyMjIyMjIyMgU8dAgICAgICAgICAgICAgICSoyMjIxGAgICAgICAgICAgICAgJXjIyMjD4CAgICAgJMjIyMjIyMjIyMjIyMjIyMhQUCAgICAgICAgICAgICAjaMjIyMYwICAgICAgICAgICAgICPYyMjIxYAgICAgJAjIyMjIyMjIyMjIyMjIyMjIwjAgICAgICAgICAgICAgIhjIyMjHkCAgICAjtoaGIIAgICAiqMjIyMbwICAgIWg4yMjIyMXCoOAQMPJWmMjIyMOwICAgICAgICAgICAgICBYeMjIyMEAICAgJtjIyMUgICAgIQjIyMjIYEAgICQ4yMjIyMOAICAgICAgJCjIyMjFcCAgICAgICAgICAgICAgJwjIyMjCkCAgIVjIyMjIwrAgICAnqMjIyMIAICAmqMjIyMWgICAgICAgICKoyMjIxzAgICAgICAgICAgICAgICWYyMjIw9AgICOYyMjIyMdwsCAgJljIyMjDUCAgJ9jIyMjCcCAgICAgICAgyLjIyMiwoCAgICAgICAgICAgICAj+MjIyMVwICAmCMjIyMjIxWAgICSYyMjIxJAgICh4yMjIwMAgICAgJkjIyMjIyMjIwpAgICAgICAgICAgICAgIsjIyMjG4CAgaCjIyMjIyMjC8CAjWMjIyMZQICAn+MjIyMBAICAgICRoyMjIyMjIyMQgICAgICAgICAgICAgICEoyMjIyGBAIsjIyMjGiMjIx6DgIgjIyMjHsCAgJzjIyMjBMCAgICAjOMjIyMjIyMjF8CAgICAgICAgICAgICAgJ8jIyMjB8CTIyMjHYNeIyMjFsCBIeMjIyMEgICXYyMjIwnAgICAgIcjIyMjIyMjIx4AgICAgICAgICAgICAgICZoyMjIw1AnWMjIxQAi6MjIyMMQJvjIyMjCsCAjqMjIyMRwICAgICAgICAgICAgICAgICAgICAgICAgICAgICAkqMjIyMSRuMjIyMLgICVIyMjH4RWYyMjIw+AgIXiIyMjH8KAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI2jIyMjGY9jIyMggYCAgl2jIyMXj+MjIyMWAICAlmMjIyMUQICAgICAgICAgICAgICAgICAgICAgICAgICAgICIYyMjIx8Z4yMjGECAgICKIuMjIxZjIyMjG8CAgIchYyMjIw8AgICAgICAgICAgICAgICAgICAgICAgICAgICAgWHjIyMjImMjIw5AgICAgJOjIyMiYyMjIyGBAICAjyMjIyMjFMMAgICAgICAgIBMGwYAgICAgICAgICAgICAgICcIyMjIyMjIyLFAICAgICB3SMjIyMjIyMjCACAgICXYyMjIyMgUstFgYJGTFNeYyMMwICAgICAgICAgICAgICAlmMjIyMjIyMbAICAgICAgIkioyMjIyMjIw1AgICAgRdjIyMjIyMjIyMjIyMjIyMjE0CAgICAgICAgICAgICAgI/jIyMjIyMjEQCAgICAgICAkiMjIyMjIyMSQICAgICAEGFjIyMjIyMjIyMjIyMjIxrAgICAgICAgICAgICAgICLIyMjIyMjIwjAgICAgICAgIGcoyMjIyMjGUCAgICAgICGliHjIyMjIyMjIyMjIx/TAICAgICAgICAgICAgICAhKMjIyMjIx6AAICAgICAgICAiKIjIyMjIx7AgICAgICAgICDjdWa32FiIBzYEMmBAICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
              };

              nix-packages = {
                name = "Nix Packages";
                urls = [{template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";}];
                definedAliases = ["@np"];
                icon = "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhLS0gQ3JlYXRlZCB3aXRoIElua3NjYXBlIChodHRwOi8vd3d3Lmlua3NjYXBlLm9yZy8pIC0tPgoKPHN2ZwogICB3aWR0aD0iNTM1IgogICBoZWlnaHQ9IjUzNSIKICAgdmlld0JveD0iMCAwIDUwMS41NjI1MSA1MDEuNTYyNDkiCiAgIGlkPSJzdmcyIgogICB2ZXJzaW9uPSIxLjEiCiAgIGlua3NjYXBlOnZlcnNpb249IjEuMy4yICgwOTFlMjBlZjBmLCAyMDIzLTExLTI1KSIKICAgc29kaXBvZGk6ZG9jbmFtZT0ibml4LXNub3dmbGFrZS1jb2xvdXJzLnN2ZyIKICAgeG1sbnM6aW5rc2NhcGU9Imh0dHA6Ly93d3cuaW5rc2NhcGUub3JnL25hbWVzcGFjZXMvaW5rc2NhcGUiCiAgIHhtbG5zOnNvZGlwb2RpPSJodHRwOi8vc29kaXBvZGkuc291cmNlZm9yZ2UubmV0L0RURC9zb2RpcG9kaS0wLmR0ZCIKICAgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiCiAgIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6c3ZnPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIgogICB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIgogICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogIDxkZWZzCiAgICAgaWQ9ImRlZnM0Ij4KICAgIDxsaW5lYXJHcmFkaWVudAogICAgICAgaW5rc2NhcGU6Y29sbGVjdD0iYWx3YXlzIgogICAgICAgaWQ9ImxpbmVhckdyYWRpZW50NTU2MiI+CiAgICAgIDxzdG9wCiAgICAgICAgIHN0eWxlPSJzdG9wLWNvbG9yOiM2OTlhZDc7c3RvcC1vcGFjaXR5OjEiCiAgICAgICAgIG9mZnNldD0iMCIKICAgICAgICAgaWQ9InN0b3A1NTY0IiAvPgogICAgICA8c3RvcAogICAgICAgICBpZD0ic3RvcDU1NjYiCiAgICAgICAgIG9mZnNldD0iMC4yNDM0NTE5OCIKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzdlYjFkZDtzdG9wLW9wYWNpdHk6MSIgLz4KICAgICAgPHN0b3AKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzdlYmFlNDtzdG9wLW9wYWNpdHk6MSIKICAgICAgICAgb2Zmc2V0PSIxIgogICAgICAgICBpZD0ic3RvcDU1NjgiIC8+CiAgICA8L2xpbmVhckdyYWRpZW50PgogICAgPGxpbmVhckdyYWRpZW50CiAgICAgICBpbmtzY2FwZTpjb2xsZWN0PSJhbHdheXMiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ1MDUzIj4KICAgICAgPHN0b3AKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzQxNWU5YTtzdG9wLW9wYWNpdHk6MSIKICAgICAgICAgb2Zmc2V0PSIwIgogICAgICAgICBpZD0ic3RvcDUwNTUiIC8+CiAgICAgIDxzdG9wCiAgICAgICAgIGlkPSJzdG9wNTA1NyIKICAgICAgICAgb2Zmc2V0PSIwLjIzMTY4NjQ0IgogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojNGE2YmFmO3N0b3Atb3BhY2l0eToxIiAvPgogICAgICA8c3RvcAogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojNTI3N2MzO3N0b3Atb3BhY2l0eToxIgogICAgICAgICBvZmZzZXQ9IjEiCiAgICAgICAgIGlkPSJzdG9wNTA1OSIgLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGlua3NjYXBlOmNvbGxlY3Q9ImFsd2F5cyIKICAgICAgIHhsaW5rOmhyZWY9IiNsaW5lYXJHcmFkaWVudDU1NjIiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ0MzI4IgogICAgICAgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBncmFkaWVudFRyYW5zZm9ybT0idHJhbnNsYXRlKDcwLjY1MDMzOSwtMTA1NS4xNTExKSIKICAgICAgIHgxPSIyMDAuNTk2NjgiCiAgICAgICB5MT0iMzUxLjQxMTE2IgogICAgICAgeDI9IjI5MC4wODcwMSIKICAgICAgIHkyPSI1MDYuMTg4MTQiIC8+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGlua3NjYXBlOmNvbGxlY3Q9ImFsd2F5cyIKICAgICAgIHhsaW5rOmhyZWY9IiNsaW5lYXJHcmFkaWVudDUwNTMiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ0MzMwIgogICAgICAgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBncmFkaWVudFRyYW5zZm9ybT0idHJhbnNsYXRlKDg2NC42OTU4OSwtMTQ5MS4zNDA1KSIKICAgICAgIHgxPSItNTg0LjE5OTM0IgogICAgICAgeTE9Ijc4Mi4zMzU2MyIKICAgICAgIHgyPSItNDk2LjI5NzAzIgogICAgICAgeTI9IjkzNy43MTM5OSIgLz4KICA8L2RlZnM+CiAgPHNvZGlwb2RpOm5hbWVkdmlldwogICAgIGlkPSJiYXNlIgogICAgIHBhZ2Vjb2xvcj0iI2ZmZmZmZiIKICAgICBib3JkZXJjb2xvcj0iIzY2NjY2NiIKICAgICBib3JkZXJvcGFjaXR5PSIxLjAiCiAgICAgaW5rc2NhcGU6cGFnZW9wYWNpdHk9IjAuMCIKICAgICBpbmtzY2FwZTpwYWdlc2hhZG93PSIyIgogICAgIGlua3NjYXBlOnpvb209IjAuNzA5MDQzNjgiCiAgICAgaW5rc2NhcGU6Y3g9Ijk5LjQyOTY5OSIKICAgICBpbmtzY2FwZTpjeT0iMTk1LjMzMzUyIgogICAgIGlua3NjYXBlOmRvY3VtZW50LXVuaXRzPSJweCIKICAgICBpbmtzY2FwZTpjdXJyZW50LWxheWVyPSJsYXllcjMiCiAgICAgc2hvd2dyaWQ9ImZhbHNlIgogICAgIGlua3NjYXBlOndpbmRvdy13aWR0aD0iMTkyMCIKICAgICBpbmtzY2FwZTp3aW5kb3ctaGVpZ2h0PSIxMDUwIgogICAgIGlua3NjYXBlOndpbmRvdy14PSIxOTIwIgogICAgIGlua3NjYXBlOndpbmRvdy15PSIzMCIKICAgICBpbmtzY2FwZTp3aW5kb3ctbWF4aW1pemVkPSIxIgogICAgIGlua3NjYXBlOnNuYXAtZ2xvYmFsPSJ0cnVlIgogICAgIGZpdC1tYXJnaW4tdG9wPSIwIgogICAgIGZpdC1tYXJnaW4tbGVmdD0iMCIKICAgICBmaXQtbWFyZ2luLXJpZ2h0PSIwIgogICAgIGZpdC1tYXJnaW4tYm90dG9tPSIwIgogICAgIGlua3NjYXBlOnNob3dwYWdlc2hhZG93PSIyIgogICAgIGlua3NjYXBlOnBhZ2VjaGVja2VyYm9hcmQ9IjAiCiAgICAgaW5rc2NhcGU6ZGVza2NvbG9yPSIjZDFkMWQxIiAvPgogIDxtZXRhZGF0YQogICAgIGlkPSJtZXRhZGF0YTciPgogICAgPHJkZjpSREY+CiAgICAgIDxjYzpXb3JrCiAgICAgICAgIHJkZjphYm91dD0iIj4KICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3N2Zyt4bWw8L2RjOmZvcm1hdD4KICAgICAgICA8ZGM6dHlwZQogICAgICAgICAgIHJkZjpyZXNvdXJjZT0iaHR0cDovL3B1cmwub3JnL2RjL2RjbWl0eXBlL1N0aWxsSW1hZ2UiIC8+CiAgICAgIDwvY2M6V29yaz4KICAgIDwvcmRmOlJERj4KICA8L21ldGFkYXRhPgogIDxnCiAgICAgaW5rc2NhcGU6Z3JvdXBtb2RlPSJsYXllciIKICAgICBpZD0ibGF5ZXIzIgogICAgIGlua3NjYXBlOmxhYmVsPSJncmFkaWVudC1sb2dvIgogICAgIHN0eWxlPSJkaXNwbGF5OmlubGluZTtvcGFjaXR5OjEiCiAgICAgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTE1Ni40MTEyMSw5MzMuMzA2ODUpIj4KICAgIDxnCiAgICAgICBpZD0iZzIiCiAgICAgICB0cmFuc2Zvcm09Im1hdHJpeCgwLjk5OTk0MDU5LDAsMCwwLjk5OTk0MDU5LC0wLjA2MzIxNzk4LDMzLjE4ODM3NykiCiAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjEuMDAwMDYiPgogICAgICA8cGF0aAogICAgICAgICBzb2RpcG9kaTpub2RldHlwZXM9ImNjY2NjY2NjY2MiCiAgICAgICAgIGlua3NjYXBlOmNvbm5lY3Rvci1jdXJ2YXR1cmU9IjAiCiAgICAgICAgIGlkPSJwYXRoMzMzNi02IgogICAgICAgICBkPSJtIDMwOS41NDg5MiwtNzEwLjM4ODI3IDEyMi4xOTY4MywyMTEuNjc1MTIgLTU2LjE1NzA2LDAuNTI2OCAtMzIuNjIzNiwtNTYuODY5MiAtMzIuODU2NDUsNTYuNTY1MyAtMjcuOTAyMzcsLTAuMDExIC0xNC4yOTA4NiwtMjQuNjg5NiA0Ni44MTA0NywtODAuNDkwMSAtMzMuMjI5NDYsLTU3LjgyNTcgeiIKICAgICAgICAgc3R5bGU9Im9wYWNpdHk6MTtmaWxsOnVybCgjbGluZWFyR3JhZGllbnQ0MzI4KTtmaWxsLW9wYWNpdHk6MTtmaWxsLXJ1bGU6ZXZlbm9kZDtzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6My4wMDAxODtzdHJva2UtbGluZWNhcDpidXR0O3N0cm9rZS1saW5lam9pbjpyb3VuZDtzdHJva2UtbWl0ZXJsaW1pdDo0O3N0cm9rZS1kYXNoYXJyYXk6bm9uZTtzdHJva2Utb3BhY2l0eToxIiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKDYwLDQwNy4xMTE1NSwtNzE1Ljc4NzI0KSIKICAgICAgICAgaWQ9InVzZTM0MzktNiIKICAgICAgICAgaW5rc2NhcGU6dHJhbnNmb3JtLWNlbnRlci15PSIxNTEuNTkwODIiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteD0iMTI0LjQzMDQ1IgogICAgICAgICB4bGluazpocmVmPSIjcGF0aDMzMzYtNiIKICAgICAgICAgeT0iMCIKICAgICAgICAgeD0iMCIKICAgICAgICAgc3R5bGU9InN0cm9rZS13aWR0aDoxLjAwMDA2IiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKC02MCw0MDcuMzExNzcsLTcxNS43MDAxNikiCiAgICAgICAgIGlkPSJ1c2UzNDQ1LTAiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteT0iNzUuNTczOTU4IgogICAgICAgICBpbmtzY2FwZTp0cmFuc2Zvcm0tY2VudGVyLXg9Ii0xNjguMjA2NTEiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoMzMzNi02IgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICAgIDx1c2UKICAgICAgICAgaGVpZ2h0PSIxMDAlIgogICAgICAgICB3aWR0aD0iMTAwJSIKICAgICAgICAgdHJhbnNmb3JtPSJyb3RhdGUoMTgwLDQwNy40MTg2OCwtNzE1Ljc1NjUpIgogICAgICAgICBpZD0idXNlMzQ0OS01IgogICAgICAgICBpbmtzY2FwZTp0cmFuc2Zvcm0tY2VudGVyLXk9Ii0xMzkuOTQ1OTIiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteD0iNTkuNjY5NzA1IgogICAgICAgICB4bGluazpocmVmPSIjcGF0aDMzMzYtNiIKICAgICAgICAgeT0iMCIKICAgICAgICAgeD0iMCIKICAgICAgICAgc3R5bGU9InN0cm9rZS13aWR0aDoxLjAwMDA2IiAvPgogICAgICA8cGF0aAogICAgICAgICBzdHlsZT0iY29sb3I6IzAwMDAwMDtjbGlwLXJ1bGU6bm9uemVybztkaXNwbGF5OmlubGluZTtvdmVyZmxvdzp2aXNpYmxlO3Zpc2liaWxpdHk6dmlzaWJsZTtvcGFjaXR5OjE7aXNvbGF0aW9uOmF1dG87bWl4LWJsZW5kLW1vZGU6bm9ybWFsO2NvbG9yLWludGVycG9sYXRpb246c1JHQjtjb2xvci1pbnRlcnBvbGF0aW9uLWZpbHRlcnM6bGluZWFyUkdCO3NvbGlkLWNvbG9yOiMwMDAwMDA7c29saWQtb3BhY2l0eToxO2ZpbGw6dXJsKCNsaW5lYXJHcmFkaWVudDQzMzApO2ZpbGwtb3BhY2l0eToxO2ZpbGwtcnVsZTpldmVub2RkO3N0cm9rZTpub25lO3N0cm9rZS13aWR0aDozLjAwMDE4O3N0cm9rZS1saW5lY2FwOmJ1dHQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kO3N0cm9rZS1taXRlcmxpbWl0OjQ7c3Ryb2tlLWRhc2hhcnJheTpub25lO3N0cm9rZS1kYXNob2Zmc2V0OjA7c3Ryb2tlLW9wYWNpdHk6MTtjb2xvci1yZW5kZXJpbmc6YXV0bztpbWFnZS1yZW5kZXJpbmc6YXV0bztzaGFwZS1yZW5kZXJpbmc6YXV0bzt0ZXh0LXJlbmRlcmluZzphdXRvO2VuYWJsZS1iYWNrZ3JvdW5kOmFjY3VtdWxhdGUiCiAgICAgICAgIGQ9Im0gMzA5LjU0ODkyLC03MTAuMzg4MjcgMTIyLjE5NjgzLDIxMS42NzUxMiAtNTYuMTU3MDYsMC41MjY4IC0zMi42MjM2LC01Ni44NjkyIC0zMi44NTY0NSw1Ni41NjUzIC0yNy45MDIzNywtMC4wMTEgLTE0LjI5MDg2LC0yNC42ODk2IDQ2LjgxMDQ3LC04MC40OTAxIC0zMy4yMjk0NiwtNTcuODI1NiB6IgogICAgICAgICBpZD0icGF0aDQyNjAtMCIKICAgICAgICAgaW5rc2NhcGU6Y29ubmVjdG9yLWN1cnZhdHVyZT0iMCIKICAgICAgICAgc29kaXBvZGk6bm9kZXR5cGVzPSJjY2NjY2NjY2NjIiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKDEyMCw0MDcuMzM5MTYsLTcxNi4wODM1NikiCiAgICAgICAgIGlkPSJ1c2U0MzU0LTUiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoNDI2MC0wIgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmU7c3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICAgIDx1c2UKICAgICAgICAgaGVpZ2h0PSIxMDAlIgogICAgICAgICB3aWR0aD0iMTAwJSIKICAgICAgICAgdHJhbnNmb3JtPSJyb3RhdGUoLTEyMCw0MDcuMjg4MjMsLTcxNS44Njk5NSkiCiAgICAgICAgIGlkPSJ1c2U0MzYyLTIiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoNDI2MC0wIgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmU7c3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICA8L2c+CiAgPC9nPgo8L3N2Zz4K";
              };

              nix-options = {
                name = "Nix Options";
                urls = [{template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";}];
                definedAliases = ["@no"];
                icon = "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhLS0gQ3JlYXRlZCB3aXRoIElua3NjYXBlIChodHRwOi8vd3d3Lmlua3NjYXBlLm9yZy8pIC0tPgoKPHN2ZwogICB3aWR0aD0iNTM1IgogICBoZWlnaHQ9IjUzNSIKICAgdmlld0JveD0iMCAwIDUwMS41NjI1MSA1MDEuNTYyNDkiCiAgIGlkPSJzdmcyIgogICB2ZXJzaW9uPSIxLjEiCiAgIGlua3NjYXBlOnZlcnNpb249IjEuMy4yICgwOTFlMjBlZjBmLCAyMDIzLTExLTI1KSIKICAgc29kaXBvZGk6ZG9jbmFtZT0ibml4LXNub3dmbGFrZS1jb2xvdXJzLnN2ZyIKICAgeG1sbnM6aW5rc2NhcGU9Imh0dHA6Ly93d3cuaW5rc2NhcGUub3JnL25hbWVzcGFjZXMvaW5rc2NhcGUiCiAgIHhtbG5zOnNvZGlwb2RpPSJodHRwOi8vc29kaXBvZGkuc291cmNlZm9yZ2UubmV0L0RURC9zb2RpcG9kaS0wLmR0ZCIKICAgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiCiAgIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6c3ZnPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIgogICB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIgogICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogIDxkZWZzCiAgICAgaWQ9ImRlZnM0Ij4KICAgIDxsaW5lYXJHcmFkaWVudAogICAgICAgaW5rc2NhcGU6Y29sbGVjdD0iYWx3YXlzIgogICAgICAgaWQ9ImxpbmVhckdyYWRpZW50NTU2MiI+CiAgICAgIDxzdG9wCiAgICAgICAgIHN0eWxlPSJzdG9wLWNvbG9yOiM2OTlhZDc7c3RvcC1vcGFjaXR5OjEiCiAgICAgICAgIG9mZnNldD0iMCIKICAgICAgICAgaWQ9InN0b3A1NTY0IiAvPgogICAgICA8c3RvcAogICAgICAgICBpZD0ic3RvcDU1NjYiCiAgICAgICAgIG9mZnNldD0iMC4yNDM0NTE5OCIKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzdlYjFkZDtzdG9wLW9wYWNpdHk6MSIgLz4KICAgICAgPHN0b3AKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzdlYmFlNDtzdG9wLW9wYWNpdHk6MSIKICAgICAgICAgb2Zmc2V0PSIxIgogICAgICAgICBpZD0ic3RvcDU1NjgiIC8+CiAgICA8L2xpbmVhckdyYWRpZW50PgogICAgPGxpbmVhckdyYWRpZW50CiAgICAgICBpbmtzY2FwZTpjb2xsZWN0PSJhbHdheXMiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ1MDUzIj4KICAgICAgPHN0b3AKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzQxNWU5YTtzdG9wLW9wYWNpdHk6MSIKICAgICAgICAgb2Zmc2V0PSIwIgogICAgICAgICBpZD0ic3RvcDUwNTUiIC8+CiAgICAgIDxzdG9wCiAgICAgICAgIGlkPSJzdG9wNTA1NyIKICAgICAgICAgb2Zmc2V0PSIwLjIzMTY4NjQ0IgogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojNGE2YmFmO3N0b3Atb3BhY2l0eToxIiAvPgogICAgICA8c3RvcAogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojNTI3N2MzO3N0b3Atb3BhY2l0eToxIgogICAgICAgICBvZmZzZXQ9IjEiCiAgICAgICAgIGlkPSJzdG9wNTA1OSIgLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGlua3NjYXBlOmNvbGxlY3Q9ImFsd2F5cyIKICAgICAgIHhsaW5rOmhyZWY9IiNsaW5lYXJHcmFkaWVudDU1NjIiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ0MzI4IgogICAgICAgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBncmFkaWVudFRyYW5zZm9ybT0idHJhbnNsYXRlKDcwLjY1MDMzOSwtMTA1NS4xNTExKSIKICAgICAgIHgxPSIyMDAuNTk2NjgiCiAgICAgICB5MT0iMzUxLjQxMTE2IgogICAgICAgeDI9IjI5MC4wODcwMSIKICAgICAgIHkyPSI1MDYuMTg4MTQiIC8+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGlua3NjYXBlOmNvbGxlY3Q9ImFsd2F5cyIKICAgICAgIHhsaW5rOmhyZWY9IiNsaW5lYXJHcmFkaWVudDUwNTMiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ0MzMwIgogICAgICAgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBncmFkaWVudFRyYW5zZm9ybT0idHJhbnNsYXRlKDg2NC42OTU4OSwtMTQ5MS4zNDA1KSIKICAgICAgIHgxPSItNTg0LjE5OTM0IgogICAgICAgeTE9Ijc4Mi4zMzU2MyIKICAgICAgIHgyPSItNDk2LjI5NzAzIgogICAgICAgeTI9IjkzNy43MTM5OSIgLz4KICA8L2RlZnM+CiAgPHNvZGlwb2RpOm5hbWVkdmlldwogICAgIGlkPSJiYXNlIgogICAgIHBhZ2Vjb2xvcj0iI2ZmZmZmZiIKICAgICBib3JkZXJjb2xvcj0iIzY2NjY2NiIKICAgICBib3JkZXJvcGFjaXR5PSIxLjAiCiAgICAgaW5rc2NhcGU6cGFnZW9wYWNpdHk9IjAuMCIKICAgICBpbmtzY2FwZTpwYWdlc2hhZG93PSIyIgogICAgIGlua3NjYXBlOnpvb209IjAuNzA5MDQzNjgiCiAgICAgaW5rc2NhcGU6Y3g9Ijk5LjQyOTY5OSIKICAgICBpbmtzY2FwZTpjeT0iMTk1LjMzMzUyIgogICAgIGlua3NjYXBlOmRvY3VtZW50LXVuaXRzPSJweCIKICAgICBpbmtzY2FwZTpjdXJyZW50LWxheWVyPSJsYXllcjMiCiAgICAgc2hvd2dyaWQ9ImZhbHNlIgogICAgIGlua3NjYXBlOndpbmRvdy13aWR0aD0iMTkyMCIKICAgICBpbmtzY2FwZTp3aW5kb3ctaGVpZ2h0PSIxMDUwIgogICAgIGlua3NjYXBlOndpbmRvdy14PSIxOTIwIgogICAgIGlua3NjYXBlOndpbmRvdy15PSIzMCIKICAgICBpbmtzY2FwZTp3aW5kb3ctbWF4aW1pemVkPSIxIgogICAgIGlua3NjYXBlOnNuYXAtZ2xvYmFsPSJ0cnVlIgogICAgIGZpdC1tYXJnaW4tdG9wPSIwIgogICAgIGZpdC1tYXJnaW4tbGVmdD0iMCIKICAgICBmaXQtbWFyZ2luLXJpZ2h0PSIwIgogICAgIGZpdC1tYXJnaW4tYm90dG9tPSIwIgogICAgIGlua3NjYXBlOnNob3dwYWdlc2hhZG93PSIyIgogICAgIGlua3NjYXBlOnBhZ2VjaGVja2VyYm9hcmQ9IjAiCiAgICAgaW5rc2NhcGU6ZGVza2NvbG9yPSIjZDFkMWQxIiAvPgogIDxtZXRhZGF0YQogICAgIGlkPSJtZXRhZGF0YTciPgogICAgPHJkZjpSREY+CiAgICAgIDxjYzpXb3JrCiAgICAgICAgIHJkZjphYm91dD0iIj4KICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3N2Zyt4bWw8L2RjOmZvcm1hdD4KICAgICAgICA8ZGM6dHlwZQogICAgICAgICAgIHJkZjpyZXNvdXJjZT0iaHR0cDovL3B1cmwub3JnL2RjL2RjbWl0eXBlL1N0aWxsSW1hZ2UiIC8+CiAgICAgIDwvY2M6V29yaz4KICAgIDwvcmRmOlJERj4KICA8L21ldGFkYXRhPgogIDxnCiAgICAgaW5rc2NhcGU6Z3JvdXBtb2RlPSJsYXllciIKICAgICBpZD0ibGF5ZXIzIgogICAgIGlua3NjYXBlOmxhYmVsPSJncmFkaWVudC1sb2dvIgogICAgIHN0eWxlPSJkaXNwbGF5OmlubGluZTtvcGFjaXR5OjEiCiAgICAgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTE1Ni40MTEyMSw5MzMuMzA2ODUpIj4KICAgIDxnCiAgICAgICBpZD0iZzIiCiAgICAgICB0cmFuc2Zvcm09Im1hdHJpeCgwLjk5OTk0MDU5LDAsMCwwLjk5OTk0MDU5LC0wLjA2MzIxNzk4LDMzLjE4ODM3NykiCiAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjEuMDAwMDYiPgogICAgICA8cGF0aAogICAgICAgICBzb2RpcG9kaTpub2RldHlwZXM9ImNjY2NjY2NjY2MiCiAgICAgICAgIGlua3NjYXBlOmNvbm5lY3Rvci1jdXJ2YXR1cmU9IjAiCiAgICAgICAgIGlkPSJwYXRoMzMzNi02IgogICAgICAgICBkPSJtIDMwOS41NDg5MiwtNzEwLjM4ODI3IDEyMi4xOTY4MywyMTEuNjc1MTIgLTU2LjE1NzA2LDAuNTI2OCAtMzIuNjIzNiwtNTYuODY5MiAtMzIuODU2NDUsNTYuNTY1MyAtMjcuOTAyMzcsLTAuMDExIC0xNC4yOTA4NiwtMjQuNjg5NiA0Ni44MTA0NywtODAuNDkwMSAtMzMuMjI5NDYsLTU3LjgyNTcgeiIKICAgICAgICAgc3R5bGU9Im9wYWNpdHk6MTtmaWxsOnVybCgjbGluZWFyR3JhZGllbnQ0MzI4KTtmaWxsLW9wYWNpdHk6MTtmaWxsLXJ1bGU6ZXZlbm9kZDtzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6My4wMDAxODtzdHJva2UtbGluZWNhcDpidXR0O3N0cm9rZS1saW5lam9pbjpyb3VuZDtzdHJva2UtbWl0ZXJsaW1pdDo0O3N0cm9rZS1kYXNoYXJyYXk6bm9uZTtzdHJva2Utb3BhY2l0eToxIiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKDYwLDQwNy4xMTE1NSwtNzE1Ljc4NzI0KSIKICAgICAgICAgaWQ9InVzZTM0MzktNiIKICAgICAgICAgaW5rc2NhcGU6dHJhbnNmb3JtLWNlbnRlci15PSIxNTEuNTkwODIiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteD0iMTI0LjQzMDQ1IgogICAgICAgICB4bGluazpocmVmPSIjcGF0aDMzMzYtNiIKICAgICAgICAgeT0iMCIKICAgICAgICAgeD0iMCIKICAgICAgICAgc3R5bGU9InN0cm9rZS13aWR0aDoxLjAwMDA2IiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKC02MCw0MDcuMzExNzcsLTcxNS43MDAxNikiCiAgICAgICAgIGlkPSJ1c2UzNDQ1LTAiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteT0iNzUuNTczOTU4IgogICAgICAgICBpbmtzY2FwZTp0cmFuc2Zvcm0tY2VudGVyLXg9Ii0xNjguMjA2NTEiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoMzMzNi02IgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICAgIDx1c2UKICAgICAgICAgaGVpZ2h0PSIxMDAlIgogICAgICAgICB3aWR0aD0iMTAwJSIKICAgICAgICAgdHJhbnNmb3JtPSJyb3RhdGUoMTgwLDQwNy40MTg2OCwtNzE1Ljc1NjUpIgogICAgICAgICBpZD0idXNlMzQ0OS01IgogICAgICAgICBpbmtzY2FwZTp0cmFuc2Zvcm0tY2VudGVyLXk9Ii0xMzkuOTQ1OTIiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteD0iNTkuNjY5NzA1IgogICAgICAgICB4bGluazpocmVmPSIjcGF0aDMzMzYtNiIKICAgICAgICAgeT0iMCIKICAgICAgICAgeD0iMCIKICAgICAgICAgc3R5bGU9InN0cm9rZS13aWR0aDoxLjAwMDA2IiAvPgogICAgICA8cGF0aAogICAgICAgICBzdHlsZT0iY29sb3I6IzAwMDAwMDtjbGlwLXJ1bGU6bm9uemVybztkaXNwbGF5OmlubGluZTtvdmVyZmxvdzp2aXNpYmxlO3Zpc2liaWxpdHk6dmlzaWJsZTtvcGFjaXR5OjE7aXNvbGF0aW9uOmF1dG87bWl4LWJsZW5kLW1vZGU6bm9ybWFsO2NvbG9yLWludGVycG9sYXRpb246c1JHQjtjb2xvci1pbnRlcnBvbGF0aW9uLWZpbHRlcnM6bGluZWFyUkdCO3NvbGlkLWNvbG9yOiMwMDAwMDA7c29saWQtb3BhY2l0eToxO2ZpbGw6dXJsKCNsaW5lYXJHcmFkaWVudDQzMzApO2ZpbGwtb3BhY2l0eToxO2ZpbGwtcnVsZTpldmVub2RkO3N0cm9rZTpub25lO3N0cm9rZS13aWR0aDozLjAwMDE4O3N0cm9rZS1saW5lY2FwOmJ1dHQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kO3N0cm9rZS1taXRlcmxpbWl0OjQ7c3Ryb2tlLWRhc2hhcnJheTpub25lO3N0cm9rZS1kYXNob2Zmc2V0OjA7c3Ryb2tlLW9wYWNpdHk6MTtjb2xvci1yZW5kZXJpbmc6YXV0bztpbWFnZS1yZW5kZXJpbmc6YXV0bztzaGFwZS1yZW5kZXJpbmc6YXV0bzt0ZXh0LXJlbmRlcmluZzphdXRvO2VuYWJsZS1iYWNrZ3JvdW5kOmFjY3VtdWxhdGUiCiAgICAgICAgIGQ9Im0gMzA5LjU0ODkyLC03MTAuMzg4MjcgMTIyLjE5NjgzLDIxMS42NzUxMiAtNTYuMTU3MDYsMC41MjY4IC0zMi42MjM2LC01Ni44NjkyIC0zMi44NTY0NSw1Ni41NjUzIC0yNy45MDIzNywtMC4wMTEgLTE0LjI5MDg2LC0yNC42ODk2IDQ2LjgxMDQ3LC04MC40OTAxIC0zMy4yMjk0NiwtNTcuODI1NiB6IgogICAgICAgICBpZD0icGF0aDQyNjAtMCIKICAgICAgICAgaW5rc2NhcGU6Y29ubmVjdG9yLWN1cnZhdHVyZT0iMCIKICAgICAgICAgc29kaXBvZGk6bm9kZXR5cGVzPSJjY2NjY2NjY2NjIiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKDEyMCw0MDcuMzM5MTYsLTcxNi4wODM1NikiCiAgICAgICAgIGlkPSJ1c2U0MzU0LTUiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoNDI2MC0wIgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmU7c3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICAgIDx1c2UKICAgICAgICAgaGVpZ2h0PSIxMDAlIgogICAgICAgICB3aWR0aD0iMTAwJSIKICAgICAgICAgdHJhbnNmb3JtPSJyb3RhdGUoLTEyMCw0MDcuMjg4MjMsLTcxNS44Njk5NSkiCiAgICAgICAgIGlkPSJ1c2U0MzYyLTIiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoNDI2MC0wIgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmU7c3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICA8L2c+CiAgPC9nPgo8L3N2Zz4K";
              };

              nixos-wiki = {
                name = "NixOS Wiki";
                urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
                definedAliases = ["@nw"];
                icon = "data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhLS0gQ3JlYXRlZCB3aXRoIElua3NjYXBlIChodHRwOi8vd3d3Lmlua3NjYXBlLm9yZy8pIC0tPgoKPHN2ZwogICB3aWR0aD0iNTM1IgogICBoZWlnaHQ9IjUzNSIKICAgdmlld0JveD0iMCAwIDUwMS41NjI1MSA1MDEuNTYyNDkiCiAgIGlkPSJzdmcyIgogICB2ZXJzaW9uPSIxLjEiCiAgIGlua3NjYXBlOnZlcnNpb249IjEuMy4yICgwOTFlMjBlZjBmLCAyMDIzLTExLTI1KSIKICAgc29kaXBvZGk6ZG9jbmFtZT0ibml4LXNub3dmbGFrZS1jb2xvdXJzLnN2ZyIKICAgeG1sbnM6aW5rc2NhcGU9Imh0dHA6Ly93d3cuaW5rc2NhcGUub3JnL25hbWVzcGFjZXMvaW5rc2NhcGUiCiAgIHhtbG5zOnNvZGlwb2RpPSJodHRwOi8vc29kaXBvZGkuc291cmNlZm9yZ2UubmV0L0RURC9zb2RpcG9kaS0wLmR0ZCIKICAgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiCiAgIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6c3ZnPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIgogICB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIgogICB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iPgogIDxkZWZzCiAgICAgaWQ9ImRlZnM0Ij4KICAgIDxsaW5lYXJHcmFkaWVudAogICAgICAgaW5rc2NhcGU6Y29sbGVjdD0iYWx3YXlzIgogICAgICAgaWQ9ImxpbmVhckdyYWRpZW50NTU2MiI+CiAgICAgIDxzdG9wCiAgICAgICAgIHN0eWxlPSJzdG9wLWNvbG9yOiM2OTlhZDc7c3RvcC1vcGFjaXR5OjEiCiAgICAgICAgIG9mZnNldD0iMCIKICAgICAgICAgaWQ9InN0b3A1NTY0IiAvPgogICAgICA8c3RvcAogICAgICAgICBpZD0ic3RvcDU1NjYiCiAgICAgICAgIG9mZnNldD0iMC4yNDM0NTE5OCIKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzdlYjFkZDtzdG9wLW9wYWNpdHk6MSIgLz4KICAgICAgPHN0b3AKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzdlYmFlNDtzdG9wLW9wYWNpdHk6MSIKICAgICAgICAgb2Zmc2V0PSIxIgogICAgICAgICBpZD0ic3RvcDU1NjgiIC8+CiAgICA8L2xpbmVhckdyYWRpZW50PgogICAgPGxpbmVhckdyYWRpZW50CiAgICAgICBpbmtzY2FwZTpjb2xsZWN0PSJhbHdheXMiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ1MDUzIj4KICAgICAgPHN0b3AKICAgICAgICAgc3R5bGU9InN0b3AtY29sb3I6IzQxNWU5YTtzdG9wLW9wYWNpdHk6MSIKICAgICAgICAgb2Zmc2V0PSIwIgogICAgICAgICBpZD0ic3RvcDUwNTUiIC8+CiAgICAgIDxzdG9wCiAgICAgICAgIGlkPSJzdG9wNTA1NyIKICAgICAgICAgb2Zmc2V0PSIwLjIzMTY4NjQ0IgogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojNGE2YmFmO3N0b3Atb3BhY2l0eToxIiAvPgogICAgICA8c3RvcAogICAgICAgICBzdHlsZT0ic3RvcC1jb2xvcjojNTI3N2MzO3N0b3Atb3BhY2l0eToxIgogICAgICAgICBvZmZzZXQ9IjEiCiAgICAgICAgIGlkPSJzdG9wNTA1OSIgLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGlua3NjYXBlOmNvbGxlY3Q9ImFsd2F5cyIKICAgICAgIHhsaW5rOmhyZWY9IiNsaW5lYXJHcmFkaWVudDU1NjIiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ0MzI4IgogICAgICAgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBncmFkaWVudFRyYW5zZm9ybT0idHJhbnNsYXRlKDcwLjY1MDMzOSwtMTA1NS4xNTExKSIKICAgICAgIHgxPSIyMDAuNTk2NjgiCiAgICAgICB5MT0iMzUxLjQxMTE2IgogICAgICAgeDI9IjI5MC4wODcwMSIKICAgICAgIHkyPSI1MDYuMTg4MTQiIC8+CiAgICA8bGluZWFyR3JhZGllbnQKICAgICAgIGlua3NjYXBlOmNvbGxlY3Q9ImFsd2F5cyIKICAgICAgIHhsaW5rOmhyZWY9IiNsaW5lYXJHcmFkaWVudDUwNTMiCiAgICAgICBpZD0ibGluZWFyR3JhZGllbnQ0MzMwIgogICAgICAgZ3JhZGllbnRVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBncmFkaWVudFRyYW5zZm9ybT0idHJhbnNsYXRlKDg2NC42OTU4OSwtMTQ5MS4zNDA1KSIKICAgICAgIHgxPSItNTg0LjE5OTM0IgogICAgICAgeTE9Ijc4Mi4zMzU2MyIKICAgICAgIHgyPSItNDk2LjI5NzAzIgogICAgICAgeTI9IjkzNy43MTM5OSIgLz4KICA8L2RlZnM+CiAgPHNvZGlwb2RpOm5hbWVkdmlldwogICAgIGlkPSJiYXNlIgogICAgIHBhZ2Vjb2xvcj0iI2ZmZmZmZiIKICAgICBib3JkZXJjb2xvcj0iIzY2NjY2NiIKICAgICBib3JkZXJvcGFjaXR5PSIxLjAiCiAgICAgaW5rc2NhcGU6cGFnZW9wYWNpdHk9IjAuMCIKICAgICBpbmtzY2FwZTpwYWdlc2hhZG93PSIyIgogICAgIGlua3NjYXBlOnpvb209IjAuNzA5MDQzNjgiCiAgICAgaW5rc2NhcGU6Y3g9Ijk5LjQyOTY5OSIKICAgICBpbmtzY2FwZTpjeT0iMTk1LjMzMzUyIgogICAgIGlua3NjYXBlOmRvY3VtZW50LXVuaXRzPSJweCIKICAgICBpbmtzY2FwZTpjdXJyZW50LWxheWVyPSJsYXllcjMiCiAgICAgc2hvd2dyaWQ9ImZhbHNlIgogICAgIGlua3NjYXBlOndpbmRvdy13aWR0aD0iMTkyMCIKICAgICBpbmtzY2FwZTp3aW5kb3ctaGVpZ2h0PSIxMDUwIgogICAgIGlua3NjYXBlOndpbmRvdy14PSIxOTIwIgogICAgIGlua3NjYXBlOndpbmRvdy15PSIzMCIKICAgICBpbmtzY2FwZTp3aW5kb3ctbWF4aW1pemVkPSIxIgogICAgIGlua3NjYXBlOnNuYXAtZ2xvYmFsPSJ0cnVlIgogICAgIGZpdC1tYXJnaW4tdG9wPSIwIgogICAgIGZpdC1tYXJnaW4tbGVmdD0iMCIKICAgICBmaXQtbWFyZ2luLXJpZ2h0PSIwIgogICAgIGZpdC1tYXJnaW4tYm90dG9tPSIwIgogICAgIGlua3NjYXBlOnNob3dwYWdlc2hhZG93PSIyIgogICAgIGlua3NjYXBlOnBhZ2VjaGVja2VyYm9hcmQ9IjAiCiAgICAgaW5rc2NhcGU6ZGVza2NvbG9yPSIjZDFkMWQxIiAvPgogIDxtZXRhZGF0YQogICAgIGlkPSJtZXRhZGF0YTciPgogICAgPHJkZjpSREY+CiAgICAgIDxjYzpXb3JrCiAgICAgICAgIHJkZjphYm91dD0iIj4KICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3N2Zyt4bWw8L2RjOmZvcm1hdD4KICAgICAgICA8ZGM6dHlwZQogICAgICAgICAgIHJkZjpyZXNvdXJjZT0iaHR0cDovL3B1cmwub3JnL2RjL2RjbWl0eXBlL1N0aWxsSW1hZ2UiIC8+CiAgICAgIDwvY2M6V29yaz4KICAgIDwvcmRmOlJERj4KICA8L21ldGFkYXRhPgogIDxnCiAgICAgaW5rc2NhcGU6Z3JvdXBtb2RlPSJsYXllciIKICAgICBpZD0ibGF5ZXIzIgogICAgIGlua3NjYXBlOmxhYmVsPSJncmFkaWVudC1sb2dvIgogICAgIHN0eWxlPSJkaXNwbGF5OmlubGluZTtvcGFjaXR5OjEiCiAgICAgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTE1Ni40MTEyMSw5MzMuMzA2ODUpIj4KICAgIDxnCiAgICAgICBpZD0iZzIiCiAgICAgICB0cmFuc2Zvcm09Im1hdHJpeCgwLjk5OTk0MDU5LDAsMCwwLjk5OTk0MDU5LC0wLjA2MzIxNzk4LDMzLjE4ODM3NykiCiAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjEuMDAwMDYiPgogICAgICA8cGF0aAogICAgICAgICBzb2RpcG9kaTpub2RldHlwZXM9ImNjY2NjY2NjY2MiCiAgICAgICAgIGlua3NjYXBlOmNvbm5lY3Rvci1jdXJ2YXR1cmU9IjAiCiAgICAgICAgIGlkPSJwYXRoMzMzNi02IgogICAgICAgICBkPSJtIDMwOS41NDg5MiwtNzEwLjM4ODI3IDEyMi4xOTY4MywyMTEuNjc1MTIgLTU2LjE1NzA2LDAuNTI2OCAtMzIuNjIzNiwtNTYuODY5MiAtMzIuODU2NDUsNTYuNTY1MyAtMjcuOTAyMzcsLTAuMDExIC0xNC4yOTA4NiwtMjQuNjg5NiA0Ni44MTA0NywtODAuNDkwMSAtMzMuMjI5NDYsLTU3LjgyNTcgeiIKICAgICAgICAgc3R5bGU9Im9wYWNpdHk6MTtmaWxsOnVybCgjbGluZWFyR3JhZGllbnQ0MzI4KTtmaWxsLW9wYWNpdHk6MTtmaWxsLXJ1bGU6ZXZlbm9kZDtzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6My4wMDAxODtzdHJva2UtbGluZWNhcDpidXR0O3N0cm9rZS1saW5lam9pbjpyb3VuZDtzdHJva2UtbWl0ZXJsaW1pdDo0O3N0cm9rZS1kYXNoYXJyYXk6bm9uZTtzdHJva2Utb3BhY2l0eToxIiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKDYwLDQwNy4xMTE1NSwtNzE1Ljc4NzI0KSIKICAgICAgICAgaWQ9InVzZTM0MzktNiIKICAgICAgICAgaW5rc2NhcGU6dHJhbnNmb3JtLWNlbnRlci15PSIxNTEuNTkwODIiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteD0iMTI0LjQzMDQ1IgogICAgICAgICB4bGluazpocmVmPSIjcGF0aDMzMzYtNiIKICAgICAgICAgeT0iMCIKICAgICAgICAgeD0iMCIKICAgICAgICAgc3R5bGU9InN0cm9rZS13aWR0aDoxLjAwMDA2IiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKC02MCw0MDcuMzExNzcsLTcxNS43MDAxNikiCiAgICAgICAgIGlkPSJ1c2UzNDQ1LTAiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteT0iNzUuNTczOTU4IgogICAgICAgICBpbmtzY2FwZTp0cmFuc2Zvcm0tY2VudGVyLXg9Ii0xNjguMjA2NTEiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoMzMzNi02IgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICAgIDx1c2UKICAgICAgICAgaGVpZ2h0PSIxMDAlIgogICAgICAgICB3aWR0aD0iMTAwJSIKICAgICAgICAgdHJhbnNmb3JtPSJyb3RhdGUoMTgwLDQwNy40MTg2OCwtNzE1Ljc1NjUpIgogICAgICAgICBpZD0idXNlMzQ0OS01IgogICAgICAgICBpbmtzY2FwZTp0cmFuc2Zvcm0tY2VudGVyLXk9Ii0xMzkuOTQ1OTIiCiAgICAgICAgIGlua3NjYXBlOnRyYW5zZm9ybS1jZW50ZXIteD0iNTkuNjY5NzA1IgogICAgICAgICB4bGluazpocmVmPSIjcGF0aDMzMzYtNiIKICAgICAgICAgeT0iMCIKICAgICAgICAgeD0iMCIKICAgICAgICAgc3R5bGU9InN0cm9rZS13aWR0aDoxLjAwMDA2IiAvPgogICAgICA8cGF0aAogICAgICAgICBzdHlsZT0iY29sb3I6IzAwMDAwMDtjbGlwLXJ1bGU6bm9uemVybztkaXNwbGF5OmlubGluZTtvdmVyZmxvdzp2aXNpYmxlO3Zpc2liaWxpdHk6dmlzaWJsZTtvcGFjaXR5OjE7aXNvbGF0aW9uOmF1dG87bWl4LWJsZW5kLW1vZGU6bm9ybWFsO2NvbG9yLWludGVycG9sYXRpb246c1JHQjtjb2xvci1pbnRlcnBvbGF0aW9uLWZpbHRlcnM6bGluZWFyUkdCO3NvbGlkLWNvbG9yOiMwMDAwMDA7c29saWQtb3BhY2l0eToxO2ZpbGw6dXJsKCNsaW5lYXJHcmFkaWVudDQzMzApO2ZpbGwtb3BhY2l0eToxO2ZpbGwtcnVsZTpldmVub2RkO3N0cm9rZTpub25lO3N0cm9rZS13aWR0aDozLjAwMDE4O3N0cm9rZS1saW5lY2FwOmJ1dHQ7c3Ryb2tlLWxpbmVqb2luOnJvdW5kO3N0cm9rZS1taXRlcmxpbWl0OjQ7c3Ryb2tlLWRhc2hhcnJheTpub25lO3N0cm9rZS1kYXNob2Zmc2V0OjA7c3Ryb2tlLW9wYWNpdHk6MTtjb2xvci1yZW5kZXJpbmc6YXV0bztpbWFnZS1yZW5kZXJpbmc6YXV0bztzaGFwZS1yZW5kZXJpbmc6YXV0bzt0ZXh0LXJlbmRlcmluZzphdXRvO2VuYWJsZS1iYWNrZ3JvdW5kOmFjY3VtdWxhdGUiCiAgICAgICAgIGQ9Im0gMzA5LjU0ODkyLC03MTAuMzg4MjcgMTIyLjE5NjgzLDIxMS42NzUxMiAtNTYuMTU3MDYsMC41MjY4IC0zMi42MjM2LC01Ni44NjkyIC0zMi44NTY0NSw1Ni41NjUzIC0yNy45MDIzNywtMC4wMTEgLTE0LjI5MDg2LC0yNC42ODk2IDQ2LjgxMDQ3LC04MC40OTAxIC0zMy4yMjk0NiwtNTcuODI1NiB6IgogICAgICAgICBpZD0icGF0aDQyNjAtMCIKICAgICAgICAgaW5rc2NhcGU6Y29ubmVjdG9yLWN1cnZhdHVyZT0iMCIKICAgICAgICAgc29kaXBvZGk6bm9kZXR5cGVzPSJjY2NjY2NjY2NjIiAvPgogICAgICA8dXNlCiAgICAgICAgIGhlaWdodD0iMTAwJSIKICAgICAgICAgd2lkdGg9IjEwMCUiCiAgICAgICAgIHRyYW5zZm9ybT0icm90YXRlKDEyMCw0MDcuMzM5MTYsLTcxNi4wODM1NikiCiAgICAgICAgIGlkPSJ1c2U0MzU0LTUiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoNDI2MC0wIgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmU7c3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICAgIDx1c2UKICAgICAgICAgaGVpZ2h0PSIxMDAlIgogICAgICAgICB3aWR0aD0iMTAwJSIKICAgICAgICAgdHJhbnNmb3JtPSJyb3RhdGUoLTEyMCw0MDcuMjg4MjMsLTcxNS44Njk5NSkiCiAgICAgICAgIGlkPSJ1c2U0MzYyLTIiCiAgICAgICAgIHhsaW5rOmhyZWY9IiNwYXRoNDI2MC0wIgogICAgICAgICB5PSIwIgogICAgICAgICB4PSIwIgogICAgICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmU7c3Ryb2tlLXdpZHRoOjEuMDAwMDYiIC8+CiAgICA8L2c+CiAgPC9nPgo8L3N2Zz4K";
              };
            };
          };
        };
      };
    };
  };
}
