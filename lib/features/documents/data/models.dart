class DocumentSummary {
  final String id, title, issuer, type;
  final DateTime issuedAt;
  final bool valid;
  const DocumentSummary({required this.id, required this.title, required this.issuer, required this.type, required this.issuedAt, required this.valid});
}