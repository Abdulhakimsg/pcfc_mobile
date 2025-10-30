class DocumentSummaryDto {
  final String id, title, issuer, type, issuedAt;
  final bool valid;
  DocumentSummaryDto({required this.id, required this.title, required this.issuer, required this.type, required this.issuedAt, required this.valid});
  factory DocumentSummaryDto.fromJson(Map<String, dynamic> j) => DocumentSummaryDto(
    id: j['id'], title: j['title'], issuer: j['issuer'], type: j['type'],
    issuedAt: j['issuedAt'], valid: j['valid'] as bool,
  );
}