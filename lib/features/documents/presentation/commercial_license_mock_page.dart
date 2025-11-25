// lib/features/documents/presentation/commercial_license_mock_page.dart
// Deps: pdfx, qr_flutter, http
//
// This version:
// - Calls the real Nexus API
// - Takes the first object in "data"
// - Uses the "presentation"/"pdf" file URL for the PDF
// - Tries to read company/member data from the RAW JSON

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

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

  // ── Config ─────────────────────────────────────────────────────────────────
  static const _baseUrl = 'https://nexus.uat.accredify.io/api/v1';
  static const _workflowUuid = 'a03c899e-7a44-473a-acdd-4329aa8097f8';

  // ⚠️ Replace this with your real token (and store it safely)
  static const _bearerToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJhMDQ0N2NmZC00ZmFkLTRlMDctYTAwMS0wNmUxMDU2ZWMzOWMiLCJqdGkiOiJlZTk1YzUxZTJjYTBmOGFkODAxMjg5YzQ3OTA1MGE1YzdmOTc4ZWM5MmYxNzRiOWRlMzkyYWU4NGY0NTdlZTRiMmU3MTYxZDRlZjlmOTg5NiIsImlhdCI6MTc2MjMzNTYwOC4yNTc4NTcsIm5iZiI6MTc2MjMzNTYwOC4yNTc4NjEsImV4cCI6MTc5Mzg3MTYwOC4yNDQ4Mywic3ViIjoiIiwic2NvcGVzIjpbInJ1bi13b3JrZmxvdyIsIndlYmNvbXBvbmVudC12ZXJpZmljYXRpb24iLCJ2ZXJpZmljYXRpb24tc3VpdGUiLCJ3b3JrZmxvd3M6cmVhZCIsIndvcmtmbG93LXJ1bnM6cmVhZCIsImRvY3VtZW50czpyZWFkIiwiZG9jdW1lbnRzOndyaXRlIiwiY3VzdG9tLXZpZXdzOnJlYWQiLCJ1c2VyczpyZWFkIiwiZGVzaWduLXRlbXBsYXRlczpyZWFkIiwiZG9jdW1lbnQtdGVtcGxhdGVzOnJlYWQiLCJncm91cHM6cmVhZCIsImNvdXJzZXM6cmVhZCIsImNvdXJzZXM6d3JpdGUiXX0.YOQACJ_J8A8RN7G_UJUtJaDIvbmPkLfc_RTzsnkbdqZxWzEA4Y9IZsTBZbEXmLkeWErGOM60R-_yBF0n9jNlVLQVDpmlf2DnGzK5G9lTZUO48Y_VwDnA4qbr52Gc2HIueTmBEZBrl_-5Hg-hIhdlcRmnVxsUmCPM8s_2RpM9M_0-dPt1_C1UrJ9Ce0eicRdH7S03od4cPgWx9HMoTg3olElRnhA0kehcZA_FXkZGxBL7ybE1lJ9wUUKp2Aszb-VLV0MtLqtEZrZhiTObESOdCSdQWWmMSySXw_UnaMDei1rMlhORNYvejXyb7QCOG7QvJJA-dJ16VYeT3EkQ11G681NGYV1JoCubZwrncX-2tCaVTaLFG65PKVL7ncGwjtms_vnJ7eBowA9lIbTYMfScZX76kub5mW2JQNWEvwR9-M9jJnfXmACAwioVk4Ag1-58a2hxuog3NDmjDai1_cKBz_zlULQCDq5_QxIskO1fNyS_9p9Dwj_cihFtL2ovec8H6vxZ9_MOlUUe9tJ4H94MWpRXOPKm79OMsbJPC2SiZ3AH4PWQdpqlkK5Q9SQHuldPgs-mD-7XcA1Gf394UFuqjmEVcWz-ecHfVHDXchFAPSGDBD4zt6AiSKodkISbm0xMeFvi3dLmpWM4BtZUsu3_gGM9ZKg7MsdObOBL9dcw2-0';

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

  // ── Load & parse from Nexus API ────────────────────────────────────────────
  Future<_MockDoc> _load() async {
    // 1. Call documents API (first page, filtered by workflow_uuid)
    final uri = Uri.parse(
        '$_baseUrl/documents?workflow_uuid=$_workflowUuid&page=1');

    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_bearerToken',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load documents: ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final dataList = (json['data'] as List<dynamic>? ?? const []);
    if (dataList.isEmpty) {
      throw Exception('No documents in response');
    }

    // 2. Take the first object in "data"
    final docJson = dataList.first as Map<String, dynamic>;

    final docShareLink = docJson['share_link'] as String? ?? '';

    final recipient = docJson['recipient'] as Map<String, dynamic>?;
    String memberName = recipient?['name'] as String? ?? '';

    // 3. Extract file URLs: prefer "presentation", fallback to "pdf" and "raw"
    final files = (docJson['files'] as List<dynamic>? ?? const []);
    String? pdfUrl;
    String? rawUrl;

    for (final f in files) {
      final m = f as Map<String, dynamic>;
      final label = m['label'] as String? ?? '';
      final url = m['url'] as String? ?? '';
      if (label == 'presentation' && pdfUrl == null) {
        pdfUrl = url;
      } else if (label == 'pdf' && pdfUrl == null) {
        pdfUrl = url;
      } else if (label == 'raw' && rawUrl == null) {
        rawUrl = url;
      }
    }

    // 4. Try to pull company_name / member_role from RAW JSON (if available)
    String companyName = '';
    String memberRole = '';

    if (rawUrl != null && rawUrl.isNotEmpty) {
      final rawRes = await http.get(Uri.parse(rawUrl));
      if (rawRes.statusCode == 200) {
        final rawJson = jsonDecode(rawRes.body);

        Map<String, dynamic>? dataMap;

        if (rawJson is Map<String, dynamic>) {
          // If the raw structure is { "data": { ... } } (like your old mock)
          if (rawJson['data'] is Map<String, dynamic>) {
            dataMap = rawJson['data'] as Map<String, dynamic>;
          } else {
            dataMap = rawJson;
          }
        }

        if (dataMap != null) {
          companyName = _untag(dataMap['company_name']);
          memberRole = _untag(dataMap['member_role']);

          // If member name is empty from recipient, try from raw
          if (memberName.isEmpty) {
            memberName = _untag(dataMap['member_name']);
          }

          // If share link is empty from top-level, try the old additionalData path
          final add = dataMap['additionalData'] as Map<String, dynamic>?;
          if (docShareLink.isEmpty && add != null) {
            final maybeShare = _untag(add['shareLink']);
            if (maybeShare.isNotEmpty) {
              // ignore: unused_local_variable
              final shareLinkFromRaw = maybeShare;
            }
          }
        }
      }
    }

    // 5. Load the PDF into PdfController (if URL exists)
    PdfController? controller;
    if (pdfUrl != null && pdfUrl.isNotEmpty) {
      final pdfRes = await http.get(Uri.parse(pdfUrl));
      if (pdfRes.statusCode == 200) {
        controller = PdfController(
          document: PdfDocument.openData(pdfRes.bodyBytes),
        );
      }
    }

    _pdf = controller;

    // Fallback labels if raw didn’t contain those fields
    if (companyName.isEmpty) {
      companyName = 'Trakhees Licensee';
    }
    if (memberRole.isEmpty) {
      memberRole = 'Owner';
    }

    return _MockDoc(
      companyName: companyName,
      memberName: memberName,
      memberRole: memberRole,
      shareLink: docShareLink,
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
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: doc.companyName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: '. ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: doc.memberName,
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
                  onPressed: () => _openShareQr(doc.shareLink),
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
                  onPressed: () => _openShareQr(doc.shareLink),
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