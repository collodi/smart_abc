import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase.dart';
import 'timer.dart';

// FIXME something wrong with the auth
// FIXME can't even write to firestore (gives errors tho)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();

  auth.authStateChanges().listen((user) {
    print('auth state change');
    print('user user: $user');
  });
  runApp(const MainApp());
}

Future<UserCredential> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );

  return await FirebaseAuth.instance.signInWithCredential(credential);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: StreamBuilder<User?>(
            stream: auth.authStateChanges(),
            builder: (context, snapshot) {
              print('User: ${snapshot.data}');
              if (snapshot.hasData) {
                return Home();
              }

              return const Login();
            },
          ),
        ),
      ),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            try {
              setState(() {
                error = null;
              });

              await signInWithGoogle().then((value) {
                print(value);
              }).catchError((err) {
                print(err);
              });
              // TODO when successful, make/check a user entry in firestore
            } on FirebaseAuthException catch (e) {
              setState(() {
                error = e.message;
              });
            }
          },
          child: const Text('Log In With Google'),
        ),
        Text(error ?? ''),
      ],
    );
  }
}

const states = [
  DropdownMenuItem(value: TimerState.clock, child: Text('Clock')),
  DropdownMenuItem(value: TimerState.timer, child: Text('Timer')),
];

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TimerState? state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<TimerState>(
          items: states,
          value: state,
          onChanged: (val) {
            setState(() {
              state = val;
            });
          },
        ),
        TimerControlView(state),
      ],
    );
  }
}
