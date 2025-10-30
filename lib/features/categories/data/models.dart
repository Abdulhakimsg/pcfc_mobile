class Category {
  final String id;
  final String name;
  final int? count; // optional: how many docs
  const Category({required this.id, required this.name, this.count});
}