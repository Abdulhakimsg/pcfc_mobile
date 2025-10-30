// lib/features/home/presentation/home_page.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// adjust paths if your folders differ
import '../../../app/theme.dart';
import '../../../core/identity/identity.dart';
import '../../documents/presentation/documents_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(IdentityContext.current.name),
      ),
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [AppTheme.bgTop, AppTheme.bgMid, AppTheme.bgBottom],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.gL),
              child: Column(
                children: [
                  const _IdentityHeaderCard(),
                  const SizedBox(height: AppTheme.gXL),

                  // Add Documents → goes to documents list (mock/api behind repo)
                  _ActionTile(
                    color: AppTheme.brandGreen,
                    icon: CupertinoIcons.plus_circled,
                    title: 'Add Documents',
                    subtitle: 'Request official documents from an issuer',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DocumentsListPage()),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.gL),

                  // Scan QR → stub for now
                  _ActionTile(
                    color: AppTheme.brandBlue,
                    icon: CupertinoIcons.qrcode_viewfinder,
                    title: 'Scan QR Code',
                    subtitle: 'Use your camera to start document sharing',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scan QR (to be implemented)')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ====== UI bits (compact, matches your screenshot style) ======

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
                            decoration: BoxDecoration(
                              color: AppTheme.brandGreen, shape: BoxShape.circle,
                              border: Border.all(color: Colors.black.withOpacity(.2)),
                            ),
                            padding: const EdgeInsets.all(4),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MOHAMMAD ALI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: .6)),
                      SizedBox(height: 6),
                      _VerifiedRow(),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.gL),
                Row(
                  children: const [
                    Expanded(child: _StatPill(label: 'Signature', value: '4', icon: CupertinoIcons.doc_text_fill)),
                    SizedBox(width: AppTheme.gL),
                    Expanded(child: _StatPill(label: 'Documents', value: '12', icon: CupertinoIcons.doc_on_doc_fill)),
                  ],
                ),
                const SizedBox(height: AppTheme.gL),
                Row(
                  children: const [
                    Expanded(child: _PrimaryButton(label: 'Sign\nDocuments', color: AppTheme.gold, icon: CupertinoIcons.pencil_ellipsis_rectangle)),
                    SizedBox(width: AppTheme.gL),
                    Expanded(child: _PrimaryButton(label: 'Verify\nSignature', color: AppTheme.brandBlue, icon: CupertinoIcons.shield_fill)),
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

class _VerifiedRow extends StatelessWidget {
  const _VerifiedRow();
  @override
  Widget build(BuildContext context) => Row(
    children: const [
      Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: AppTheme.brandGreen),
      SizedBox(width: 6),
      Text('Verified Account', style: TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatPill({super.key, required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
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
          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _PrimaryButton({super.key, required this.label, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
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
        Flexible(child: Text(label, maxLines: 2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Container(
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
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(.9), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 13, fontWeight: FontWeight.w500)),
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