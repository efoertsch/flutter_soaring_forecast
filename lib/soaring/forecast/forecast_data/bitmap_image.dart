import 'package:flutter/material.dart';

class BitmapImage {
  final String imageUrl;
  bool errorOnLoad = false;
  Image _image;

  BitmapImage(this.imageUrl);

  bool isImageLoaded() {
    return _image != null;
  }

  void setErrorOnLoad(bool errorOnLoad) {
    errorOnLoad = errorOnLoad;
    _image = null;
  }

  bool isErrorOnLoad() {
    return errorOnLoad;
  }

  Image get image {
    return _image;
  }

  void setImage(Image image) {
    _image = image;
    errorOnLoad = false;
  }
}
