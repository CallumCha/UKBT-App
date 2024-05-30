// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tournaments _$TournamentsFromJson(Map<String, dynamic> json) => Tournaments(
      tournamentId: json['tournamentId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      location: json['location'] as String? ?? '',
      level: json['level'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      reserve: (json['reserve'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TournamentsToJson(Tournaments instance) =>
    <String, dynamic>{
      'tournamentId': instance.tournamentId,
      'date': instance.date,
      'location': instance.location,
      'level': instance.level,
      'gender': instance.gender,
      'teams': instance.teams,
      'reserve': instance.reserve,
    };

Users _$UsersFromJson(Map<String, dynamic> json) => Users(
      namef: json['namef'] as String? ?? '',
      namel: json['namel'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      uid: json['uid'] as String? ?? '',
      ukbtno: (json['ukbtno'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UsersToJson(Users instance) => <String, dynamic>{
      'namef': instance.namef,
      'namel': instance.namel,
      'rank': instance.rank,
      'uid': instance.uid,
      'ukbtno': instance.ukbtno,
    };
