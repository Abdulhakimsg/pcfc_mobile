import 'package:flutter/material.dart';
import '../../../core/identity/identity.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../presentation/commercial_license_mock_page.dart'; // 👈 add

class DocumentsListPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const DocumentsListPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<DocumentsListPage> createState() => _DocumentsListPageState();
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  late final DocumentsRepo _repo;
  late Future<List<DocumentSummary>> _future;

  @override
  void initState() {
    super.initState();
    _repo = makeDocumentsRepo();
    _future = _repo.listFor(
      IdentityContext.current,
      categoryId: widget.categoryId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.listFor(
        IdentityContext.current,
        categoryId: widget.categoryId,
      );
    });
    await _future;
  }

  void _open(DocumentSummary d) {
    final title = d.title.toLowerCase();

    // 🔹 Demo rule: open the mock page for your Commercial License
    if (d.id == 'doc-1' || title.contains('commercial')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CommercialLicenseMockPage()),
      );
      return;
    }

    // 🔹 Default (no detail page yet) — tweak as needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped: ${d.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Documents • ${widget.categoryName}')),
      body: FutureBuilder<List<DocumentSummary>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load documents:\n${s.error}'),
              ),
            );
          }
          final items = s.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No documents in this category'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = items[i];
                return ListTile(
                  title: Text(
                    d.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${d.issuer} • ${d.type}'),
                  trailing: Icon(
                    d.valid ? Icons.verified : Icons.error_outline,
                    color: d.valid ? Colors.green : Colors.orange,
                  ),
                  onTap: () => _open(d),
                );
              },
            ),
          );
        },
      ),
    );
  }
}