import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void openPdfInNewTab(Uint8List pdfBytes) {
  // Create a Blob from the PDF bytes
  final blob = web.Blob(
    [pdfBytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );

  // Generate an object URL and open it in a new tab
  final url = web.URL.createObjectURL(blob);
  web.window.open(url, '_blank');
}
