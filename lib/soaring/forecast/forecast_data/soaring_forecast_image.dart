import 'bitmap_image.dart';

/// This will hold details for one type of forecast image, whether body, side, header, footer
class SoaringForecastImage extends BitmapImage {
  late String
      forecastTime; //1300 or might be old 1300 if RASP regenerating bitmaps

  SoaringForecastImage(String imageUrl, String forecastTime) : super(imageUrl) {
    this.forecastTime = forecastTime;
  }
}
