import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_gradients.dart';
import '../../../core/services/menu_image_service.dart';
import '../../../models/menu_model.dart';
import '../../../providers/vendor/menu_provider.dart';

class EditMenuView extends StatefulWidget {
  final MenuModel menu;

  const EditMenuView({required this.menu, super.key});

  @override
  State<EditMenuView> createState() => _EditMenuViewState();
}

class _EditMenuViewState extends State<EditMenuView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late DateTime _menuDate;
  XFile? _selectedImage;
  late final String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _menuDate = widget.menu.menuDate;
    _titleController = TextEditingController(text: widget.menu.title);
    _descriptionController = TextEditingController(
      text: widget.menu.description ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.menu.imageUrl ?? '',
    );
    _existingImageUrl = widget.menu.imageUrl;
  }

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
      appBar: AppBar(title: const Text('Edit Menu')),
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
                FilledButton.icon(
                  onPressed: provider.isSaving ? null : _save,
                  icon: provider.isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    final existingUrl = _existingImageUrl?.trim();
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
        SizedBox(height: 10.h),
        if (_selectedImage != null)
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
          )
        else if (existingUrl != null && existingUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Image.network(
              existingUrl,
              height: 170.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Text('Existing image unavailable.'),
            ),
          ),
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
          initialDate: _menuDate,
        );
        if (!mounted || selected == null) return;
        setState(() => _menuDate = selected);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Menu Date'),
        child: Text(_dateLabel(_menuDate)),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

    final success = await context.read<VendorMenuProvider>().updateMenu(
      menuId: widget.menu.id,
      menuDate: _menuDate,
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: imageUrl,
    );
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu updated successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to update menu.')));
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
