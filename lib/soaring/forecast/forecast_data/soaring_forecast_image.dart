import 'bitmap_image.dart';

/// This will hold details for one type of forecast image, whether body, side, header, footer
class SoaringForecastImage extends BitmapImage {
  String
      url; // eg. "/NewEngland/2019-12-19/gfs/wstar_bsratio.1500local.d2.body.png"
  String forecastTime; //1300 or might be old 1300 if RASP regenerating bitmaps

  SoaringForecastImage(String imageUrl, String forecastTime) : super(imageUrl) {
    this.forecastTime = forecastTime;
  }
}
