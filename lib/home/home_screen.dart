import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:ukbtapp/shared/bottom_nav.dart';
import 'package:ukbtapp/core/auth/models/tournament_model.dart';
import 'package:ukbtapp/core/registration_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tournament> _upcomingTournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTournaments();
  }

  Future<void> _fetchUpcomingTournaments() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!userDoc.data()!.containsKey('registeredTournaments')) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'registeredTournaments': [],
        });
      }

      final registeredTournamentIds = List<String>.from(userDoc.data()!['registeredTournaments'] ?? []);

      setState(() {
        _upcomingTournaments = []; // Initialize with an empty list
      });

      if (registeredTournamentIds.isNotEmpty) {
        final now = DateTime.now();
        for (String tournamentId in registeredTournamentIds) {
          final tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();

          if (tournamentDoc.exists) {
            final tournamentData = tournamentDoc.data()!;
            final tournamentDate = tournamentData['date'] as Timestamp;
            if (tournamentDate.toDate().isAfter(now)) {
              setState(() {
                _upcomingTournaments.add(Tournament.fromMap(tournamentData, tournamentId));
              });
              if (_upcomingTournaments.length >= 2) break; // Limit to 2 tournaments
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your Upcoming Tournaments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (_upcomingTournaments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('You have no upcoming tournaments'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _upcomingTournaments.length,
                itemBuilder: (context, index) {
                  final tournament = _upcomingTournaments[index];
                  return ListTile(
                    title: Text(tournament.name),
                    subtitle: Text(
                      '${tournament.gender} - ${tournament.level}\n'
                      '${tournament.location}',
                    ),
                    trailing: Text(
                      tournament.date?.toLocal().toString().split(' ')[0] ?? 'Date not specified',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrationPage(tournament: tournament),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'UKBT News',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: NewsItem(
                imageUrl: 'https://static.wixstatic.com/media/101e95_1ac6d2009f5543c592607837c72cd204~mv2.jpg/v1/fill/w_1816,h_1212,fp_0.50_0.50,q_90,enc_auto/101e95_1ac6d2009f5543c592607837c72cd204~mv2.jpg',
                title: 'Junior Championships Recap',
                articleUrl: 'https://www.ukbeachtour.com/post/junior-championships-recap',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/tournaments');
          }
        },
      ),
    );
  }
}

class NewsItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String articleUrl;

  const NewsItem({Key? key, required this.imageUrl, required this.title, required this.articleUrl}) : super(key: key);

  Future<void> _launchUrl(BuildContext context) async {
    final Uri url = Uri.parse(articleUrl);
    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the article. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
