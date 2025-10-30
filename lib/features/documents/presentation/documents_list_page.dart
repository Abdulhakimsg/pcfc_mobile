import 'package:flutter/material.dart';
import '../../../core/identity/identity.dart';
import '../data/models.dart';
import '../data/repo.dart';

class DocumentsListPage extends StatefulWidget {
  const DocumentsListPage({super.key});
  @override
  State<DocumentsListPage> createState() => _DocumentsListPageState();
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  late final DocumentsRepo _repo;
  late Future<List<DocumentSummary>> _future;

  @override
  void initState() {
    super.initState();
    _repo = makeDocumentsRepo(); // <- toggle by env
    _future = _repo.listFor(IdentityContext.current);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Documents • ${IdentityContext.current.name}')),
      body: FutureBuilder<List<DocumentSummary>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (s.hasError) return Center(child: Text('Failed: ${s.error}'));
          final items = s.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('No documents'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = items[i];
              return ListTile(
                title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${d.issuer} • ${d.type}'),
                trailing: Icon(d.valid ? Icons.verified : Icons.error_outline, color: d.valid ? Colors.green : Colors.orange),
              );
            },
          );
        },
      ),
    );
  }
}