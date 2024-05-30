import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable()
class Tournaments {
  final String tournamentId;
  final String date;
  final String location;
  final String level;
  final String gender;
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>>? reserve; // Add reserve list

  Tournaments({
    this.tournamentId = '',
    this.date = '',
    this.location = '',
    this.level = '',
    this.gender = '',
    this.teams = const [],
    this.reserve = const [], // Initialize reserve
  });

  factory Tournaments.fromJson(Map<String, dynamic> json) => _$TournamentsFromJson(json);
  Map<String, dynamic> toJson() => _$TournamentsToJson(this);
}

@JsonSerializable()
class Users {
  final String namef;
  final String namel;
  final int rank;
  final String uid;
  final int ukbtno;

  Users({
    this.namef = '',
    this.namel = '',
    this.rank = 0,
    this.uid = '',
    this.ukbtno = 0,
  });

  factory Users.fromJson(Map<String, dynamic> json) => _$UsersFromJson(json);
  Map<String, dynamic> toJson() => _$UsersToJson(this);
}
