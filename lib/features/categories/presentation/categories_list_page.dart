import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/identity/identity.dart';
import '../data/models.dart';
import '../data/repo.dart';
import '../../documents/presentation/documents_list_page.dart';

class CategoriesListPage extends StatefulWidget {
  const CategoriesListPage({super.key});
  @override
  State<CategoriesListPage> createState() => _CategoriesListPageState();
}

class _CategoriesListPageState extends State<CategoriesListPage> {
  late final CategoriesRepo _repo;
  late Future<List<Category>> _future;

  int? _businessDocsCount;
  int? _personnelDocsCount;
  int? _accessDocsCount;

  static const _bearerToken =
      'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJhMDQ0N2NmZC00ZmFkLTRlMDctYTAwMS0wNmUxMDU2ZWMzOWMiLCJqdGkiOiJlZTk1YzUxZTJjYTBmOGFkODAxMjg5YzQ3OTA1MGE1YzdmOTc4ZWM5MmYxNzRiOWRlMzkyYWU4NGY0NTdlZTRiMmU3MTYxZDRlZjlmOTg5NiIsImlhdCI6MTc2MjMzNTYwOC4yNTc4NTcsIm5iZiI6MTc2MjMzNTYwOC4yNTc4NjEsImV4cCI6MTc5Mzg3MTYwOC4yNDQ4Mywic3ViIjoiIiwic2NvcGVzIjpbInJ1bi13b3JrZmxvdyIsIndlYmNvbXBvbmVudC12ZXJpZmljYXRpb24iLCJ2ZXJpZmljYXRpb24tc3VpdGUiLCJ3b3JrZmxvd3M6cmVhZCIsIndvcmtmbG93LXJ1bnM6cmVhZCIsImRvY3VtZW50czpyZWFkIiwiZG9jdW1lbnRzOndyaXRlIiwiY3VzdG9tLXZpZXdzOnJlYWQiLCJ1c2VyczpyZWFkIiwiZGVzaWduLXRlbXBsYXRlczpyZWFkIiwiZG9jdW1lbnQtdGVtcGxhdGVzOnJlYWQiLCJncm91cHM6cmVhZCIsImNvdXJzZXM6cmVhZCIsImNvdXJzZXM6d3JpdGUiXX0.YOQACJ_J8A8RN7G_UJUtJaDIvbmPkLfc_RTzsnkbdqZxWzEA4Y9IZsTBZbEXmLkeWErGOM60R-_yBF0n9jNlVLQVDpmlf2DnGzK5G9lTZUO48Y_VwDnA4qbr52Gc2HIueTmBEZBrl_-5Hg-hIhdlcRmnVxsUmCPM8s_2RpM9M_0-dPt1_C1UrJ9Ce0eicRdH7S03od4cPgWx9HMoTg3olElRnhA0kehcZA_FXkZGxBL7ybE1lJ9wUUKp2Aszb-VLV0MtLqtEZrZhiTObESOdCSdQWWmMSySXw_UnaMDei1rMlhORNYvejXyb7QCOG7QvJJA-dJ16VYeT3EkQ11G681NGYV1JoCubZwrncX-2tCaVTaLFG65PKVL7ncGwjtms_vnJ7eBowA9lIbTYMfScZX76kub5mW2JQNWEvwR9-M9jJnfXmACAwioVk4Ag1-58a2hxuog3NDmjDai1_cKBz_zlULQCDq5_QxIskO1fNyS_9p9Dwj_cihFtL2ovec8H6vxZ9_MOlUUe9tJ4H94MWpRXOPKm79OMsbJPC2SiZ3AH4PWQdpqlkK5Q9SQHuldPgs-mD-7XcA1Gf394UFuqjmEVcWz-ecHfVHDXchFAPSGDBD4zt6AiSKodkISbm0xMeFvi3dLmpWM4BtZUsu3_gGM9ZKg7MsdObOBL9dcw2-0';

