class KnockoutGenerator {
  Map<String, List<Map<String, dynamic>>> createKnockouts(int numTeams) {
    final knockoutRounds = {
      'Quarter-finals': <Map<String, dynamic>>[],
      'Semi-finals': <Map<String, dynamic>>[],
      'Finals': <Map<String, dynamic>>[]
    };

    if (numTeams == 5) {
      knockoutRounds['Semi-finals'] = [
        {
          'team1': 'Winner of Pool A',
          'team2': 'Runner-up of Pool A',
          'result': null
        },
        {
          'team1': '3rd Place of Pool A',
          'team2': '4th Place of Pool A',
          'result': null
        }
      ];
      knockoutRounds['Finals'] = [
        {
          'team1': 'Winner of Semifinal 1',
          'team2': 'Winner of Semifinal 2',
          'result': null
        }
      ];
    } else if (numTeams == 6 || numTeams == 7 || numTeams == 8) {
      knockoutRounds['Semi-finals'] = [
        {
          'team1': 'Winner of Pool A',
          'team2': 'Runner-up of Pool B',
          'result': null
        },
        {
          'team1': 'Winner of Pool B',
          'team2': 'Runner-up of Pool A',
          'result': null
        }
      ];
      knockoutRounds['Finals'] = [
        {
          'team1': 'Winner of Semifinal 1',
          'team2': 'Winner of Semifinal 2',
          'result': null
        }
      ];
    } else if (numTeams == 9 || numTeams == 10 || numTeams == 11 || numTeams == 12) {
      knockoutRounds['Quarter-finals'] = [
        {
          'team1': 'Winner of Pool A',
          'team2': 'Runner-up of Pool B',
          'result': null
        },
        {
          'team1': 'Winner of Pool B',
          'team2': 'Runner-up of Pool A',
          'result': null
        },
        {
          'team1': 'Winner of Pool C',
          'team2': 'Runner-up of Pool D',
          'result': null
        },
        {
          'team1': 'Winner of Pool D',
          'team2': 'Runner-up of Pool C',
          'result': null
        }
      ];
      knockoutRounds['Semi-finals'] = [
        {
          'team1': 'Winner of Quarter-final 1',
          'team2': 'Winner of Quarter-final 2',
          'result': null
        },
        {
          'team1': 'Winner of Quarter-final 3',
          'team2': 'Winner of Quarter-final 4',
          'result': null
        }
      ];
      knockoutRounds['Finals'] = [
        {
          'team1': 'Winner of Semifinal 1',
          'team2': 'Winner of Semifinal 2',
          'result': null
        }
      ];
    }

    return knockoutRounds;
  }
}
