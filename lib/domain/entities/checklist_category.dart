import 'package:vivu_tet/domain/entities/checklist_item.dart';

class ChecklistCategory {
  final String id;
  final String icon;
  final String title;
  final int colorValue;
  final List<ChecklistItem> items;

  ChecklistCategory({
    required this.id,
    required this.icon,
    required this.title,
    required this.colorValue,
    required this.items,
  });

  int get doneCount => items.where((i) => i.done).length;
  double get progress =>
      items.isEmpty ? 0 : doneCount / items.length;
}