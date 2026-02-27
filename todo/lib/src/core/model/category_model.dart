import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final int colorValue;
  final int iconCodePoint;

  const Category({
    this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Category copyWith({int? id, String? name, int? colorValue, int? iconCodePoint}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'] ?? '',
        colorValue: map['colorValue'] ?? 0xFF6366F1,
        iconCodePoint: map['iconCodePoint'] ?? Icons.folder.codePoint,
      );

  @override
  List<Object?> get props => [id, name, colorValue, iconCodePoint];
}

// Default categories
final List<Category> defaultCategories = [
  Category(name: 'Personal', colorValue: 0xFF6366F1, iconCodePoint: Icons.person.codePoint),
  Category(name: 'Work', colorValue: 0xFF0EA5E9, iconCodePoint: Icons.work.codePoint),
  Category(name: 'Shopping', colorValue: 0xFF10B981, iconCodePoint: Icons.shopping_cart.codePoint),
  Category(name: 'Health', colorValue: 0xFFF43F5E, iconCodePoint: Icons.favorite.codePoint),
  Category(name: 'Finance', colorValue: 0xFFF59E0B, iconCodePoint: Icons.attach_money.codePoint),
  Category(name: 'Education', colorValue: 0xFF8B5CF6, iconCodePoint: Icons.school.codePoint),
];