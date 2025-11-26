import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../app/theme.dart';
import '../../categories/presentation/categories_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  int? _documentsCount;
  bool _loadingDocuments = false;

  @override
  void initState() {
    super.initState();
    _fetchDocumentsCount();
  }

  Future<void> _fetchDocumentsCount() async {
    setState(() => _loadingDocuments = true);
    try {
      final uri = Uri.parse(
        'https://nexus.uat.accredify.io/api/v1/documents/by_recipient?identifier_value=Test%20Ali&identifier_type=name',
      );

      final res = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Authorization':
              'Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJhMDQ0N2NmZC00ZmFkLTRlMDctYTAwMS0wNmUxMDU2ZWMzOWMiLCJqdGkiOiJlZTk1YzUxZTJjYTBmOGFkODAxMjg5YzQ3OTA1MGE1YzdmOTc4ZWM5MmYxNzRiOWRlMzkyYWU4NGY0NTdlZTRiMmU3MTYxZDRlZjlmOTg5NiIsImlhdCI6MTc2MjMzNTYwOC4yNTc4NTcsIm5iZiI6MTc2MjMzNTYwOC4yNTc4NjEsImV4cCI6MTc5Mzg3MTYwOC4yNDQ4Mywic3ViIjoiIiwic2NvcGVzIjpbInJ1bi13b3JrZmxvdyIsIndlYmNvbXBvbmVudC12ZXJpZmljYXRpb24iLCJ2ZXJpZmljYXRpb24tc3VpdGUiLCJ3b3JrZmxvd3M6cmVhZCIsIndvcmtmbG93LXJ1bnM6cmVhZCIsImRvY3VtZW50czpyZWFkIiwiZG9jdW1lbnRzOndyaXRlIiwiY3VzdG9tLXZpZXdzOnJlYWQiLCJ1c2VyczpyZWFkIiwiZGVzaWduLXRlbXBsYXRlczpyZWFkIiwiZG9jdW1lbnQtdGVtcGxhdGVzOnJlYWQiLCJncm91cHM6cmVhZCIsImNvdXJzZXM6cmVhZCIsImNvdXJzZXM6d3JpdGUiXX0.YOQACJ_J8A8RN7G_UJUtJaDIvbmPkLfc_RTzsnkbdqZxWzEA4Y9IZsTBZbEXmLkeWErGOM60R-_yBF0n9jNlVLQVDpmlf2DnGzK5G9lTZUO48Y_VwDnA4qbr52Gc2HIueTmBEZBrl_-5Hg-hIhdlcRmnVxsUmCPM8s_2RpM9M_0-dPt1_C1UrJ9Ce0eicRdH7S03od4cPgWx9HMoTg3olElRnhA0kehcZA_FXkZGxBL7ybE1lJ9wUUKp2Aszb-VLV0MtLqtEZrZhiTObESOdCSdQWWmMSySXw_UnaMDei1rMlhORNYvejXyb7QCOG7QvJJA-dJ16VYeT3EkQ11G681NGYV1JoCubZwrncX-2tCaVTaLFG65PKVL7ncGwjtms_vnJ7eBowA9lIbTYMfScZX76kub5mW2JQNWEvwR9-M9jJnfXmACAwioVk4Ag1-58a2hxuog3NDmjDai1_cKBz_zlULQCDq5_QxIskO1fNyS_9p9Dwj_cihFtL2ovec8H6vxZ9_MOlUUe9tJ4H94MWpRXOPKm79OMsbJPC2SiZ3AH4PWQdpqlkK5Q9SQHuldPgs-mD-7XcA1Gf394UFuqjmEVcWz-ecHfVHDXchFAPSGDBD4zt6AiSKodkISbm0xMeFvi3dLmpWM4BtZUsu3_gGM9ZKg7MsdObOBL9dcw2-0',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final meta = decoded['meta'] as Map<String, dynamic>?;
        final total = meta?['total'];

        final intCount = total is int
            ? total
            : int.tryParse(total?.toString() ?? '') ?? 0;

        if (mounted) {
          setState(() {
            _documentsCount = intCount;
          });
        }
      } else {
        // Optional: log or handle non-200 status
      }
    } catch (_) {
      // Optional: log the error
    } finally {
      if (mounted) {
        setState(() => _loadingDocuments = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeContent(
        // Only source of truth is meta.total from the endpoint
        documentsCount:
            _documentsCount?.toString() ?? (_loadingDocuments ? '...' : '0'),
      ),
      const Center(child: Text('Payments')),
      const Center(child: Text('History')),
      const Center(child: Text('Profile')),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1E34),
      extendBody: true,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(child: IndexedStack(index: _index, children: pages)),
        ],
      ),

      // --- Native M3 NavigationBar with square gold icon highlight, Home only clickable ---
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: Colors.black.withOpacity(0.55),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              color:
                  isSelected ? Colors.white : Colors.white.withOpacity(0.85),
            );
          }),
        ),
        child: NavigationBar(
          height: 70,
          elevation: 0,
          selectedIndex: _index,
          onDestinationSelected: (i) {
            if (i == 0) {
              setState(() => _index = 0);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(CupertinoIcons.house_fill),
              selectedIcon: _GoldSquareIcon(
                child: const Icon(
                  CupertinoIcons.house_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(CupertinoIcons.creditcard),
              selectedIcon: Icon(CupertinoIcons.creditcard),
              label: 'Payments',
            ),
            const NavigationDestination(
              icon: Icon(CupertinoIcons.clock),
              selectedIcon: Icon(CupertinoIcons.clock),
              label: 'History',
            ),
            const NavigationDestination(
              icon: Icon(CupertinoIcons.person_fill),
              selectedIcon: Icon(CupertinoIcons.person_fill),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldSquareIcon extends StatelessWidget {
  final Widget child;
  const _GoldSquareIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1E34),
            Color(0xFF172C47),
            Color(0xFF214263),
          ],
        ),
      ),
    );
  }
}

