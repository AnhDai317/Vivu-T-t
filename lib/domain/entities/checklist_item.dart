class ChecklistItem {
  final String id;
  final String categoryId;
  String title;      // mutable để edit optimistic
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