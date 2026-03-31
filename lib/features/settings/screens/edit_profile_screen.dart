import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/cubit/auth_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  String? _selectedGender;
  File? _avatarFile;
  final _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      _nameController.text = authState.user!.displayName ?? '';
      _selectedGender = authState.user!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện ảnh'),
              onTap: () async {
                final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (ctx.mounted) Navigator.pop(ctx, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh mới'),
              onTap: () async {
                final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (ctx.mounted) Navigator.pop(ctx, file);
              },
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    
    // Call AuthCubit to update profile. This will handle Firestore and Firebase Storage.
    await context.read<AuthCubit>().updateProfile(
      displayName: _nameController.text.trim(),
      avatarFile: _avatarFile,
      gender: _selectedGender,
    );
    
    if (!mounted) return;
    
    final state = context.read<AuthCubit>().state;
    setState(() => _isSaving = false);
    
    if (state.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.errorMessage ?? 'Có lỗi xảy ra', style: GoogleFonts.manrope()),
        backgroundColor: Colors.red,
      ));
      context.read<AuthCubit>().clearError();
    } else if (state.status == AuthStatus.authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cập nhật thành công'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2B7CEE);
    final cardColor = isDark ? const Color(0xFF1A2737) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111418);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Xong',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: _avatarFile != null
                              ? Image.file(_avatarFile!, fit: BoxFit.cover)
                              : Builder(builder: (context) {
                                  final authState = context.watch<AuthCubit>().state;
                                  final photoUrl = (authState.status == AuthStatus.authenticated && authState.user != null) ? authState.user!.photoUrl : null;
                                  return (photoUrl != null && photoUrl.isNotEmpty)
                                      ? Image.network(photoUrl, fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 60, color: Colors.grey);
                                }),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tên hiển thị', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.manrope(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Nhập tên của bạn',
                          hintStyle: GoogleFonts.manrope(color: Colors.grey),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Giới tính', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            hint: Text('Chọn giới tính', style: GoogleFonts.manrope(color: Colors.grey)),
                            isExpanded: true,
                            dropdownColor: cardColor,
                            style: GoogleFonts.manrope(color: textColor, fontSize: 16),
                            items: const [
                              DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                              DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                              DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedGender = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Đang lưu thông tin...', style: GoogleFonts.manrope(color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
