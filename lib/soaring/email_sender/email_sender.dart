import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';

import '../app/common_widgets.dart';
import '../app/constants.dart' show EmailError;

class EmailDetails {
  final String title;
  final String subject;
  final String recipients;
  final String body;

  EmailDetails({required this.title, required this.subject, required this.recipients, this.body = ''});
}

class EmailSender extends StatefulWidget {
  const EmailSender({
    Key? key,
    required this.title,
    required this.subject,
    required this.recipients,
  }) : super(key: key);
  final String title;
  final String subject;
  final String recipients;

  @override
  _EmailSenderState createState() => _EmailSenderState();
}

class _EmailSenderState extends State<EmailSender> {
  List<String> attachments = [];
  bool isHTML = false;
  late final TextEditingController _recipientController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.subject);
    _recipientController = TextEditingController(text: widget.recipients);
    _bodyController = TextEditingController(text: ' ');
  }

  Future<void> send() async {
    final Email email = Email(
      body: _bodyController.text,
      subject: _subjectController.text,
      recipients: [_recipientController.text],
      attachmentPaths: attachments,
      isHTML: isHTML,
    );

    String platformResponse;

    if (!mounted) return;

    try {
      await FlutterEmailSender.send(email);
      platformResponse = 'success';
    } catch (error) {
      print(error);
      platformResponse = error.toString();
      if (!mounted) return;
      CommonWidgets.showErrorDialog(context, EmailError.send_email_error,
          EmailError.email_error_text + '\n' + platformResponse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email'),
        actions: <Widget>[
          IconButton(
            onPressed: send,
            icon: Icon(Icons.send),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _recipientController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Recipient',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Subject',
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                      labelText: 'Body', border: OutlineInputBorder()),
                ),
              ),
            ),
            CheckboxListTile(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
              title: Text('HTML'),
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    isHTML = value;
                  });
                }
              },
              value: isHTML,
            ),
            // Padding(
            //   padding: EdgeInsets.all(8.0),
            //   child: Column(
            //     children: <Widget>[
            //       for (var i = 0; i < attachments.length; i++)
            //         Row(
            //           children: <Widget>[
            //             Expanded(
            //               child: Text(
            //                 attachments[i],
            //                 softWrap: false,
            //                 overflow: TextOverflow.fade,
            //               ),
            //             ),
            //             IconButton(
            //               icon: Icon(Icons.remove_circle),
            //               onPressed: () => {_removeAttachment(i)},
            //             )
            //           ],
            //         ),
            //       Align(
            //         alignment: Alignment.centerRight,
            //         child: IconButton(
            //           icon: Icon(Icons.attach_file),
            //           onPressed: _openImagePicker,
            //         ),
            //       ),
            //       TextButton(
            //         child: Text('Attach file in app documents directory'),
            //         onPressed: () => _attachFileFromAppDocumentsDirectoy(),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // void _openImagePicker() async {
  //   final picker = ImagePicker();
  //   final pick = await picker.pickImage(source: ImageSource.gallery);
  //   if (pick != null) {
  //     setState(() {
  //       attachments.add(pick.path);
  //     });
  //   }
  // }

  void _removeAttachment(int index) {
    setState(() {
      attachments.removeAt(index);
    });
  }

  Future<void> _attachFileFromAppDocumentsDirectoy() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final filePath = appDocumentDir.path + '/file.txt';
      final file = File(filePath);
      await file.writeAsString('Text file in app directory');

      setState(() {
        attachments.add(filePath);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create file in applicion directory'),
        ),
      );
    }
  }
}
