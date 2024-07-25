import 'dart:math';

class EloCalculator {
  static const int K = 32;

  static double calculateExpectedScore(int rating1, int rating2) {
    return 1 / (1 + pow(10, (rating2 - rating1) / 400));
  }

  static int calculateNewRating(int rating, double expectedScore, double actualScore) {
    return (rating + K * (actualScore - expectedScore)).round();
  }

  static List<int> calculateEloChange(int rating1, int rating2, bool team1Won) {
    double expectedScore1 = calculateExpectedScore(rating1, rating2);
    double expectedScore2 = 1 - expectedScore1;

    double actualScore1 = team1Won ? 1 : 0;
    double actualScore2 = 1 - actualScore1;

    int newRating1 = calculateNewRating(rating1, expectedScore1, actualScore1);
    int newRating2 = calculateNewRating(rating2, expectedScore2, actualScore2);

    return [
      newRating1 - rating1,
      newRating2 - rating2
    ];
  }
}
