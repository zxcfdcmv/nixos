# modules/nixos/edge.nix
{ config, lib, pkgs, ... }:
{
  environment.etc."opt/edge/policies/managed/policies.json".text = builtins.toJSON {

    DefaultSearchProviderEnabled = true;
    DefaultSearchProviderName = "Bing";
    DefaultSearchProviderKeyword = "b";
    DefaultSearchProviderSearchURL = "https://cn.bing.com/search?q={searchTerms}";

    ExtensionInstallForcelist = [
      "jbkfoedgocfjonbeabaeeioedeocecga;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
      "amnoiceffbpcgofieenmbgicholldbno;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
    ];

    NewTabPageLocation = "about:blank";
    NewTabPageContentEnabled = false;
    NewTabPageQuickLinksEnabled = false;
    NewTabPageAllowedBackgroundTypes = 3;
    NewTabPageAppLauncherEnabled = false;
    NewTabPageBingChatEnabled = false;
    NewTabPageHideDefaultTopSites = true;

    HubsSidebarEnabled = false;
    CopilotPageContext = false;
    CopilotAddressBarSuggestionsEnabled = false;
    GenAILocalFoundationalModelSettings = 0;
    Microsoft365CopilotChatIconEnabled = false;

    EdgeShoppingAssistantEnabled = false;
    ShowMicrosoftRewards = false;
    ShowRecommendationsEnabled = false;
    PromotionalTabsEnabled = false;
    QuickSearchShowMiniMenu = false;
    VisualSearchEnabled = false;

    EdgeCollectionsEnabled = false;
    EdgeWorkspacesEnabled = false;
    WhatsNewPageForEntraProfilesEnabled = false;
    MicrosoftEdgeInsiderPromotionEnabled = false;
    GuidedSwitchEnabled = false;

    PersonalizationReportingEnabled = false;
    PersonalizeTopSitesInCustomizeSidebarEnabled = false;
    EdgeAssetDeliveryServiceEnabled = false;

    PasswordManagerEnabled = false;
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;
    AutofillMembershipsEnabled = false;
    PaymentMethodQueryEnabled = false;

    HideFirstRunExperience = true;
    AutoImportAtFirstRun = 4;
    BrowserGuestModeEnabled = false;

    AllowGamesMenu = false;
    PictureInPictureOverlayEnabled = false;
    QRCodeGeneratorEnabled = false;
    ReadAloudEnabled = false;
    RemoteDebuggingAllowed = false;
    ShowAcrobatSubscriptionButton = false;
    PinBrowserEssentialsToolbarButton = false;
    UserFeedbackAllowed = false;

    AlternateErrorPagesEnabled = false;
    ResolveNavigationErrorsUseWebService = false;
    NetworkPredictionOptions = 2;
    QuicAllowed = false;
    SearchSuggestEnabled = false;
    DefaultSearchProviderContextMenuAccessAllowed = true;

    ConfigureDoNotTrack = true;
    WebRtcLocalhostIpHandling = "disable_non_proxied_udp";
    SitePerProcess = true;

    HighEfficiencyModeEnabled = 1;
    SleepingTabsEnabled = true;
    SleepingTabsTimeout = 300;

    VerticalTabsAllowed = true;
    FavoritesBarEnabled = "on_new_tab";
    ShowHomeButton = false;
  };
}
