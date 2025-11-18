import 'named_query.dart';

class ImportResult {
  final List<NamedQuery> added;
  final List<String> skipped;
  final Map<String, String> renamed; // old name -> new name

  ImportResult({
    required this.added,
    required this.skipped,
    required this.renamed,
  });

  Map<String, dynamic> toJson() {
    return {
      'added': added.map((q) => q.toJson()).toList(),
      'skipped': skipped,
      'renamed': renamed,
    };
  }

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      added: (json['added'] as List<dynamic>)
          .map((q) => NamedQuery.fromJson(q as Map<String, dynamic>))
          .toList(),
      skipped: (json['skipped'] as List<dynamic>).cast<String>(),
      renamed: Map<String, String>.from(json['renamed'] as Map),
    );
  }
}

