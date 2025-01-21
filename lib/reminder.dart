import 'package:flutter/material.dart';

import '../colors.dart';


class Reminder extends StatefulWidget {
  const Reminder({super.key});

  @override
  State<Reminder> createState() => _ReminderState();
}

class _ReminderState extends State<Reminder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        title: Text("Reminder Transaction" , style: TextStyle(color: Colors.white),),
      ),
    );
  }
}
