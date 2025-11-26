import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../../core/identity/identity.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../presentation/document_page.dart';

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

/// UI model we use in this page only
class _UiDocument {
  final String id;
  final String title;      // e.g. "Commercial License"
  final String issuer;     // e.g. "Trakhees"
  final bool valid;
  final String? rawUrl;    // file.label == "raw"
  final String? pdfUrl;    // file.label == "presentation" / "pdf"
  final String? shareLink; // top-level share_link from Nexus

  _UiDocument({
    required this.id,
    required this.title,
    required this.issuer,
    required this.valid,
    this.rawUrl,
    this.pdfUrl,
    this.shareLink,
  });
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  late final DocumentsRepo _repo;
  late Future<List<_UiDocument>> _future;

  bool get _isBusinessCategory {
    final id = widget.categoryId.toLowerCase();
    final name = widget.categoryName.toLowerCase();
    return id.contains('business') || name.contains('business');
  }

  @override
  void initState() {
    super.initState();
    _repo = makeDocumentsRepo();
    _future = _loadDocuments();
  }

  /// Simple Title Case helper: "commercial license" -> "Commercial License"
  String _toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Future<List<_UiDocument>> _loadDocuments() {
    if (_isBusinessCategory) {
      // Business docs: fetch from Nexus via email identifier + follow RAW
      return _fetchBusinessDocumentsFromNexus();
    } else {
      // Other categories: use existing repo
      return _fetchFromRepo();
    }
  }

  Future<List<_UiDocument>> _fetchFromRepo() async {
    final docs = await _repo.listFor(
      IdentityContext.current,
      categoryId: widget.categoryId,
    );

    return docs
        .map((d) => _UiDocument(
              id: d.id,
              title: _toTitleCase(d.title),
              issuer: _toTitleCase(d.issuer),
              valid: d.valid,
              rawUrl: null,
              pdfUrl: null,
              shareLink: null,
            ))
        .toList();
  }

  /// Helper: extract document title from RAW JSON.
  /// For your business docs, this should be "document_name": "commercial license"
  String? _extractTitleFromRaw(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;

    if (raw['document_name'] is String) {
      return raw['document_name'] as String;
    }

    // Fallbacks
    if (raw['name'] is String) return raw['name'] as String;
    if (raw['title'] is String) return raw['title'] as String;

    final cs = raw['credentialSubject'];
    if (cs is Map<String, dynamic>) {
      if (cs['name'] is String) return cs['name'] as String;
      if (cs['title'] is String) return cs['title'] as String;
    }

    return null;
  }

  /// Helper: extract issuer name from RAW JSON.
  /// For your business docs, this should be "document_issuer": "trakhees"
  String? _extractIssuerFromRaw(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;

    if (raw['document_issuer'] is String) {
      return raw['document_issuer'] as String;
    }

    // Fallback: typical OA issuer field
    final issuer = raw['issuer'];
    if (issuer is String) return issuer;
    if (issuer is Map<String, dynamic>) {
      if (issuer['name'] is String) return issuer['name'] as String;
      if (issuer['legalName'] is String) return issuer['legalName'] as String;
    }

    return null;
  }

