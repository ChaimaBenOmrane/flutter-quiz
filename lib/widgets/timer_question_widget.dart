// widgets/timer_question_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';

class TimerQuestionWidget extends StatefulWidget {
  final int durationSeconds;
  final Function onTimeOut;

  TimerQuestionWidget({required this.durationSeconds, required this.onTimeOut});

  @override
  _TimerQuestionWidgetState createState() => _TimerQuestionWidgetState();
}

class _TimerQuestionWidgetState extends State<TimerQuestionWidget> {
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        widget.onTimeOut();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Temps restant: $_remainingSeconds s',
      style: TextStyle(fontSize: 20, color: Colors.red),
    );
  }
}
