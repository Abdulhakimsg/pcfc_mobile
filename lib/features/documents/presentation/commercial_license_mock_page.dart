import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart';

class CommercialLicenseMockPage extends StatefulWidget {
  const CommercialLicenseMockPage({super.key});

  @override
  State<CommercialLicenseMockPage> createState() => _CommercialLicenseMockPageState();
}

class _CommercialLicenseMockPageState extends State<CommercialLicenseMockPage> {
  Future<_MockDoc>? _future;
  PdfController? _pdf;

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

  /// Strips `uuid:type:value` → `value`. Leaves input untouched if no match.
  String _untag(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    final m = RegExp(r'^[^:]+:[^:]+:(.+)$').firstMatch(s);
    return m?.group(1) ?? s;
  }

  /// For data URLs like `data:application/pdf;base64,JVBERi0x...` return only the base64.
  String _stripDataUrlHeader(String s) {
    if (!s.startsWith('data:')) return s;
    final comma = s.indexOf(',');
    return comma >= 0 ? s.substring(comma + 1) : s;
  }

  Future<_MockDoc> _load() async {
    final raw = await rootBundle.loadString('assets/mock/commercial_license.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final data = (json['data'] as Map<String, dynamic>);

    final companyName  = _untag(data['company_name']);
    final businessName = _untag(data['business_name']);
    final memberName   = _untag(data['member_name']);
    final memberRole   = _untag(data['member_role']);

    // Optional
    final recipientName = _untag((data['recipient'] as Map?)?['name']);

    // additionalData
    final add = (data['additionalData'] as Map<String, dynamic>?);
    final shareLink = _untag(add?['shareLink']);

    // ---- PDF handling (supports data URL + plain base64) ----
    final pdfRaw = _untag(add?['pdf']);      // remove `...:string:`
    final b64    = _stripDataUrlHeader(pdfRaw); // remove `data:application/pdf;base64,`

    Uint8List bytes = Uint8List(0);
    if (b64.isNotEmpty) {
      bytes = base64Decode(b64);
    }

    PdfController? controller;
    if (bytes.isNotEmpty) {
      // pdfx >= 2.9.x accepts a Future<PdfDocument>
      controller = PdfController(document: PdfDocument.openData(bytes));
    }

    _pdf = controller;
    return _MockDoc(
      companyName: companyName,
      businessName: businessName,
      memberName: memberName,
      memberRole: memberRole,
      recipientName: recipientName,
      shareLink: shareLink,
      pdf: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          return Column(
            children: [
              // Business statement
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('This document is issued by PCFC.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text(
                      'This is a commercial license issued to use the information above.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Details card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _InfoCard(entries: [
                  _KV('Company Name', doc.companyName),
                  _KV('Business Name', doc.businessName),
                  _KV('Member Name', doc.memberName),
                  _KV('Member Role', doc.memberRole),
                  if (doc.recipientName.isNotEmpty) _KV('Recipient', doc.recipientName),
                  if (doc.shareLink.isNotEmpty) _KV('Share Link', doc.shareLink),
                ]),
              ),

              const SizedBox(height: 12),

              // PDF section title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('License PDF',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),

              // PDF (or placeholder if missing)
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (doc.pdf == null) {
                      return const Center(
                        child: Text('No PDF found in additionalData.pdf'),
                      );
                    }
                    return PdfView(
                      controller: doc.pdf!,
                      scrollDirection: Axis.vertical,
                      pageSnapping: false,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MockDoc {
  final String companyName, businessName, memberName, memberRole;
  final String recipientName;
  final String shareLink;
  final PdfController? pdf;
  _MockDoc({
    required this.companyName,
    required this.businessName,
    required this.memberName,
    required this.memberRole,
    required this.recipientName,
    required this.shareLink,
    required this.pdf,
  });
}

class _KV {
  final String k, v;
  _KV(this.k, this.v);
}

class _InfoCard extends StatelessWidget {
  final List<_KV> entries;
  const _InfoCard({super.key, required this.entries});
  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Colors.white.withOpacity(.12));
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.fromBorderSide(border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: i < entries.length - 1
                  ? BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(.12), width: 0.6)))
                  : const BoxDecoration(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(entries[i].k,
                        style: TextStyle(color: Colors.white.withOpacity(.85), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      entries[i].v,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}