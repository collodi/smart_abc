import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

import 'firebase.dart';

enum TimerState {
  clock,
  timer,
}

class TimerControlView extends StatelessWidget {
  final TimerState? state;
  const TimerControlView(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case null:
        return const Text('Select a timer state.');
      case TimerState.clock:
        return const ClockState();
      case TimerState.timer:
        // TODO
        return const Text('Timer state');
    }
  }
}

String getHexString(int num, int nBytes) {
  ByteData bytes = ByteData(8);
  bytes.setInt64(0, num, Endian.little);

  String res = '';
  bytes.buffer.asUint8List(0, nBytes).forEach((element) {
    res += element.toRadixString(16).padLeft(2, '0');
  });

  return res;
}

class ClockState extends StatefulWidget {
  const ClockState({super.key});

  @override
  State<ClockState> createState() => _ClockStateState();
}

class _ClockStateState extends State<ClockState> {
  int offset = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            offset = DateTime.now().timeZoneOffset.inSeconds;
            String stateString = 'CLOCK${getHexString(offset, 4)}';

            // final bigtimer = await db.ref('bigtimer').get();
            // print('value: ${bigtimer.value}');

            final ref = db.doc('tests/test');
            await ref.set({'test_child': 'aaa'});

            print('AAA');
            // await db.ref('bigtimer').set({'state': stateString}).then((_) {
            //   print('success');
            // }).catchError((e) {
            //   print('error');
            //   print(e);
            // });
          },
          child: const Text('Show Clock'),
        )
      ],
    );
  }
}
