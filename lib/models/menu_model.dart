class MenuModel {
  final String id;
  final DateTime menuDate;
  final String title;
  final String? description;
  final String? imageUrl;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MenuModel({
    required this.id,
    required this.menuDate,
    required this.title,
    this.description,
    this.imageUrl,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final menuDate = map['menu_date'];
    final title = map['title'];
    final createdBy = map['created_by'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Menu id is missing or invalid.');
    }
    if (menuDate is! String) {
      throw const FormatException('Menu date is missing or invalid.');
    }
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('Menu title is missing or invalid.');
    }
    if (createdBy is! String || createdBy.isEmpty) {
      throw const FormatException('Menu owner is missing or invalid.');
    }

    final parsedDate = DateTime.tryParse(menuDate);
    if (parsedDate == null) {
      throw const FormatException('Menu date is invalid.');
    }

    return MenuModel(
      id: id,
      menuDate: parsedDate,
      title: title,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      createdBy: createdBy,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  bool isForDate(DateTime date) {
    return menuDate.year == date.year &&
        menuDate.month == date.month &&
        menuDate.day == date.day;
  }
}
