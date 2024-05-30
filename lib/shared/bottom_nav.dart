import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavBar extends StatelessWidget {
  final int x;

  const BottomNavBar({super.key, required this.x});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: NavigationBar,
      child: BottomNavigationBar(
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 14,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.house,
              size: 18,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.trophy,
              size: 18,
            ),
            label: 'Ranks',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.calendarDay,
              size: 18,
            ),
            label: 'Tournaments',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              FontAwesomeIcons.user,
              size: 18,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: x,
        selectedItemColor: const Color(0xFFFFCD03),
        unselectedItemColor: Colors.grey,
        onTap: (int idx) {
          switch (idx) {
            case 0:
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              Navigator.pushNamed(context, '/rank');
              break;
            case 2:
              Navigator.pushNamed(context, '/tournaments');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
