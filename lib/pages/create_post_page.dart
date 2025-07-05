import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key}); // <-- ici super.key

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final textCtrl = TextEditingController();
  File? audioFile;
  bool isUploading = false;

  Future<void> pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        audioFile = File(result.files.single.path!);
      });
    }
  }

  Future<String?> uploadAudio() async {
    if (audioFile == null) return null;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final filename = 'audios/${uid}_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final ref = FirebaseStorage.instance.ref().child(filename);
    await ref.putFile(audioFile!);
    return await ref.getDownloadURL();
  }

  Future<void> submitPost() async {
    if (textCtrl.text.trim().isEmpty) return;

    setState(() => isUploading = true);

    final audioUrl = await uploadAudio();

    await FirebaseFirestore.instance.collection('posts').add({
      'text': textCtrl.text.trim(),
      'audioUrl': audioUrl,
      'authorId': FirebaseAuth.instance.currentUser!.uid,
      'likesCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    setState(() {
      isUploading = false;
      textCtrl.clear();
      audioFile = null;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un post'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: textCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Qu'est-ce que tu veux partager ?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickAudio,
                  icon: const Icon(Icons.music_note),
                  label: Text(
                    audioFile == null ? 'Ajouter une musique' : 'Changer la musique',
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                if (audioFile != null)
                  Expanded(
                    child: Text(
                      audioFile!.path.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isUploading ? null : submitPost,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Publier"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
