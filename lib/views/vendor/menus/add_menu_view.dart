import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_gradients.dart';
import '../../../core/services/menu_image_service.dart';
import '../../../providers/vendor/menu_provider.dart';
import 'edit_menu_view.dart';

class AddMenuView extends StatefulWidget {
  const AddMenuView({super.key});

  @override
  State<AddMenuView> createState() => _AddMenuViewState();
}

class _AddMenuViewState extends State<AddMenuView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  XFile? _selectedImage;
  DateTime? _menuDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorMenuProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Add Menu')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                _dateField(),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _imageUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                  ),
                ),
                SizedBox(height: 16.h),
                _imagePicker(),
                SizedBox(height: 28.h),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: FilledButton.icon(
                    onPressed: provider.isSaving ? null : _save,
                    icon: provider.isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save Menu'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            _selectedImage == null ? 'Choose Image' : 'Replace Image',
          ),
        ),
        if (_selectedImage != null) ...[
          SizedBox(height: 10.h),
          FutureBuilder(
            future: _selectedImage!.readAsBytes(),
            builder: (context, snapshot) => snapshot.hasData
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: Image.memory(
                      snapshot.data!,
                      height: 170.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : const SizedBox(height: 170),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    setState(() => _selectedImage = image);
  }

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDate: _menuDate ?? DateTime.now(),
        );
        if (!mounted || selected == null) return;
        setState(() => _menuDate = selected);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Menu Date'),
        child: Text(
          _menuDate == null ? 'Select a date' : _dateLabel(_menuDate!),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_menuDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a menu date.')),
      );
      return;
    }

    String? imageUrl = _imageUrlController.text;
    if (_selectedImage != null) {
      try {
        imageUrl = await MenuImageService.upload(_selectedImage!);
      } on FormatException catch (error) {
        _showImageError(error.message);
        return;
      } catch (_) {
        _showImageError(
          'Image upload failed. Check your connection and try again.',
        );
        return;
      }
    }

    final success = await context.read<VendorMenuProvider>().createMenu(
      menuDate: _menuDate!,
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: imageUrl,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu added successfully')));
      Navigator.pop(context);
    } else {
      final provider = context.read<VendorMenuProvider>();
      final duplicateMenu = provider.duplicateMenu;
      if (duplicateMenu != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('A menu already exists for this date.'),
            action: SnackBarAction(
              label: 'Edit Existing Menu',
              onPressed: () {
                Navigator.pushReplacement<void, void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => EditMenuView(menu: duplicateMenu),
                  ),
                );
              },
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<VendorMenuProvider>().errorMessage ??
                'Unable to create menu.',
          ),
        ),
      );
    }
  }

  void _showImageError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
