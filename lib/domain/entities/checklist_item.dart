class ChecklistItem {
  final String id;
  final String categoryId;
  final String title;
  bool done;

  ChecklistItem({
    required this.id,
    required this.categoryId,
    required this.title,
    this.done = false,
  });
}
