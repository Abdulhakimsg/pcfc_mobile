class CategoryDto {
  final String id;
  final String name;
  final int? count;
  CategoryDto({required this.id, required this.name, this.count});
  factory CategoryDto.fromJson(Map<String, dynamic> j) =>
      CategoryDto(id: j['id'], name: j['name'], count: j['count']);
}