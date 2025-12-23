import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'riwayat.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscure = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: ['email']);

  Future<void> register() async {
    try {
      final UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );  

      final user = FirebaseAuth.instance.currentUser;
      final String uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': user.email,
        'photoUrl': '',
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      print("Error register: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential cred = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': cred.user!.displayName ?? 'google_user',
        'email': cred.user!.email,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AbsensiPage()),
      );
    } catch (e) {
      print("Error login Google: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2DBD),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'REGISTER',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Email
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Email'),
              ),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7CDEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Masukkan email',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Username
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Username'),
              ),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7CDEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Masukkan username',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Password'),
              ),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7CDEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Masukkan password',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // REGISTER Button
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2DBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Text('or'),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text(
                    'Google',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: const BorderSide(color: Colors.black54),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF1F2DBD),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
