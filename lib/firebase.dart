import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;
late final FirebaseDatabase db;

Future<void> initializeFirebase() async {
  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  auth = FirebaseAuth.instanceFor(app: app);
  db = FirebaseDatabase.instanceFor(app: app);
}
