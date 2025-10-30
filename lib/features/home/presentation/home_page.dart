import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../categories/presentation/categories_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _HomeContent(),
      Center(child: Text('Payments')),
      Center(child: Text('History')),
      Center(child: Text('Profile')),
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
          // Turn off the default wide pill so we can show our own square highlight
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: Colors.black.withOpacity(0.55),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(color: isSelected ? Colors.white : Colors.white.withOpacity(0.85));
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
              // Do nothing (disabled). Optional toast:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            }
          },
          destinations: [
            NavigationDestination(
              // Normal icon when not selected
              icon: const Icon(CupertinoIcons.house_fill),
              // Square gold background when selected
              selectedIcon: _GoldSquareIcon(child: const Icon(CupertinoIcons.house_fill, color: Colors.white, size: 22)),
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
      width: 36, // square
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(8), // square (not a wide pill)
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
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppTheme.gL, AppTheme.gL, AppTheme.gL, 110 + bottomPad),
      child: Column(
        children: [
          const _IdentityHeaderCard(),
          const SizedBox(height: AppTheme.gXL),
          _ActionTile(
            color: AppTheme.brandGreen,
            icon: CupertinoIcons.plus_circled,
            title: 'View Documents',
            subtitle: 'View all official documents issued to you',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesListPage()),
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
  const _IdentityHeaderCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.rL),
      child: Stack(
        children: [
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: const SizedBox()),
          Container(
            padding: const EdgeInsets.all(AppTheme.gL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(.06), Colors.white.withOpacity(.03)],
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
                          child: const Icon(CupertinoIcons.person_crop_circle, size: 48, color: Colors.white),
                        ),
                        Positioned(
                          right: -2, bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.brandGreen, shape: BoxShape.circle,
                              border: Border.all(color: Colors.black.withOpacity(.2)),
                            ),
                            child: const Icon(CupertinoIcons.check_mark, size: 14, color: Colors.white),
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
                              Icon(CupertinoIcons.shield_lefthalf_fill, size: 16, color: Colors.white70),
                              SizedBox(width: 6),
                              Text('Digital Identity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text('ONE PASS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.gM),
                const Text('MOHAMMAD ALI',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: .6)),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: AppTheme.brandGreen),
                    SizedBox(width: 6),
                    Text('Verified Account', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: AppTheme.gL),
                Row(
                  children: const [
                    Expanded(child: _StatPill(label: 'Signature', value: '0', icon: CupertinoIcons.doc_text_fill)),
                    SizedBox(width: AppTheme.gL),
                    Expanded(child: _StatPill(label: 'Documents', value: '3', icon: CupertinoIcons.doc_on_doc_fill)),
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
  const _StatPill({super.key, required this.label, required this.value, required this.icon});

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
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(label,
                  style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 12, fontWeight: FontWeight.w500)),
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
  const _PrimaryButton({super.key, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Colors.white),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label,
                maxLines: 2,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
                decoration: BoxDecoration(color: color.withOpacity(.9), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Colors.white.withOpacity(.85), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}