// lib/features/documents/presentation/commercial_license_mock_page.dart
// Assets (pubspec):
//  - assets/brand/trakhees_logo.png
//  - assets/brand/pcfc_logo.webp
//  - assets/mock/commercial_license.json
// Deps: pdfx, qr_flutter

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CommercialLicenseMockPage extends StatefulWidget {
  const CommercialLicenseMockPage({super.key});

  @override
  State<CommercialLicenseMockPage> createState() =>
      _CommercialLicenseMockPageState();
}

class _CommercialLicenseMockPageState extends State<CommercialLicenseMockPage> {
  Future<_MockDoc>? _future;
  PdfController? _pdf;
  bool _attesting = false;
  bool _attested = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _pdf?.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _untag(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final m = RegExp(r'^[^:]+:[^:]+:(.+)$').firstMatch(s);
    return m?.group(1) ?? s;
  }

  String _stripDataUrlHeader(String s) {
    if (!s.startsWith('data:')) return s;
    final i = s.indexOf(',');
    return i >= 0 ? s.substring(i + 1) : s;
  }

  // ── Load & parse ───────────────────────────────────────────────────────────
  Future<_MockDoc> _load() async {
    final raw =
        await rootBundle.loadString('assets/mock/commercial_license.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final data = (json['data'] as Map<String, dynamic>);

    final companyName = _untag(data['company_name']);
    final memberName = _untag(data['member_name']);
    final memberRole = _untag(data['member_role']);

    final add = (data['additionalData'] as Map<String, dynamic>?);
    final shareLink = _untag(add?['shareLink']);

    final pdfRaw = _untag(add?['pdf']);
    final b64 = _stripDataUrlHeader(pdfRaw);
    Uint8List bytes = Uint8List(0);
    if (b64.isNotEmpty) bytes = base64Decode(b64);

    PdfController? controller;
    if (bytes.isNotEmpty) {
      controller = PdfController(document: PdfDocument.openData(bytes));
    }
    _pdf = controller;

    return _MockDoc(
      companyName: companyName,
      memberName: memberName,
      memberRole: memberRole,
      shareLink: shareLink,
      pdf: controller,
    );
  }

  // ── Share QR ───────────────────────────────────────────────────────────────
  void _openShareQr(String link) {
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No share link available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white.withOpacity(.92),
      barrierColor: Colors.black.withOpacity(.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final qrMaxByWidth = (w - 32).clamp(160.0, 340.0);
              final qrMaxByHeight = (h - 230).clamp(140.0, 340.0);
              final qrSize = math.min(qrMaxByWidth, qrMaxByHeight);

              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Share Document',
                        style:
                            TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: QrImageView(
                          data: link,
                          version: QrVersions.auto,
                          size: qrSize,
                          gapless: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Simulated attestation action
  Future<void> _sendToPcfcForAttestation() async {
    if (_attesting || _attested) return;
    setState(() => _attesting = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _attesting = false;
      _attested = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content:
          Text('Sent to PCFC for attestation. Attested document will be in your registered e-mail within the next 15 minutes.'),
    ));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E34),
      appBar: AppBar(title: const Text('Commercial License')),
      body: FutureBuilder<_MockDoc>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(child: Text('Failed to load: ${s.error}'));
          }
          final doc = s.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // — Header: Text on left, Trakhees logo on right — //
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F0),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: headline & sub
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Document is issued by Trakhees',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'The information in this document is verified and up-to-date.',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right: Trakhees logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/brand/trakhees_logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),

              // — Human statement — //
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(
                          text: 'This commercial license belongs to ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      TextSpan(
                          text: doc.companyName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(
                          text: '. ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      TextSpan(
                          text: doc.memberName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(
                          text: ' is registered as ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      TextSpan(
                          text: doc.memberRole,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),

              // — Important Details — //
              Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    const Text(
                      'Important Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Divider(color: Colors.white.withOpacity(0.10), height: 1),
                    _InfoRow(label: 'Company', value: doc.companyName),
                    _InfoRow(label: 'Recipient Name', value: doc.memberName),
                    _InfoRow(label: 'Role in Company', value: doc.memberRole),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // — Certificate (PDF) — //
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12))
                  ],
                ),
                height: 520,
                clipBehavior: Clip.antiAlias,
                child: doc.pdf == null
                    ? const Center(
                        child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No PDF found')))
                    : PdfView(
                        controller: doc.pdf!,
                        scrollDirection: Axis.vertical,
                        pageSnapping: false,
                      ),
              ),

              const SizedBox(height: 12),

              // — Primary action: Send to PCFC (helper text inside) — //
              SizedBox(
                height: 68, // ↑ allow two compact lines without overflow
                child: ElevatedButton(
                  onPressed:
                      (_attesting || _attested) ? null : _sendToPcfcForAttestation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6FEB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/brand/pcfc_logo.webp',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(height: 1.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min, // ← key
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attested
                                    ? 'Sent to PCFC for Attestation'
                                    : _attesting
                                        ? 'Sending to PCFC for Attestation…'
                                        : 'Send to PCFC for Attestation',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Attest document now',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE9F0FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_attesting) const SizedBox(width: 12),
                      if (_attesting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Secondary: Share
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => _openShareQr(doc.shareLink),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share securely'),
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Reusable UI atoms ────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model ───────────────────────────────────────────────────────────────────
class _MockDoc {
  final String companyName;
  final String memberName;
  final String memberRole;
  final String shareLink;
  final PdfController? pdf;
  _MockDoc({
    required this.companyName,
    required this.memberName,
    required this.memberRole,
    required this.shareLink,
    required this.pdf,
  });
}