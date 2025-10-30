import '../../../core/identity/identity.dart';
import '../../../core/api/client.dart';
import '../../../core/util/env.dart';
import 'models.dart';

abstract class DocumentsRepo {
  /// Category is REQUIRED for this app flow.
  Future<List<DocumentSummary>> listFor(Identity subject, {required String categoryId});
}

class FakeDocumentsRepo implements DocumentsRepo {
  @override
  Future<List<DocumentSummary>> listFor(Identity s, {required String categoryId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // base data
    final all = s.id == 'user-123'
        ? <DocumentSummary>[
            DocumentSummary(
              id: 'doc-1',
              title: 'Commercial License',
              issuer: 'Trakhees',
              type: 'License',
              issuedAt: DateTime.now().subtract(const Duration(days: 9)),
              valid: true,
            ),
            DocumentSummary(
              id: 'doc-2',
              title: 'Seafarer ID',
              issuer: 'Maritime Authority',
              type: 'ID',
              issuedAt: DateTime.now().subtract(const Duration(days: 32)),
              valid: true,
            ),
            DocumentSummary(
              id: 'doc-3',
              title: 'Gate Pass',
              issuer: 'Port Authority',
              type: 'Access',
              issuedAt: DateTime.now().subtract(const Duration(days: 2)),
              valid: true,
            ),
          ]
        : <DocumentSummary>[
            DocumentSummary(
              id: 'doc-9',
              title: 'Education Certificate',
              issuer: 'KHDA',
              type: 'Certificate',
              issuedAt: DateTime.now().subtract(const Duration(days: 120)),
              valid: true,
            ),
          ];

    // strict category slice
    switch (categoryId) {
      case 'trade':
        return all.where((d) => d.type == 'License').toList();
      case 'personnel':
        return all.where((d) => d.type == 'ID' || d.type == 'Certificate').toList();
      case 'access':
        return all.where((d) => d.type == 'Access').toList();
      default:
        return const []; // unknown category → empty list
    }
  }
}

class ApiDocumentsRepo implements DocumentsRepo {
  final HttpClient http;
  ApiDocumentsRepo(this.http);

  @override
  Future<List<DocumentSummary>> listFor(Identity subject, {required String categoryId}) async {
    final json = await http.get(
      '/v1/documents',
      headers: {'X-Subject-Id': subject.id},
      query: {
        'limit': '20',
        'categoryId': categoryId,
      },
    );

    final items = (json['items'] as List).map((e) {
      final j = e as Map<String, dynamic>;
      return DocumentSummary(
        id: j['id'] as String,
        title: j['title'] as String,
        issuer: j['issuer'] as String,
        type: j['type'] as String,
        issuedAt: DateTime.tryParse(j['issuedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        valid: (j['valid'] as bool?) ?? false,
      );
    }).toList();

    return items;
  }
}

DocumentsRepo makeDocumentsRepo() =>
    useApi ? ApiDocumentsRepo(HttpClient()) : FakeDocumentsRepo();