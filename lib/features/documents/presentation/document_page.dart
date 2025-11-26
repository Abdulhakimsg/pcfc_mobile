// lib/features/documents/presentation/document_page.dart
//
// Deps: pdfx, qr_flutter, http
//
// This version:
// - Uses rawUrl + pdfUrl from parent (DocumentsListPage)
// - Parses RAW JSON to fill company / holder / license info
// - Reads document_issuer & document_name dynamically
// - Switches issuer logo based on document_issuer (Trakhees / JAFZA / default PCFC)
// - Renders the PDF from pdfUrl

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

class DocumentPage extends StatefulWidget {
  final String displayTitle; // e.g. "Commercial License"
  final String issuer;       // e.g. "Trakhees" (fallback)
  final String shareLink;
  final String? rawUrl;
  final String? pdfUrl;

  const DocumentPage({
    super.key,
    required this.displayTitle,
    required this.issuer,
    required this.shareLink,
    this.rawUrl,
    this.pdfUrl,
  });

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  Future<_DocData>? _future;
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

  String _untag(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final m = RegExp(r'^[^:]+:[^:]+:(.+)$').firstMatch(s);
    return m?.group(1) ?? s;
  }

  /// Simple Title Case helper
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

  /// Map issuer name -> logo asset path.
  /// Adjust these paths to match your project structure.
  String _issuerLogoAsset(String issuerName) {
    final n = issuerName.toLowerCase().trim();
    if (n.contains('jafza')) {
      // <- put your JAFZA logo here
      return 'assets/brand/jafza_logo.png';
    }
    if (n.contains('trakhees')) {
      return 'assets/brand/trakhees_logo.png';
    }
    // Fallback: PCFC / generic logo
    return 'assets/brand/pcfc_logo.webp';
  }

  // ── Load & parse from RAW + PDF URLs ───────────────────────────────────────
  Future<_DocData> _load() async {
    String companyName = '';
    String holderName = '';
    String memberRole = 'Owner';
    String licenseCategory = '';
    String legalType = '';

    String documentIssuer = '';
    String documentName = '';

    // 1) Read RAW JSON if provided
    if (widget.rawUrl != null && widget.rawUrl!.isNotEmpty) {
      try {
        final rawRes = await http.get(Uri.parse(widget.rawUrl!));
        if (rawRes.statusCode == 200) {
          final rawJson = jsonDecode(rawRes.body);

          Map<String, dynamic>? dataMap;
          if (rawJson is Map<String, dynamic>) {
            if (rawJson['data'] is Map<String, dynamic>) {
              dataMap = rawJson['data'] as Map<String, dynamic>;
            } else {
              dataMap = rawJson;
            }
          }

          if (dataMap != null) {
            companyName = _untag(
                  dataMap['company_name'] ??
                      dataMap['business_name'] ??
                      '',
                ) ??
                '';
            holderName = _untag(
                  dataMap['name'] ??
                      (dataMap['recipient'] is Map
                          ? (dataMap['recipient'] as Map)['name']
                          : null),
                ) ??
                '';

            licenseCategory = _untag(dataMap['license_category']) ?? '';
            legalType = _untag(dataMap['legal_type']) ?? '';

            if (dataMap['member_role'] != null) {
              memberRole = _untag(dataMap['member_role']);
            }

            // NEW: live document issuer / name
            documentIssuer = _untag(dataMap['document_issuer']);
            documentName = _untag(dataMap['document_name']);

            // Fallback issuer from issuers[0].name if document_issuer missing
            if (documentIssuer.isEmpty && dataMap['issuers'] is List) {
              final issuers = dataMap['issuers'] as List;
              if (issuers.isNotEmpty && issuers.first is Map) {
                documentIssuer =
                    _untag((issuers.first as Map<String, dynamic>)['name']);
              }
            }
          }
        }
      } catch (_) {
        // swallow; we'll use defaults
      }
    }

    // 2) Load the PDF from pdfUrl
    PdfController? controller;
    if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      try {
        final pdfRes = await http.get(Uri.parse(widget.pdfUrl!));
        if (pdfRes.statusCode == 200) {
          controller = PdfController(
            document: PdfDocument.openData(pdfRes.bodyBytes),
          );
        }
      } catch (_) {
        // ignore PDF error, show 'No PDF found'
      }
    }

