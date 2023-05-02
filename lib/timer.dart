import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:sprintf/sprintf.dart';

import 'firebase.dart';

enum TimerDisplayState {
  clock,
  timer,
  versus,
}

const states = [
  DropdownMenuItem(value: TimerDisplayState.clock, child: Text('Clock')),
  DropdownMenuItem(value: TimerDisplayState.timer, child: Text('Timer')),
  DropdownMenuItem(value: TimerDisplayState.versus, child: Text('Versus')),
];

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

String colorToHexString(Color color, {int repeat = 1}) {
  String s = getHexString(color.red, 1) +
      getHexString(color.green, 1) +
      getHexString(color.blue, 1);

  return s * repeat;
}

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
      case TimerDisplayState.versus:
        return const VersusState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder(
          stream: db.ref('/bigtimer').onValue,
          builder: (context, event) {
            if (!event.hasData) {
              return const Text("Timer hasn't been used in a while.");
            }

            final data = event.data!.snapshot;
            final lastUsedTime = DateTime.fromMillisecondsSinceEpoch(
                data.child('last_used').value as int);
            final lastUsedName = data.child('last_used_name').value as String;

            String lastUsedTimeString = lastUsedTime.toString();
            lastUsedTimeString =
                lastUsedTimeString.substring(0, lastUsedTimeString.length - 7);
            return Text(
              'Last used at $lastUsedTimeString by $lastUsedName',
            );
          },
        ),
        const Padding(padding: EdgeInsets.all(20)),
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
        const Padding(padding: EdgeInsets.all(20)),
        displayState(),
      ],
    );
  }
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

            Map<String, Object?> updates = {};
            updates['bigtimer/state'] = stateString;
            updates['bigtimer/last_used'] = ServerValue.timestamp;
            updates['bigtimer/last_used_name'] =
                auth.currentUser?.displayName ?? 'Unknown user';

            db.ref().update(updates).then((_) {
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
          'Start today at ${start.hour}:${start.minute.toString().padLeft(2, "0")}',
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

            Map<String, Object?> updates = {};
            updates['bigtimer/state'] = stateString;
            updates['bigtimer/last_used'] = ServerValue.timestamp;
            updates['bigtimer/last_used_name'] =
                auth.currentUser?.displayName ?? 'Unknown user';

            db.ref().update(updates).then((_) {
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

class VersusState extends StatefulWidget {
  const VersusState({super.key});

  @override
  State<VersusState> createState() => _VersusStateState();
}

class _VersusStateState extends State<VersusState> {
  int score1 = 0;
  int score2 = 0;
  Color color1 = const Color(0xffff0000);
  Color color2 = const Color(0xff0000ff);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NumberColorPicker(
              n: score1,
              color: color1,
              onChanged: (n, color) {
                setState(() {
                  score1 = n;
                  color1 = color;
                });
              },
              buttonChild: const Text("Pick Team 1 Color"),
            ),
            NumberColorPicker(
              n: score2,
              color: color2,
              onChanged: (n, color) {
                setState(() {
                  score2 = n;
                  color2 = color;
                });
              },
              buttonChild: const Text("Pick Team 2 Color"),
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(10)),
        ElevatedButton(
          onPressed: () {
            String stateString = 'NMBRS';
            stateString += sprintf('%02d%02d', [score1, score2]) +
                colorToHexString(color1, repeat: 2) +
                colorToHexString(color2, repeat: 2);

            Map<String, Object?> updates = {};
            updates['bigtimer/state'] = stateString;
            updates['bigtimer/last_used'] = ServerValue.timestamp;
            updates['bigtimer/last_used_name'] =
                auth.currentUser?.displayName ?? 'Unknown user';

            db.ref().update(updates).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("scores successfully updated")));
            }).catchError((e) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.toString())));
            });
          },
          child: const Text('Update Scores'),
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

class NumberColorPicker extends StatelessWidget {
  final int n;
  final Color color;
  final void Function(int, Color) onChanged;
  final Widget buttonChild;

  const NumberColorPicker(
      {super.key,
      required this.n,
      required this.color,
      required this.onChanged,
      required this.buttonChild});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            showColorPicker(
              context,
              color,
              (value) {
                onChanged(n, value);
              },
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: buttonChild,
        ),
        NumberPicker(
          minValue: 0,
          maxValue: 99,
          value: n,
          onChanged: (value) {
            onChanged(value, color);
          },
        ),
      ],
    );
  }
}

void showColorPicker(
    BuildContext context, Color initColor, void Function(Color) f) {
  Color color = initColor;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pick a color!'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: color,
            onColorChanged: (value) {
              color = value;
            },
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Select'),
            onPressed: () {
              Navigator.of(context).pop();
              f(color);
            },
          ),
        ],
      );
    },
  );
}
