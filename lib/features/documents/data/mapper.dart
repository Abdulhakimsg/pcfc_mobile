import 'dto.dart';
import 'models.dart';

DocumentSummary toDomain(DocumentSummaryDto d) => DocumentSummary(
  id: d.id,
  title: d.title,
  issuer: d.issuer,
  type: d.type,
  issuedAt: DateTime.parse(d.issuedAt),
  valid: d.valid,
);