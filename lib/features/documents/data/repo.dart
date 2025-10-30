import '../../../core/identity/identity.dart';
import '../../../core/api/client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/util/env.dart';
import 'dto.dart';
import 'mapper.dart';
import 'models.dart';

abstract class DocumentsRepo {
  Future<List<DocumentSummary>> listFor(Identity subject);
}

class FakeDocumentsRepo implements DocumentsRepo {
  @override
  Future<List<DocumentSummary>> listFor(Identity s) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (s.id == 'user-123') {
      return [
        DocumentSummary(id:'doc-1', title:'Trade License', issuer:'Dubai Freezone', type:'License',
          issuedAt: DateTime.now().subtract(const Duration(days:9)), valid:true),
        DocumentSummary(id:'doc-2', title:'Seafarer ID', issuer:'Maritime Authority', type:'ID',
          issuedAt: DateTime.now().subtract(const Duration(days:32)), valid:true),
      ];
    }
    return [ DocumentSummary(id:'doc-9', title:'Education Certificate', issuer:'KHDA', type:'Certificate',
      issuedAt: DateTime.now().subtract(const Duration(days:120)), valid:true) ];
  }
}

class ApiDocumentsRepo implements DocumentsRepo {
  final HttpClient http;
  ApiDocumentsRepo(this.http);

  @override
  Future<List<DocumentSummary>> listFor(Identity subject) async {
    final json = await http.get(Endpoints.documents,
      headers: {'X-Subject-Id': subject.id},
      query: {'limit': '20'},
    );
    final items = (json['items'] as List)
        .map((e) => DocumentSummaryDto.fromJson(e as Map<String, dynamic>))
        .map(toDomain)
        .toList();
    return items;
  }
}

/// Factory: choose Fake or API using env flag
DocumentsRepo makeDocumentsRepo() =>
    useApi ? ApiDocumentsRepo(HttpClient()) : FakeDocumentsRepo();