import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void showAlert(BuildContext context, String text) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        content: Text(text, style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK', style: TextStyle(color: Colors.black)),
          ),
        ],
      );
    },
  );
}

void httpErrorHandle({
  required http.Response response,
  required BuildContext context,
  required VoidCallback onSuccess,
}) {
  switch (response.statusCode) {
    case 200:
      onSuccess();
      break;
    case 400:
      showAlert(context, jsonDecode(response.body)['msg']);
      break;
    case 500:
      showAlert(context, jsonDecode(response.body)['error']);
      break;
    default:
      showAlert(context, response.body);
  }
}