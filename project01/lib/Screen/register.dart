import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:project01/Screen/home.dart';
import 'package:project01/models/profile.dart' show Profile;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:project01/Screen/login.dart';
import 'package:project01/models/profile.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Future<FirebaseApp> firebase = Firebase.initializeApp();
  Profile profile = Profile(email: '', password: '');
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signUpWithGoogle() async {
    try {
      GoogleSignInAccount? account;
      try {
        final Future<GoogleSignInAccount?>? lf =
            googleSignIn.attemptLightweightAuthentication();
        if (lf != null) account = await lf;
      } catch (_) {
        account = null;
      }
      if (account == null) {
        try {
          account = await googleSignIn.authenticate();
        } catch (e) {
          print('Google authenticate threw: $e');
          return null;
        }
      }

      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return null;

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error signing up with Google: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Welcome to', style: TextStyle(fontSize: 22)),
                const Text(
                  'Sign Up!',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Gmail',
                          border: UnderlineInputBorder(),
                        ),
                        validator:
                            MultiValidator([
                              RequiredValidator(errorText: "กรุณากรอกอีเมล"),
                              EmailValidator(
                                errorText: "กรุณากรอกอีเมลให้ถูกต้อง",
                              ),
                            ]).call,
                        onSaved: (String? email) {
                          profile.email = email ?? '';
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: UnderlineInputBorder(),
                        ),
                        validator:
                            RequiredValidator(
                              errorText: "กรุณากรอกรหัสผ่าน",
                            ).call,
                        onSaved: (String? password) {
                          profile.password = password ?? '';
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              // แสดง Loading Dialog
                              showDialog(
                                context: context,
                                barrierDismissible:
                                    false, // ป้องกันการปิด dialog โดยการคลิกด้านนอก
                                builder: (BuildContext context) {
                                  return const Center(
                                    child: AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text("กำลังดำเนินการ..."),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              try {
                                // รอ 3 วินาที
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );

                                // สร้างบัญชีผู้ใช้
                                await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                      email: profile.email,
                                      password: profile.password,
                                    );

                                // ปิด Loading Dialog
                                Navigator.of(context).pop();

                                // แสดง Success Dialog
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('สำเร็จ'),
                                      content: const Text('ลงทะเบียนสำเร็จ'),
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _formKey.currentState!.reset();
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  return MyHomePage();
                                                },
                                              ),
                                            );
                                          },
                                          child: const Text('ตกลง'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } on FirebaseAuthException catch (e) {
                                // ปิด Loading Dialog
                                Navigator.of(context).pop();

                                // แสดง Error Dialog
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('เกิดข้อผิดพลาด'),
                                      content: Text(
                                        e.message ?? "ไม่สามารถลงทะเบียนได้",
                                      ),
                                      icon: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('ปิด'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          },
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Image.asset(
                            'assets/img/google.jpg',
                            height: 24.0,
                          ),
                          label: const Text('Sign up with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text("กำลังลงทะเบียนด้วย Google..."),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );

                            try {
                              final UserCredential? userCredential =
                                  await signUpWithGoogle();

                              // ปิด Loading Dialog
                              Navigator.of(context).pop();

                              if (userCredential != null) {
                                // ลงทะเบียนสำเร็จ
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('สำเร็จ'),
                                      content: const Text(
                                        'ลงทะเบียนด้วย Google สำเร็จ',
                                      ),
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const MyHomePage(),
                                              ),
                                            );
                                          },
                                          child: const Text('ตกลง'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              } else {
                                // ลงทะเบียนไม่สำเร็จ
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('เกิดข้อผิดพลาด'),
                                      content: const Text(
                                        'ไม่สามารถลงทะเบียนด้วย Google ได้',
                                      ),
                                      icon: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('ปิด'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            } catch (e) {
                              Navigator.of(context).pop(); // ปิด Loading Dialog
                              print('Error: $e');
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "SIGN IN ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
