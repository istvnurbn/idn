{
  den.aspects.darwin-privacy = {
    darwin.system.defaults.CustomSystemPreferences = {
      # Disable personalized advertisements and identifier tracking.
      "com.apple.AdLib" = {
        "allowIdentifierForAdvertising" = false;
        "allowApplePersonalizedAdvertising" = false;
        "forceLimitAdTracking" = true;
      };

      # Disable Microsoft Office telemetry
      "com.microsoft.office" = {"DiagnosticDataTypePreference" = "ZeroDiagnosticData";};

      # Disable online spell correction
      NSGlobalDomain = {
        WebAutomaticSpellingCorrectionEnabled = false;
      };
    };
  };
}
