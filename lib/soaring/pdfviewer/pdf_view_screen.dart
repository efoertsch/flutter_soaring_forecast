import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// https://pub.dev/packages/native_pdf_view/example
class PdfViewScreen extends StatefulWidget {
  String fileName;

  PdfViewScreen({Key? key, required String this.fileName}) : super(key: key);

  @override
  _PdfViewScreenState createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;

  bool _searchBoolean = false;

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    super.initState();
  }

  @override
  void dispose() {
    //_pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _getAppBar(),
        body: _getBody(),
      ),
    );
  }

  // using exmaple from https://enoiu.com/en/app-develop/flutter-search-function/#
  // for search
  AppBar _getAppBar() {
    return AppBar(
      title: !_searchBoolean ? const Text('1800WxBrief') : _searchTextField(),
       actions: !_searchBoolean ? <Widget>[
        IconButton(
          icon: const Icon(
            Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _searchBoolean = true;
            });
          },

        ) ] :[
        Visibility(
          visible: _searchResult.hasResult,
          child: IconButton(
            icon: const Icon(
              Icons.clear,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _searchBoolean = false;
                _searchResult.clear();
              });
            },
          ),
        ),
        Visibility(
          visible: _searchResult.hasResult,
          child: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white,
            ),
            onPressed: () {
              _searchResult.previousInstance();
            },
          ),
        ),
        Visibility(
          visible: _searchResult.hasResult,
          child: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            onPressed: () {
              _searchResult.nextInstance();
            },
          ),
        ),
      ]
    );
  }

  Widget _searchTextField() {
    //add
    return TextField(
      onChanged: (String searchString) {
        //add
        setState(() {
          _searchResult = _pdfViewerController.searchText(searchString,
              searchOption: TextSearchOption.caseSensitive);
          if (kIsWeb) {
            setState(() {});
          } else {
            _searchResult.addListener(() {
              if (_searchResult.hasResult) {
                setState(() {});
              }
            });
          }
        });
      },
      autofocus: true,
      //Display the keyboard when TextField is displayed
      cursorColor: Colors.white,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      textInputAction: TextInputAction.search,
      //Specify the action button on the keyboard
      decoration: InputDecoration(
        //Style of TextField
        enabledBorder: UnderlineInputBorder(
            //Default TextField border
            borderSide: BorderSide(color: Colors.white)),
        focusedBorder: UnderlineInputBorder(
            //Borders when a TextField is in focus
            borderSide: BorderSide(color: Colors.white)),
        hintText: 'Search', //Text that is displayed when nothing is entered.
        hintStyle: TextStyle(
          //Style of hintText
          color: Colors.white60,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _getBody() {
    return SfPdfViewer.file(
      File(widget.fileName),
      controller: _pdfViewerController,
      currentSearchTextHighlightColor: Colors.yellow.withOpacity(0.6),
      otherSearchTextHighlightColor: Colors.yellow.withOpacity(0.3),
    );
  }
}
