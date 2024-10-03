import 'package:flutter/material.dart';

class InAppAlertDialog extends StatelessWidget {
  const InAppAlertDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate this App'),
      content: Text('Please leave a rating for our app!'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Implement logic to handle the user's rating.
            // You can use the response to perform further actions if needed.
            // For simplicity, we'll just print the user's decision.
            print('User clicked SUBMIT');
          },
          child: Text('SUBMIT'),
        ),
      ],
    );
  }
}
