import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase.dart';
import 'timer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebase();
  runApp(const MainApp());
}

Future<UserCredential> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn(
          clientId:
              '134790081856-fn804ibqandel75i25oe5ien0vuihtrm.apps.googleusercontent.com')
      .signIn();
  final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );

  return await auth.signInWithCredential(credential);
}

Future<void> addUserToFirestore() async {
  if (auth.currentUser == null) {
    return;
  }

  final uid = auth.currentUser!.uid;
  final doc = db.ref('/users/$uid');
  final snap = await doc.get();
  if (!snap.exists) {
    await doc.set({
      'uid': uid,
      'displayName': auth.currentUser!.displayName,
      'priv': 0,
    });
  }
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
              if (snapshot.hasData) {
                addUserToFirestore();
                return const Home();
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  setState(() {
                    error = null;
                  });

                  await signInWithGoogle();
                } on FirebaseAuthException catch (e) {
                  setState(() {
                    error = e.message;
                  });
                }
              },
              child: const Text('Log In With Google'),
            ),
            const Padding(padding: EdgeInsets.all(10)),
            Text(
              error ?? '',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: TimerControlView(),
    );
  }
}
