import 'dart:io';

import 'package:email_launcher/email_launcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/common_widgets.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    show FEEDBACK_EMAIL_ADDRESS, Feedback;

mixin AppFeedback {
  void sendFeedback({
    required BuildContext context,
  }) {
    final TextEditingController controller = TextEditingController();

    CommonWidgets.displayTextInputDialog(
        context: context,
        title: Feedback.FEEDBACK_TITLE,
        inputHintText: Feedback.FEEDBACK_HINT,
        textEditingController: controller,
        button1Text: Feedback.FEEDBACK_CANCEL,
        button1Function: () {
          Navigator.pop(context);
        },
        button2Text: (Feedback.FEEDBACK_SUBMIT),
        button2Function: () async {
          if (controller.text.isNotEmpty) {
            await sendEmail(context: context, feedback: controller.text ?? "");
            Navigator.pop(context);
          }
        });
  }

  Future<void> sendEmail(
      {required BuildContext context, required String feedback}) async {
    if (feedback.isNotEmpty) {
      debugPrint("Send email");
      Email email = Email(
          //to: ['flightservice@soaringforecast.org'],
          to: [FEEDBACK_EMAIL_ADDRESS],
          subject: Feedback.FEEDBACK_TITLE + " - " + Platform.operatingSystem,
          body: feedback);
      await EmailLauncher.launch(email);
    }
  }
}
