import 'package:flutter/material.dart';

class KnockoutMatch {
  final String id;
  final Map<String, dynamic> team1;
  final Map<String, dynamic> team2;
  final Map<String, dynamic>? result;

  KnockoutMatch({
    required this.id,
    required this.team1,
    required this.team2,
    this.result,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team1': team1,
      'team2': team2,
      'result': result,
    };
  }

  factory KnockoutMatch.fromMap(Map<String, dynamic> map) {
    return KnockoutMatch(
      id: map['id'] as String,
      team1: Map<String, dynamic>.from(map['team1'] as Map),
      team2: Map<String, dynamic>.from(map['team2'] as Map),
      result: map['result'] != null ? Map<String, dynamic>.from(map['result'] as Map) : null,
    );
  }
}
