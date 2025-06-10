import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/utils/logger.dart';
import '../../../auth/providers/auth_providers.dart';

class StorageTestScreen extends ConsumerStatefulWidget {
  const StorageTestScreen({super.key});

  @override
  ConsumerState<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends ConsumerState<StorageTestScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _status = 'No test started';
  bool _isLoading = false;

  Future<void> _testStorageConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase Storage connection...';
    });

    try {
      final storage = FirebaseStorage.instance;
      AppLogger.i('Firebase Storage instance: $storage');

      final ref = storage.ref().child('test/connection_test.txt');
      AppLogger.i('Storage reference created: ${ref.fullPath}');

      setState(() {
        _status = 'Storage connection successful!';
      });
    } catch (e, stackTrace) {
      AppLogger.e('Storage connection test failed', e, stackTrace);
      setState(() {
        _status = 'Storage connection failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isLoading = true;
          _status = 'Image selected, starting upload...';
        });

        await _uploadImage();
      }
    } catch (e) {
      AppLogger.e('Error picking image', e);
      setState(() {
        _status = 'Error picking image: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('No authenticated user');
      }

      setState(() {
        _status = 'Starting upload...';
      });

      final storage = FirebaseStorage.instance;
      final storageRef = storage.ref().child(
          'test_uploads/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      AppLogger.i('Starting test upload to: ${storageRef.fullPath}');

      final uploadTask = storageRef.putFile(
        _selectedImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'testUpload': 'true',
          },
        ),
      );

      setState(() {
        _status = 'Upload in progress...';
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.i('Test upload successful: $downloadUrl');
      setState(() {
        _status = 'Upload successful!\nURL: $downloadUrl';
      });
    } catch (e, stackTrace) {
      AppLogger.e('Test upload failed', e, stackTrace);
      setState(() {
        _status = 'Upload failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firebase Storage Test',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(_status),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const LinearProgressIndicator()
                    else ...[
                      ElevatedButton(
                        onPressed: _testStorageConnection,
                        child: const Text('Test Storage Connection'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickAndUploadImage,
                        child: const Text('Pick Image & Upload'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              const Text('Selected Image:'),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
