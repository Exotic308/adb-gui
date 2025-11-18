import 'package:flutter_querybuilder/flutter_querybuilder.dart';

class NamedQuery {
  final String id;
  final String name;
  final QueryGroup query;

  NamedQuery({
    required this.id,
    required this.name,
    required this.query,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'query': QuerySerializer.toJson(query),
    };
  }

  factory NamedQuery.fromJson(Map<String, dynamic> json) {
    return NamedQuery(
      id: json['id'] as String,
      name: json['name'] as String,
      query: QuerySerializer.fromJson(json['query'] as Map<String, dynamic>),
    );
  }

  NamedQuery copyWith({
    String? id,
    String? name,
    QueryGroup? query,
  }) {
    return NamedQuery(
      id: id ?? this.id,
      name: name ?? this.name,
      query: query ?? this.query,
    );
  }
}

