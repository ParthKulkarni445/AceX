import 'package:cf_buddy/contests_page.dart';
import 'package:cf_buddy/friends_page.dart';
import 'package:cf_buddy/profile_page.dart';
import 'package:cf_buddy/providers/user_provider.dart';
import 'package:cf_buddy/stats_page.dart';
import 'package:cf_buddy/submissions.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _page = 0;

  final List<Color?> colors = [
    Colors.red,
    Colors.yellow[600],
    Colors.blue,
    Colors.green,
    Colors.purple
  ];

  void onPageChange(int page) {
    setState(() {
      _page = page;
    });
  }

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final handle = user.handle;
    pages = [
      ProfilePage(handle: handle),
      const ContestsPage(),
      const FriendsPage(),
      SubmissionsPage(handle: handle),
      StatsPage(handle: handle)
    ];
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            pages[_page],
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: w * 0.03),
                height: w * 0.180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      offset: const Offset(0, 10),
                      blurRadius: 30
                    )
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BottomNavigationBar(
                    showSelectedLabels: false,
                    showUnselectedLabels: false,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    onTap: onPageChange,
                    currentIndex: _page,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: colors[_page],
                    unselectedItemColor: Colors.grey[600],
                    items: [
                      _buildNavBarItem(FontAwesomeIcons.solidUser, 0),
                      _buildNavBarItem(FontAwesomeIcons.trophy, 1),
                      _buildNavBarItem(FontAwesomeIcons.users, 2),
                      _buildNavBarItem(FontAwesomeIcons.clipboardList, 3),
                      _buildNavBarItem(FontAwesomeIcons.magnifyingGlassChart, 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavBarItem(IconData icon, int index) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: _page == index ? colors[index] : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: FaIcon(icon, size: 24),
          ),
        ],
      ),
      label: '',
    );
  }
}

