import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _coverPhotoController;
  late TextEditingController _displayNameController;
  late TextEditingController _photoUrlController;
  bool _isLoading = false;
  final UserRepository _userRepository = UserRepository();
  final ImagePicker _picker = ImagePicker();
  // TODO: Replace with your actual Cloudinary credentials
  final CloudinaryService _cloudinaryService = CloudinaryService(
    cloudName: 'drv9t5pbc', // Replace with your cloud name
    uploadPreset: 'AnimeHat', // Replace with your upload preset
  );

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Crop Image
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: isProfile
          ? const CropAspectRatio(ratioX: 1, ratioY: 1)
          : const CropAspectRatio(ratioX: 16, ratioY: 9),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: isProfile
              ? CropAspectRatioPreset.square
              : CropAspectRatioPreset.ratio16x9,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Cropper'),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _isLoading = true);

    // Upload to Cloudinary
    final url = await _cloudinaryService.uploadImage(File(croppedFile.path));

    setState(() {
      _isLoading = false;
      if (url != null) {
        if (isProfile) {
          _photoUrlController.text = url;
        } else {
          _coverPhotoController.text = url;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Check Cloudinary config.'),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.user.bio);
    _coverPhotoController = TextEditingController(
      text: widget.user.coverPhotoUrl,
    );
    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );
    _photoUrlController = TextEditingController(text: widget.user.photoUrl);
  }

  @override
  void dispose() {
    _bioController.dispose();
    _coverPhotoController.dispose();
    _displayNameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _userRepository.updateProfile(
        uid: widget.user.uid,
        bio: _bioController.text.trim(),
        displayName: _displayNameController.text.trim(),
        photoUrl: _photoUrlController.text.trim(),
        coverPhotoUrl: _coverPhotoController.text.trim().isEmpty
            ? null
            : _coverPhotoController.text.trim(),
        // socialLinks: {}, // TODO: Implement social links editor
      );

      // Also update basic info if changed (using syncUser logic or direct update)
      // Since updateProfile is for specific fields, we might need to update displayName separately
      // checks if Display Name or Photo URL changed? UserRepository.updateProfile could be expanded or we rely on separate call.
      // Let's check UserRepository... it only updates bio/cover/socials.
      // We should probably update basic info too if we want a "Full" edit page.

      // For now, let's stick to what updateProfile supports + maybe add todo or expand repo.
      // Actually, syncUser updates basic info but usually from Auth.
      // Let's assume for now we just edit the profile specific fields + maybe I can add displayName update to repo later if needed.
      // Wait, user might want to change display name.

      // Let's add that capability to this screen, but we might need to update Auth profile too?
      // For simplicity, let's just update Firestore for now or leave it as is.
      // The user asked for "Modification of profile file", implying the fields we added (bio, cover).

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // Cover Photo
                      GestureDetector(
                        onTap: () => _pickImage(false),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            image: _coverPhotoController.text.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      _coverPhotoController.text,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _coverPhotoController.text.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Profile Photo (Overlapping)
                      Positioned(
                        bottom: -50,
                        left: 20,
                        child: GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundImage:
                                      _photoUrlController.text.isNotEmpty
                                      ? NetworkImage(_photoUrlController.text)
                                      : null,
                                  child: _photoUrlController.text.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Cover Photo Edit Button
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _pickImage(false),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: "Display Name",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                              helperText:
                                  "This name will appear to other users",
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _bioController,
                            decoration: const InputDecoration(
                              labelText: "Bio",
                              hintText: "Tell us about yourself...",
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
