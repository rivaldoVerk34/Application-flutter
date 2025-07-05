import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import '../firebase_messaging_service.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final commentCtrl = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool isSending = false;
  final _firebaseMessagingService = FirebaseMessagingService();

  final Logger _logger = Logger('PostDetailPage');

  @override
  void initState() {
    super.initState();
    _firebaseMessagingService.initFirebaseMessaging(
      onMessageReceived: (message) {
        _logger.info('Message reçu: ${message.messageId}');
      },
      onMessageOpenedApp: (message) {
        _logger.info('Notification ouverte: ${message.messageId}');
      },
      onInitialMessage: (message) {
        if (message != null) {
          _logger.info('Message initial: ${message.messageId}');
        }
      },
    );
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await _firebaseMessagingService.requestPermission();
  }

  Future<void> addComment() async {
    final text = commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'authorId': user!.uid,
        'authorName': user!.displayName ?? 'Utilisateur',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      commentCtrl.clear();
    } catch (e, stack) {
      _logger.severe('Erreur lors de l’envoi du commentaire', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l’envoi du commentaire')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  Future<void> toggleLike(bool isLiked) async {
    if (user == null) return;

    final likeRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(user!.uid);

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      if (isLiked) {
        await likeRef.delete();
        await postRef.update({'likesCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
        await postRef.update({'likesCount': FieldValue.increment(1)});
      }
    } catch (e, stack) {
      _logger.warning('Erreur lors du like', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour du like')),
        );
      }
    }
  }

  Future<bool> checkIfLiked() async {
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(user!.uid)
        .get();
    return doc.exists;
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Détail du post", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: postRef.snapshots(),
        builder: (context, postSnap) {
          if (!postSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final postData = postSnap.data!.data() as Map<String, dynamic>;
          final postText = postData['text'] ?? '';
          final likeCount = postData['likesCount'] ?? 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      postText,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              FutureBuilder<bool>(
                future: checkIfLiked(),
                builder: (context, likeSnap) {
                  if (!likeSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final isLiked = likeSnap.data!;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 32,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey<bool>(isLiked),
                            color: isLiked ? Colors.redAccent : Colors.grey,
                          ),
                        ),
                        onPressed: () => toggleLike(isLiked),
                      ),
                      Text(
                        '$likeCount likes',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  );
                },
              ),
              const Divider(thickness: 1.5),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: postRef.collection('comments').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snap.data!.docs;

                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          "Pas encore de commentaires",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final data = comments[index].data() as Map<String, dynamic>;
                        final commentText = data['text'] ?? '';
                        final authorName = data['authorName'] ?? 'Utilisateur';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U'),
                            ),
                            title: Text(commentText),
                            subtitle: Text("Par $authorName"),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => addComment(),
                        enabled: !isSending,
                      ),
                    ),
                    const SizedBox(width: 8),
                    isSending
                        ? const CircularProgressIndicator()
                        : CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: addComment,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
