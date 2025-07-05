import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isSending = false;

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final postRef = FirebaseFirestore.instance.collection('posts');

      await postRef.add({
        'text': _textController.text.trim(),
        'authorId': user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
      });

      if (!mounted) return; // Protection avant navigation asynchrone
      Navigator.pop(context);
    } catch (e) {
      // Remplacer print par debugPrint (optionnel)
      debugPrint('Erreur lors de l\'ajout du post: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ajout du post.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Post'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Texte du Post',
                hintText: 'Que voulez-vous partager ?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            _isSending
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ajouter le Post'), // child en dernier
                  ),
          ],
        ),
      ),
    );
  }
}
