import 'package:sketch_square/features/architects/domain/architect_summary.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/drawings/domain/sheet.dart';

DrawingSummary fakeDrawing({
  String id = 'd1',
  String title = 'Modern Villa',
  int pricePaise = 150000,
  bool isFree = false,
}) => DrawingSummary(
  id: id,
  title: title,
  category: const CategoryRef(id: 'c1', name: 'Villas', slug: 'villas'),
  city: 'Bengaluru',
  plotLengthFt: 30,
  plotBreadthFt: 40,
  plotAreaSqft: 1200,
  floors: 2,
  pricePaise: isFree ? 0 : pricePaise,
  isFree: isFree,
  architect: const ArchitectSummary(
    id: 'a1',
    fullName: 'Asha Rao',
    city: 'Bengaluru',
  ),
  status: DrawingStatus.published,
  createdAt: DateTime.utc(2026),
);

Sheet fakeSheet({
  String id = 's1',
  String fileName = 'plan.pdf',
  SheetType type = SheetType.architectural,
}) => Sheet(
  id: id,
  type: type,
  originalMime: 'application/pdf',
  fileName: fileName,
  sizeBytes: 2048,
);
