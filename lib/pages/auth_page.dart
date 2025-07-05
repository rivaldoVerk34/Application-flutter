import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLoading = false;
  String? error;

  Future<void> signIn() async {
    setState(() { error = null; isLoading = true; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } catch (e) {
      error = 'Erreur authentification';
    }
    setState(() => isLoading = false);
  }

  Future<void> register() async {
    setState(() { error = null; isLoading = true; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } catch (e) {
      error = 'Erreur inscription';
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
          const SizedBox(height: 20),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          if (isLoading) const CircularProgressIndicator(),
          if (!isLoading)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: signIn, child: const Text('Connexion')),
                ElevatedButton(onPressed: register, child: const Text('Inscription')),
              ],
            ),
        ]),
      ),
    );
  }
}