  @override
  void initState() {
    super.initState();
    _repo = makeCategoriesRepo();
    _future = _loadAll(); // load categories + all doc counts together
  }

  Future<List<Category>> _loadAll() async {
    // 1. Load categories
    final categories = await _repo.listFor(IdentityContext.current);

    // 2. Load Business docs meta.total
    _businessDocsCount = await _fetchDocsCountForEmail(
      'demo_ali@business.com',
    );

    // 3. Load Personnel docs meta.total
    _personnelDocsCount = await _fetchDocsCountForEmail(
      'demo_ali@personnel.com',
    );

    // 4. Load Access docs meta.total
    _accessDocsCount = await _fetchDocsCountForEmail(
      'demo_ali@access.com',
    );

    return categories;
  }

  Future<int?> _fetchDocsCountForEmail(String email) async {
    try {
      final uri = Uri.https(
        'nexus.uat.accredify.io',
        '/api/v1/documents/by_recipient',
        {
          'identifier_type': 'email',
          'identifier_value': email,
        },
      );

      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': _bearerToken,
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final meta = decoded['meta'] as Map<String, dynamic>?;
        final total = meta?['total'];

        final intCount =
            total is int ? total : int.tryParse(total?.toString() ?? '') ?? 0;

        return intCount;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            // Waiting for:
            // - categories
            // - business docs meta.total
            // - personnel docs meta.total
            // - access docs meta.total
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) return Center(child: Text('Failed: ${s.error}'));
          final items = s.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('No categories'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = items[i];
              final ui = _CategoryLook.from(c);

              final id = c.id.toLowerCase();
              final name = c.name.toLowerCase();
              final isBusiness =
                  id.contains('business') || name.contains('business');
              final isPersonnel =
                  id.contains('personnel') || name.contains('personnel');
              final isAccess =
                  id.contains('access') || name.contains('access') || id.contains('pass');

              // Override counts for nexus-backed categories
              final int? count;
              if (isBusiness) {
                count = _businessDocsCount ?? 0;
              } else if (isPersonnel) {
                count = _personnelDocsCount ?? 0;
              } else if (isAccess) {
                count = _accessDocsCount ?? 0;
              } else {
                count = c.count;
              }

              return _CategoryTile(
                color: ui.color,
                icon: ui.icon,
                title: c.name,
                subtitle: ui.subtitle,
                count: count,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DocumentsListPage(
                        categoryId: c.id,
                        categoryName: c.name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// ---------- Visuals & mapping ----------

class _CategoryTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final int? count;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (count != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(.14)),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryLook {
  final Color color;
  final IconData icon;
  final String subtitle;

  const _CategoryLook({
    required this.color,
    required this.icon,
    required this.subtitle,
  });

  /// Map well-known IDs/names to consistent visuals + short copy.
  factory _CategoryLook.from(Category c) {
    final id = c.id.toLowerCase();
    final name = c.name.toLowerCase();

    if (id.contains('business') || name.contains('business')) {
      return const _CategoryLook(
        color: Color(0xFFD4A52E), // gold-ish
        icon: CupertinoIcons.doc_chart_fill,
        subtitle: 'Licenses and permits',
      );
    }
    if (id.contains('personnel') || name.contains('personnel')) {
      return const _CategoryLook(
        color: Color(0xFF2EA043), // green
        icon: CupertinoIcons.person_crop_square_fill,
        subtitle: 'IDs, certificates, and personal documents',
      );
    }
    if (id.contains('access') || name.contains('access') || id.contains('pass')) {
      return const _CategoryLook(
        color: Color(0xFF2F6FEB), // blue
        icon: CupertinoIcons.tickets_fill,
        subtitle: 'Gate passes and facility access',
      );
    }
    // Fallback look
    return const _CategoryLook(
      color: Color(0xFF7B7F85),
      icon: CupertinoIcons.folder_fill,
      subtitle: 'Documents in this category',
    );
  }
}