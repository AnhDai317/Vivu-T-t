class ChecklistItem {
  final String id;
  final String categoryId;
  final String title;
  final String itemDate; // 'yyyy-MM-dd'
  bool done;

  ChecklistItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.itemDate,
    this.done = false,
  });
}