    _pdf = controller;

    // Fallbacks / nice formatting
    if (companyName.isEmpty) {
      companyName = 'Trakhees Licensee';
    }
    if (holderName.isEmpty) {
      holderName = 'Authorised Signatory';
    }

    companyName = _toTitleCase(companyName);
    holderName = _toTitleCase(holderName);
    memberRole = _toTitleCase(memberRole);
    documentIssuer = documentIssuer.isEmpty
        ? _toTitleCase(widget.issuer)
        : _toTitleCase(documentIssuer);
    documentName = documentName.isEmpty
        ? _toTitleCase(widget.displayTitle)
        : _toTitleCase(documentName);

    return _DocData(
      companyName: companyName,
      holderName: holderName,
      memberRole: memberRole,
      licenseCategory: licenseCategory,
      legalType: legalType,
      documentIssuer: documentIssuer,
      documentName: documentName,
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
                        'For OnePass Scan',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
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
      content: Text(
        'Sent to PCFC for attestation. Attested document will be in your registered e-mail within the next 15 minutes.',
      ),
    ));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1E34),
      body: FutureBuilder<_DocData>(
        future: _future,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(child: Text('Failed to load: ${s.error}'));
          }
          final doc = s.data!;

          final issuerName = doc.documentIssuer;
          final docName = doc.documentName;
          final logoAsset = _issuerLogoAsset(issuerName);

          return Scaffold(
            backgroundColor: const Color(0xFF0B1E34),
            appBar: AppBar(title: Text(docName)),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // — Header: Text on left, issuer logo on right — //
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
                          children: [
                            Text(
                              'Document is issued by $issuerName',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
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
                      // Right: issuer logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          logoAsset,
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
                    textAlign: TextAlign.center, // center the two lines
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.45,
                      ),
                      children: [
                        const TextSpan(
                          text: 'This ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: docName.toLowerCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text: ' belongs to ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: doc.companyName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          // line break after first sentence
                          text: '.\n\n',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: doc.holderName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text: ' is registered as ',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: doc.memberRole,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
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
                      _InfoRow(label: 'Recipient Name', value: doc.holderName),
                      _InfoRow(label: 'Role in Company', value: doc.memberRole),
                      if (doc.licenseCategory.isNotEmpty)
                        _InfoRow(
                          label: 'License Category',
                          value: doc.licenseCategory,
                        ),
                      if (doc.legalType.isNotEmpty)
                        _InfoRow(
                          label: 'Legal Type',
                          value: doc.legalType,
                        ),
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
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  height: 520,
                  clipBehavior: Clip.antiAlias,
                  child: doc.pdf == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No PDF found'),
                          ),
                        )
                      : PdfView(
                          controller: doc.pdf!,
                          scrollDirection: Axis.vertical,
                          pageSnapping: false,
                        ),
                ),

                const SizedBox(height: 12),

                // — Primary action: Send to PCFC (helper text inside) — //
                SizedBox(
                  height: 68,
                  child: ElevatedButton(
                    onPressed: (_attesting || _attested)
                        ? null
                        : _sendToPcfcForAttestation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6FEB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                              mainAxisSize: MainAxisSize.min,
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
                                const Text(
                                  'Attest document now',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
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
                    onPressed: () => _openShareQr(widget.shareLink),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Present for OnePass Scan'),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary: Download
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => _openShareQr(widget.shareLink),
                    icon: const Icon(Icons.file_download),
                    label: const Text('Download Credential'),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Reusable UI atoms ───────────────────────────────────────────────────────
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
class _DocData {
  final String companyName;
  final String holderName;
  final String memberRole;
  final String licenseCategory;
  final String legalType;
  final String documentIssuer;
  final String documentName;
  final PdfController? pdf;

  _DocData({
    required this.companyName,
    required this.holderName,
    required this.memberRole,
    required this.licenseCategory,
    required this.legalType,
    required this.documentIssuer,
    required this.documentName,
    required this.pdf,
  });
}