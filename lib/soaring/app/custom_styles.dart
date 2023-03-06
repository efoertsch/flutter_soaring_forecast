import 'package:flutter/material.dart';

class CustomStyle {
  static TextStyle bold18(BuildContext context) {
    return Theme.of(context)
        .textTheme
        .bodyText1!
        .copyWith(fontSize: 18.0, fontWeight: FontWeight.bold);
  }
}

const textStyleBoldBlackFontSize24 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 24);

const textStyleBoldBlackFontSize20 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20);

const textStyleBlackFontSize20 = TextStyle(color: Colors.black, fontSize: 20);

const textStyleBlackFontSize18 = TextStyle(color: Colors.black, fontSize: 18);

const textStyleBlackFontSize24 = TextStyle(color: Colors.black, fontSize: 24);

const textStyleBoldBlackFontSize18 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18);

const textStyleBoldBlackFontSize16 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16);

const textStyleBlackFontSize16 = TextStyle(color: Colors.black, fontSize: 16);

const textStyleBoldBlackFontSize14 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14);

const textStyleBlackFontSize14 = TextStyle(color: Colors.black, fontSize: 14);

const textStyleBoldBlack87FontSize15 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15);

const textStyleBlack87FontSize15 =
    TextStyle(color: Colors.black87, fontSize: 15);

const textStyleBoldBlack87FontSize14 =
    TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14);

const textStyleBlack87FontSize14 =
    TextStyle(color: Colors.black87, fontSize: 14);

const textStyleWhiteFontSize12 = TextStyle(color: Colors.white, fontSize: 12);
const textStyleBlackFontSize12 = TextStyle(color: Colors.black, fontSize: 12);

const textStyleWhiteFontSize13 = TextStyle(color: Colors.white, fontSize: 13);
const textStyleBlackFontSize13 = TextStyle(color: Colors.black, fontSize: 13);
