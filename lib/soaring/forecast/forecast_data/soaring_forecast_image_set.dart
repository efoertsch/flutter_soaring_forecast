import 'package:flutter_soaring_forecast/soaring/forecast/forecast_data/soaring_forecast_image.dart';

/// Hold the set of forecast images for the forecast time period
class SoaringForecastImageSet {
  String localTime;
  SoaringForecastImage bodyImage;
  SoaringForecastImage headerImage;
  SoaringForecastImage sideImage;
  SoaringForecastImage footerImage;

  SoaringForecastImageSet(
      {this.localTime,
      this.bodyImage,
      this.headerImage,
      this.sideImage,
      this.footerImage});
}
