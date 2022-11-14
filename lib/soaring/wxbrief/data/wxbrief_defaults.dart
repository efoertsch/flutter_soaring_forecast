class WxBriefDefaults {
  final String aircraftRegistration;
  final String wxBriefAccountName;
  final String routeWidthNM;
  final String windsAloftNM;

  WxBriefDefaults(
      {required this.aircraftRegistration,
      required this.wxBriefAccountName,
      this.routeWidthNM = "",
      this.windsAloftNM = ""});
}
