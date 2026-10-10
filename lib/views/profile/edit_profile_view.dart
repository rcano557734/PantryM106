import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_colors.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;

  String? _savedPhotoPath;
  XFile? _selectedPhoto;

  String _photoKey(String uid) => 'pantrymatch_profile_photo_$uid';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _savedPhotoPath = prefs.getString(_photoKey(user.uid));

      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('Could not load your profile.');
    }
  }

  Future<void> _pickPhoto() async {
    if (_saving) return;

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (!mounted || photo == null) return;

      setState(() {
        _selectedPhoto = photo;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not select that photo. Please try again.');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please log in again.');
      return;
    }

    setState(() => _saving = true);

    var emailVerificationSent = false;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Copy the selected photo into persistent app storage.
      if (_selectedPhoto != null) {
        final directory = await getApplicationDocumentsDirectory();
        final sourceName = _selectedPhoto!.name;
        final dot = sourceName.lastIndexOf('.');
        var extension = dot >= 0
            ? sourceName.substring(dot).toLowerCase()
            : '.jpg';

        if (!{'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)) {
          extension = '.jpg';
        }

        final destination = File(
          '${directory.path}/pantrymatch_profile_${user.uid}$extension',
        );

        final oldPath = prefs.getString(_photoKey(user.uid));
        final copiedPhoto = await File(_selectedPhoto!.path)
            .copy(destination.path);

        await prefs.setString(_photoKey(user.uid), copiedPhoto.path);

        if (oldPath != null && oldPath != copiedPhoto.path) {
          try {
            final oldFile = File(oldPath);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (_) {
            // A leftover older photo does not prevent saving the profile.
          }
        }

        _savedPhotoPath = copiedPhoto.path;
      }

      final newName = _nameController.text.trim();

      if (newName != (user.displayName ?? '')) {
        await user.updateDisplayName(newName);
      }

      final newEmail = _emailController.text.trim();
      final currentEmail = user.email ?? '';

      if (newEmail.toLowerCase() != currentEmail.toLowerCase()) {
        await user.verifyBeforeUpdateEmail(newEmail);
        emailVerificationSent = true;
      }

      await user.reload();

      if (!mounted) return;

      setState(() => _saving = false);

      _showMessage(
        emailVerificationSent
            ? 'Profile saved. Check $newEmail and verify the email change.'
            : 'Your profile has been updated.',
      );

      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      switch (error.code) {
        case 'requires-recent-login':
          _showMessage(
            'For security, sign out and sign in again before changing your email.',
          );
        case 'email-already-in-use':
          _showMessage('That email address is already in use.');
        case 'invalid-email':
          _showMessage('Please enter a valid email address.');
        case 'network-request-failed':
          _showMessage('Check your internet connection and try again.');
        default:
          _showMessage('Could not update your account. Please try again.');
      }
    } catch (error) {
      debugPrint('Profile update error: $error');

      if (!mounted) return;

      setState(() => _saving = false);
      _showMessage('Could not save your profile. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _profileImage() {
    final path = _selectedPhoto?.path ?? _savedPhotoPath;

    if (path == null || !File(path).existsSync()) {
      return Icon(
        Icons.person_rounded,
        size: 48,
        color: AppColors.greenAccent(context),
      );
    }

    return Image.file(
      File(path),
      width: 104,
      height: 104,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Icon(
        Icons.person_rounded,
        size: 48,
        color: AppColors.greenAccent(context),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.greenAccent(context)),
      filled: true,
      fillColor: AppColors.surface(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.greenAccent(context),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.text(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.background(context),
        foregroundColor: AppColors.text(context),
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 112,
                                height: 112,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.greenSoft(context),
                                  border: Border.all(
                                    color: AppColors.border(context),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(child: _profileImage()),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Material(
                                  color: AppColors.primaryOrange,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    onPressed: _saving ? null : _pickPhoto,
                                    tooltip: 'Choose profile photo',
                                    icon: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _saving ? null : _pickPhoto,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose profile photo'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.greenAccent(context),
                            ),
                          ),
                          Text(
                            'Your photo is saved on this device.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text(context),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _nameController,
                            enabled: !_saving,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: _inputDecoration(
                              'Display name',
                              Icons.person_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            enabled: !_saving,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            style: TextStyle(color: AppColors.text(context)),
                            decoration: _inputDecoration(
                              'Email address',
                              Icons.email_outlined,
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty ||
                                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(email)) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Changing your email sends a verification link to the new address.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.muted(context),
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _saveProfile,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                _saving ? 'Saving...' : 'Save changes',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
