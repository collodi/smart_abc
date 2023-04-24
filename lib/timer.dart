import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:numberpicker/numberpicker.dart';

import 'firebase.dart';

enum TimerDisplayState {
  clock,
  timer,
}

const states = [
  DropdownMenuItem(value: TimerDisplayState.clock, child: Text('Clock')),
  DropdownMenuItem(value: TimerDisplayState.timer, child: Text('Timer')),
];

class TimerControlView extends StatefulWidget {
  const TimerControlView({super.key});

  @override
  State<TimerControlView> createState() => _TimerControlViewState();
}

class _TimerControlViewState extends State<TimerControlView> {
  TimerDisplayState? state;

  Widget displayState() {
    switch (state) {
      case null:
        return const Text(
          'Select a timer mode.',
          style: TextStyle(fontSize: 20),
        );
      case TimerDisplayState.clock:
        return const ClockState();
      case TimerDisplayState.timer:
        return const TimerState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Display Mode"),
        DropdownButton<TimerDisplayState>(
          items: states,
          value: state,
          isExpanded: true,
          style: const TextStyle(fontSize: 20, color: Colors.black),
          onChanged: (val) {
            setState(() {
              state = val;
            });
          },
        ),
        const Padding(padding: EdgeInsets.all(10)),
        displayState(),
      ],
    );
  }
}

String getHexString(int num, int nBytes) {
  String hexstr = BigInt.from(num)
      .toUnsigned(8 * nBytes)
      .toRadixString(16)
      .padLeft(2 * nBytes, '0');

  String res = '';
  for (int i = 0; i < hexstr.length; i += 2) {
    res = hexstr.substring(i, i + 2) + res;
  }

  return res;
}

class ClockState extends StatelessWidget {
  const ClockState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            int offset = DateTime.now().timeZoneOffset.inSeconds;
            String stateString = 'CLOCK${getHexString(offset, 4)}';
            db.ref('/bigtimer/state').set(stateString).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("clock successfully shown")));
            }).catchError((e) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
            });
          },
          child: const Text('Show Clock'),
        )
      ],
    );
  }
}

class TimerState extends StatefulWidget {
  const TimerState({super.key});

  @override
  State<TimerState> createState() => _TimerStateState();
}

class _TimerStateState extends State<TimerState> {
  late DateTime start;
  int duration = 4 * 60;
  int transition = 5;
  String? error;

  @override
  void initState() {
    super.initState();

    start = DateTime.now();
    start = start.add(const Duration(minutes: 1));
    start = start.subtract(Duration(seconds: start.second));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Today at ${start.hour}:${start.minute.toString().padLeft(2, "0")}',
          style: const TextStyle(fontSize: 20),
        ),
        ElevatedButton(
          onPressed: () {
            DatePicker.showTimePicker(
              context,
              showSecondsColumn: false,
              currentTime: start,
              onConfirm: (time) {
                setState(() {
                  start = time.subtract(Duration(seconds: time.second));
                });
              },
            );
          },
          child: const Text("Pick Start Time"),
        ),
        const Padding(padding: EdgeInsets.all(10)),
        const Text(
          "Duration",
          style: TextStyle(fontSize: 20),
        ),
        DurationPicker(
          initialValue: duration,
          textStyle: const TextStyle(fontSize: 20),
          onChanged: (n) {
            duration = n;
          },
        ),
        const Padding(padding: EdgeInsets.all(10)),
        const Text(
          "Transition",
          style: TextStyle(fontSize: 20),
        ),
        DurationPicker(
          initialValue: transition,
          textStyle: const TextStyle(fontSize: 20),
          onChanged: (n) {
            transition = n;
          },
        ),
        const Padding(padding: EdgeInsets.all(10)),
        ElevatedButton(
          onPressed: () {
            int startEpoch = start.millisecondsSinceEpoch ~/ 1000;
            String hexbytes = getHexString(startEpoch, 8) +
                getHexString(duration, 8) +
                getHexString(transition, 8);
            String stateString = 'TIMER$hexbytes';

            db.ref('/bigtimer/state').set(stateString).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("timer successfully started")));
            }).catchError((e) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
            });
          },
          child: const Text('Start Timer'),
        )
      ],
    );
  }
}

class DurationPicker extends StatefulWidget {
  final void Function(int) onChanged;
  final TextStyle? textStyle;
  final int initialValue;

  const DurationPicker(
      {super.key,
      required this.onChanged,
      this.textStyle,
      this.initialValue = 0});

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int min, sec;

  @override
  void initState() {
    super.initState();

    min = widget.initialValue ~/ 60;
    sec = widget.initialValue % 60;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NumberPicker(
          minValue: 0,
          maxValue: 100,
          itemCount: 1,
          itemWidth: 60,
          value: min,
          onChanged: (n) {
            setState(() {
              min = n;
            });

            widget.onChanged(min * 60 + sec);
          },
        ),
        Text(
          "Minutes",
          style: widget.textStyle,
        ),
        NumberPicker(
          minValue: 0,
          maxValue: 59,
          itemCount: 1,
          itemWidth: 60,
          value: sec,
          onChanged: (n) {
            setState(() {
              sec = n;
            });

            widget.onChanged(min * 60 + sec);
          },
        ),
        Text(
          "Seconds",
          style: widget.textStyle,
        ),
      ],
    );
  }
}