  Future<List<_UiDocument>> _fetchBusinessDocumentsFromNexus() async {
    try {
      // 1. Call /documents/by_recipient
      final uri = Uri.parse(
        'https://nexus.uat.accredify.io/api/v1/documents/by_recipient?identifier_type=email&identifier_value=demo_ali%40business.com',
      );

      final res = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Authorization':
              'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJhMDQ0N2NmZC00ZmFkLTRlMDctYTAwMS0wNmUxMDU2ZWMzOWMiLCJqdGkiOiJlZTk1YzUxZTJjYTBmOGFkODAxMjg5YzQ3OTA1MGE1YzdmOTc4ZWM5MmYxNzRiOWRlMzkyYWU4NGY0NTdlZTRiMmU3MTYxZDRlZjlmOTg5NiIsImlhdCI6MTc2MjMzNTYwOC4yNTc4NTcsIm5iZiI6MTc2MjMzNTYwOC4yNTc4NjEsImV4cCI6MTc5Mzg3MTYwOC4yNDQ4Mywic3ViIjoiIiwic2NvcGVzIjpbInJ1bi13b3JrZmxvdyIsIndlYmNvbXBvbmVudC12ZXJpZmljYXRpb24iLCJ2ZXJpZmljYXRpb24tc3VpdGUiLCJ3b3JrZmxvd3M6cmVhZCIsIndvcmtmbG93LXJ1bnM6cmVhZCIsImRvY3VtZW50czpyZWFkIiwiZG9jdW1lbnRzOndyaXRlIiwiY3VzdG9tLXZpZXdzOnJlYWQiLCJ1c2VyczpyZWFkIiwiZGVzaWduLXRlbXBsYXRlczpyZWFkIiwiZG9jdW1lbnQtdGVtcGxhdGVzOnJlYWQiLCJncm91cHM6cmVhZCIsImNvdXJzZXM6cmVhZCIsImNvdXJzZXM6d3JpdGUiXX0.YOQACJ_J8A8RN7G_UJUtJaDIvbmPkLfc_RTzsnkbdqZxWzEA4Y9IZsTBZbEXmLkeWErGOM60R-_yBF0n9jNlVLQVDpmlf2DnGzK5G9lTZUO48Y_VwDnA4qbr52Gc2HIueTmBEZBrl_-5Hg-hIhdlcRmnVxsUmCPM8s_2RpM9M_0-dPt1_C1UrJ9Ce0eicRdH7S03od4cPgWx9HMoTg3olElRnhA0kehcZA_FXkZGxBL7ybE1lJ9wUUKp2Aszb-VLV0MtLqtEZrZhiTObESOdCSdQWWmMSySXw_UnaMDei1rMlhORNYvejXyb7QCOG7QvJJA-dJ16VYeT3EkQ11G681NGYV1JoCubZwrncX-2tCaVTaLFG65PKVL7ncGwjtms_vnJ7eBowA9lIbTYMfScZX76kub5mW2JQNWEvwR9-M9jJnfXmACAwioVk4Ag1-58a2hxuog3NDmjDai1_cKBz_zlULQCDq5_QxIskO1fNyS_9p9Dwj_cihFtL2ovec8H6vxZ9_MOlUUe9tJ4H94MWpRXOPKm79OMsbJPC2SiZ3AH4PWQdpqlkK5Q9SQHuldPgs-mD-7XcA1Gf394UFuqjmEVcWz-ecHfVHDXchFAPSGDBD4zt6AiSKodkISbm0xMeFvi3dLmpWM4BtZUsu3_gGM9ZKg7MsdObOBL9dcw2-0',
        },
      );

      if (res.statusCode != 200) {
        return [];
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final data = decoded['data'];

      if (data is! List) return [];

      final results = <_UiDocument>[];

      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;

        final uuid = item['uuid']?.toString() ?? '';
        final status = item['status']?.toString();
        final valid = status == 'issued';
        final shareLink = item['share_link']?.toString();

        String? rawUrl;
        String? pdfUrl;

        final files = item['files'];
        if (files is List) {
          for (final f in files) {
            if (f is! Map<String, dynamic>) continue;
            final label = f['label']?.toString();
            final url = f['url']?.toString();
            if (url == null || url.isEmpty) continue;

            if (label == 'raw' && rawUrl == null) {
              rawUrl = url;
            } else if ((label == 'presentation' || label == 'pdf') &&
                pdfUrl == null) {
              pdfUrl = url;
            }
          }
        }

        String title = 'Document';
        String issuer = 'Unknown issuer';

        // Use RAW JSON to extract document_name & document_issuer
        if (rawUrl != null) {
          try {
            final rawRes = await http.get(Uri.parse(rawUrl));
            if (rawRes.statusCode == 200) {
              final rawJson = jsonDecode(rawRes.body);

              dynamic raw = rawJson;
              if (rawJson is Map<String, dynamic> && rawJson['data'] != null) {
                raw = rawJson['data'];
              }

              final t = _extractTitleFromRaw(raw);
              final i = _extractIssuerFromRaw(raw);

              if (t != null && t.isNotEmpty) title = t;
              if (i != null && i.isNotEmpty) issuer = i;
            }
          } catch (_) {
            // keep defaults
          }
        }

        title = _toTitleCase(title);   // "Commercial License"
        issuer = _toTitleCase(issuer); // "Trakhees"

        results.add(
          _UiDocument(
            id: uuid,
            title: title,
            issuer: issuer,
            valid: valid,
            rawUrl: rawUrl,
            pdfUrl: pdfUrl,
            shareLink: shareLink,
          ),
        );
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadDocuments();
    });
    await _future;
  }

  Future<void> _open(_UiDocument d) async {
    // For Business category, open the detailed document page
    if (_isBusinessCategory) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentPage(
            displayTitle: d.title,
            issuer: d.issuer,
            shareLink: d.shareLink ?? '',
            rawUrl: d.rawUrl,
            pdfUrl: d.pdfUrl,
          ),
        ),
      );
      return;
    }

    // Default for other categories (for now)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped: ${d.title} — ${d.issuer}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: FutureBuilder<List<_UiDocument>>(
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
                    d.title, // "Commercial License"
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    d.issuer, // "Trakhees"
                  ),
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