import 'package:flutter/material.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart';
import 'package:pdfx/pdfx.dart';

// https://pub.dev/packages/native_pdf_view/example
class PdfViewScreen extends StatefulWidget {
  String fileName;

  PdfViewScreen({Key? key, required String this.fileName}) : super(key: key);

  @override
  _PdfViewScreenState createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  static const int _initialPage = 1;
  int _actualPageNumber = _initialPage, _allPagesCount = 0;
  late PdfControllerPinch _pdfController;

  @override
  void initState() {
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.fileName),
      initialPage: _initialPage,
    );
    super.initState();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(),
      body: _getBody(),
    );
  }

  AppBar _getAppBar() {
    return AppBar(
      title: const Text(WxBriefLiterals.ONE800WXBRIEF),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.navigate_before),
          onPressed: () {
            _pdfController.previousPage(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
        Container(
          alignment: Alignment.center,
          child: Text(
            '$_actualPageNumber/$_allPagesCount',
            style: const TextStyle(fontSize: 22),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.navigate_next),
          onPressed: () {
            _pdfController.nextPage(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 100),
            );
          },
        ),
      ],
    );
  }

  _getBody() {
    return PdfViewPinch(
      documentLoader: const Center(child: CircularProgressIndicator()),
      pageLoader: const Center(child: CircularProgressIndicator()),
      controller: _pdfController,
      onDocumentLoaded: (document) {
        setState(() {
          _allPagesCount = document.pagesCount;
        });
      },
      onPageChanged: (page) {
        setState(() {
          _actualPageNumber = page;
        });
      },
    );
  }
}
