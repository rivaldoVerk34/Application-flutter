import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();
  bool uploading = false;

  Future<void> _pickUpload() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    setState(() => uploading = true);
    final ref = FirebaseStorage.instance.ref('profile_pics/${user!.uid}.jpg');
    await ref.putFile(File(img.path));
    final url = await ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'photoUrl': url});
    setState(() => uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final doc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil'), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: doc.snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickUpload,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                  child: uploading ? const CircularProgressIndicator() : (data['photoUrl'] == null ? const Icon(Icons.person, size: 50) : null),
                ),
              ),
              const SizedBox(height: 16),
              Text(data['username'] ?? 'Nom', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(data['bio'] ?? 'Bio ici...', textAlign: TextAlign.center),
            ],
          );
        },
      ),
    );
  }
}
