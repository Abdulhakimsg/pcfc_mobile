import '../../../core/identity/identity.dart';
import '../../../core/api/client.dart';
import '../../../core/util/env.dart';
import '../../categories/data/dto.dart';
import '../../categories/data/mapper.dart';
import '../../categories/data/models.dart';

abstract class CategoriesRepo {
  Future<List<Category>> listFor(Identity subject);
}

/// Fake for offline demo
class FakeCategoriesRepo implements CategoriesRepo {
  @override
  Future<List<Category>> listFor(Identity s) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      Category(id: 'trade', name: 'Business Documents', count: 1),
      Category(id: 'personnel', name: 'Personnel Documents', count: 1),
      Category(id: 'access', name: 'Access Passes', count: 1),
    ];
  }
}

/// API impl (drop-in)
class ApiCategoriesRepo implements CategoriesRepo {
  final HttpClient http;
  ApiCategoriesRepo(this.http);

  @override
  Future<List<Category>> listFor(Identity subject) async {
    // assume GET /v1/categories returns { items: [{id,name,count}] }
    final json = await http.get('/v1/categories', headers: {
      'X-Subject-Id': subject.id,
    });
    final items = (json['items'] as List)
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .map(toDomain)
        .toList();
    return items;
  }
}

/// Factory: controlled by USE_API
CategoriesRepo makeCategoriesRepo() =>
    useApi ? ApiCategoriesRepo(HttpClient()) : FakeCategoriesRepo();