/// ===== HOME CONTENT =====
class _HomeContent extends StatelessWidget {
  final String documentsCount;
  const _HomeContent({required this.documentsCount});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppTheme.gL,
        AppTheme.gL,
        AppTheme.gL,
        110 + bottomPad,
      ),
      child: Column(
        children: [
          _IdentityHeaderCard(documentsCount: documentsCount),
          const SizedBox(height: AppTheme.gXL),
          _ActionTile(
            color: AppTheme.brandGreen,
            icon: CupertinoIcons.plus_circled,
            title: 'View Documents',
            subtitle: 'View all official documents issued to you',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoriesListPage(),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.gL),
          _ActionTile(
            color: AppTheme.brandBlue,
            icon: CupertinoIcons.qrcode_viewfinder,
            title: 'Scan QR Code',
            subtitle: 'Use your camera',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan QR not implemented')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IdentityHeaderCard extends StatelessWidget {
  final String documentsCount;
  const _IdentityHeaderCard({required this.documentsCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.rL),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: const SizedBox(),
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.gL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(.06),
                  Colors.white.withOpacity(.03),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(.08)),
              borderRadius: BorderRadius.circular(AppTheme.rL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(.10),
                          child: const Icon(
                            CupertinoIcons.person_crop_circle,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.brandGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withOpacity(.2),
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.check_mark,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppTheme.gL),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                CupertinoIcons.shield_lefthalf_fill,
                                size: 16,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Digital Identity',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ONE PASS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.gM),
                const Text(
                  'MOHAMMAD ALI',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 16,
                      color: AppTheme.brandGreen,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Verified Account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.gL),
                Row(
                  children: [
                    const Expanded(
                      child: _StatPill(
                        label: 'Signature',
                        value: '0',
                        icon: CupertinoIcons.doc_text_fill,
                      ),
                    ),
                    const SizedBox(width: AppTheme.gL),
                    Expanded(
                      child: _StatPill(
                        label: 'Documents',
                        value: documentsCount,
                        icon: CupertinoIcons.doc_on_doc_fill,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.gL),
                Row(
                  children: const [
                    Expanded(
                      child: _PrimaryButton(
                        label: 'Sign\nDocuments',
                        color: AppTheme.gold,
                        icon: CupertinoIcons.pencil_ellipsis_rectangle,
                      ),
                    ),
                    SizedBox(width: AppTheme.gL),
                    Expanded(
                      child: _PrimaryButton(
                        label: 'Verify\nSignature',
                        color: AppTheme.brandBlue,
                        icon: CupertinoIcons.shield_fill,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatPill({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.white70),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
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