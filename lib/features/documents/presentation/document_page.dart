// lib/features/documents/presentation/document_page.dart
//
// Deps: pdfx, qr_flutter, http
//
// This version:
// - Uses rawUrl + pdfUrl from parent (DocumentsListPage)
// - Parses RAW JSON to fill fields for both Business & Personnel docs
// - For Personnel docs (document_type == "Personnel"):
//   * issuer = additionalData.document_issuer ("Maersk Training")
//   * holder = recipient.name ("M Ali")
//   * Important Details only shows Recipient Name + Issuer
// - For Business docs, keeps your existing behaviour
// - Switches issuer logo based on document_issuer (Trakhees / JAFZA / Maersk / default PCFC)
// - Renders the PDF from pdfUrl and sizes the card using the PDF page aspect ratio
//   so landscape certificates don’t leave extra vertical whitespace.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

class DocumentPage extends StatefulWidget {
  final String displayTitle; // e.g. "Commercial License" / "Safety Training Level 1"
  final String issuer; // fallback issuer
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
  String _issuerLogoAsset(String issuerName) {
    final n = issuerName.toLowerCase().trim();

    if (n.contains('maersk')) {
      // Maersk Training logo
      return 'assets/brand/maersk_logo.jpg';
    }
    if (n.contains('jafza')) {
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
    String documentType = '';
    String recipientEmail = '';

    double? pageAspect; // width / height of first PDF page

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
            // additionalData (Personnel / custom fields)
            final additional = dataMap['additionalData'];
            if (additional is Map<String, dynamic>) {
              final dt = additional['document_type'];
              final dn = additional['document_name'];
              final di = additional['document_issuer'];

              if (dt is String && dt.isNotEmpty) {
                documentType = _untag(dt);
              }
              if (dn is String && dn.isNotEmpty) {
                documentName = _untag(dn);
              }
              if (di is String && di.isNotEmpty) {
                documentIssuer = _untag(di);
              }
            }

            // Company (business docs)
            companyName = _untag(
              dataMap['company_name'] ?? dataMap['business_name'] ?? '',
            );

            // Recipient (for Personnel docs we want this as holder)
            final recipient = dataMap['recipient'];
            if (recipient is Map<String, dynamic>) {
              final rn = recipient['name'];
              final re = recipient['email'];
              if (rn != null) {
                holderName = _untag(rn);
              }
              if (re != null) {
                recipientEmail = _untag(re);
              }
            }

            // If still no holder name, fall back to other fields
            if (holderName.isEmpty) {
              final candidateHolder = dataMap['holder_name'] ?? dataMap['name'];
              holderName = _untag(candidateHolder);
            }

            // Business-specific fields
            licenseCategory = _untag(dataMap['license_category']);
            legalType = _untag(dataMap['legal_type']);
            if (dataMap['member_role'] != null) {
              memberRole = _untag(dataMap['member_role']);
            }

            // document_issuer & document_name from top-level if not set
            if (documentIssuer.isEmpty && dataMap['document_issuer'] != null) {
              documentIssuer = _untag(dataMap['document_issuer']);
            }
            if (documentName.isEmpty && dataMap['document_name'] != null) {
              documentName = _untag(dataMap['document_name']);
            }

            // Fallback issuer from issuers[0].name if still missing
            if (documentIssuer.isEmpty && dataMap['issuers'] is List) {
              final issuers = dataMap['issuers'] as List;
              if (issuers.isNotEmpty && issuers.first is Map) {
                documentIssuer = _untag(
                  (issuers.first as Map<String, dynamic>)['name'],
                );
              }
            }

            // Final fallback for docName: top-level "name"
            if (documentName.isEmpty && dataMap['name'] != null) {
              documentName = _untag(dataMap['name']);
            }
          }
        }
      } catch (_) {
        // swallow; we'll use defaults
      }
    }

