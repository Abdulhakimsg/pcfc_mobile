import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _repo = makeCategoriesRepo();
    _future = _repo.listFor(IdentityContext.current);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
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

              return _CategoryTile(
                color: ui.color,
                icon: ui.icon,
                title: c.name,
                subtitle: ui.subtitle,
                count: c.count,
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
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
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(CupertinoIcons.chevron_right,
                  color: Colors.white70, size: 18),
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

    if (id.contains('trade') || name.contains('trade')) {
      return const _CategoryLook(
        color: Color(0xFFD4A52E), // gold-ish
        icon: CupertinoIcons.doc_chart_fill,
        subtitle: 'Company licences, activities & renewals',
      );
    }
    if (id.contains('person') || name.contains('person')) {
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