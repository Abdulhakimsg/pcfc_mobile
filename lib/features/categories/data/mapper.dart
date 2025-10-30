import 'dto.dart';
import 'models.dart';

Category toDomain(CategoryDto d) => Category(id: d.id, name: d.name, count: d.count);