// 2) Load the PDF from pdfUrl and compute aspect ratio
PdfController? controller;
if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
  try {
    final pdfRes = await http.get(Uri.parse(widget.pdfUrl!));
    if (pdfRes.statusCode == 200) {
      // PdfController expects a Future<PdfDocument>
      final docFuture = PdfDocument.openData(pdfRes.bodyBytes);

      // Use the resolved document once to compute aspect ratio
      try {
        final pdfDoc = await docFuture;
        final firstPage = await pdfDoc.getPage(1);
        final w = firstPage.width;
        final h = firstPage.height;
        if (w != null && h != null && h != 0) {
          pageAspect = w / h; // width / height
        }
        await firstPage.close();
      } catch (_) {
        // ignore, we'll fall back later
      }

      // Pass the Future<PdfDocument> into the controller
      controller = PdfController(document: docFuture);
    }
  } catch (_) {
    // ignore PDF error, show 'No PDF found'
  }
}

    _pdf = controller;

    // Determine if this is a Personnel credential
    final isPersonnel = documentType.toLowerCase().trim() == 'personnel';

    // Fallbacks / nice formatting
    if (companyName.isEmpty && !isPersonnel) {
      companyName = 'Trakhees Licensee';
    }

    if (holderName.isEmpty) {
      holderName = 'Authorised Signatory';
    }

    // Title-case the human-facing labels
    companyName = _toTitleCase(companyName);
    holderName = _toTitleCase(holderName);
    memberRole = _toTitleCase(memberRole);
    licenseCategory = _toTitleCase(licenseCategory);
    legalType = _toTitleCase(legalType);
    documentIssuer = documentIssuer.isEmpty
        ? _toTitleCase(widget.issuer)
        : _toTitleCase(documentIssuer);
    documentName = documentName.isEmpty
        ? _toTitleCase(widget.displayTitle)
        : _toTitleCase(documentName);
    documentType = _toTitleCase(documentType);

    return _DocData(
      companyName: companyName,
      holderName: holderName,
      memberRole: memberRole,
      licenseCategory: licenseCategory,
      legalType: legalType,
      documentIssuer: documentIssuer,
      documentName: documentName,
      documentType: documentType,
      recipientEmail: recipientEmail,
      isPersonnel: isPersonnel,
      pageAspect: pageAspect,
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
                    textAlign: TextAlign.center,
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
                          text: doc.isPersonnel
                              ? doc.holderName
                              : doc.companyName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
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
                          text:
                              doc.isPersonnel ? 'Recipient' : doc.memberRole,
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

                      // Personnel: only Recipient Name + Issuer
                      if (doc.isPersonnel) ...[
                        _InfoRow(
                          label: 'Recipient Name',
                          value: doc.holderName,
                        ),
                        _InfoRow(
                          label: 'Issuer',
                          value: doc.documentIssuer,
                        ),
                      ] else ...[
                        _InfoRow(
                          label: 'Company',
                          value: doc.companyName,
                        ),
                        _InfoRow(
                          label: 'Recipient Name',
                          value: doc.holderName,
                        ),
                        _InfoRow(
                          label: 'Role in Company',
                          value: doc.memberRole,
                        ),
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
                      ],
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
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: doc.pdf == null
                      ? const SizedBox(
                          height: 220,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No PDF found'),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Fallback: A4 portrait ~ 1/1.414
                            final aspect =
                                doc.pageAspect ?? (1 / 1.41421356237);

                            return Center(
                              child: AspectRatio(
                                aspectRatio: aspect,
                                child: PdfView(
                                  controller: doc.pdf!,
                                  scrollDirection: Axis.vertical,
                                  pageSnapping: false,
                                ),
                              ),
                            );
                          },
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
  final String documentType;
  final String recipientEmail;
  final bool isPersonnel;
  final double? pageAspect; // width / height of first page
  final PdfController? pdf;

  _DocData({
    required this.companyName,
    required this.holderName,
    required this.memberRole,
    required this.licenseCategory,
    required this.legalType,
    required this.documentIssuer,
    required this.documentName,
    required this.documentType,
    required this.recipientEmail,
    required this.isPersonnel,
    required this.pageAspect,
    required this.pdf,
  });
}