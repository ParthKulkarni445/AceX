import 'package:cf_buddy/services.dart';
import 'package:cf_buddy/settings.dart';
import 'package:cf_buddy/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class ProfilePage extends StatefulWidget {
  final String handle;
  const ProfilePage({super.key, required this.handle});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _getOnlineStatus(int? lastOnlineTimeSeconds) {
    if (lastOnlineTimeSeconds == null) return 'Unknown';
    
    final lastOnlineTime = DateTime.fromMillisecondsSinceEpoch(lastOnlineTimeSeconds * 1000);
    final now = DateTime.now();
    final difference = now.difference(lastOnlineTime);

    if (difference.inMinutes < 1) {
      return 'Last login just now';
    } else if (difference.inHours < 1) {
      return 'Last login ${difference.inMinutes} minute(s) ago';
    } else if (difference.inDays < 1) {
      return 'Last login ${difference.inHours} hour(s) ago';
    } else {
      return 'Last login ${difference.inDays} day(s) ago';
    }
  }

  Map<String, Color> ratingColor = {
  'newbie': Colors.grey,
  'pupil': Colors.green,
  'specialist': Colors.cyan,
  'expert': const Color.fromARGB(255, 11, 35, 243), // Bright Blue
  'candidate master': Colors.purple,
  'master': Colors.orange,
  'international master': Colors.orangeAccent,
  'grandmaster': Colors.red,
  'international grandmaster': Colors.redAccent,
  'legendary grandmaster': const Color.fromARGB(255, 128, 0, 0), // Dark Red,
  'tourist': const Color.fromARGB(255, 128, 0, 0)
};

Map<String, Color> ratingRangeColor = {
  '0-1199': Colors.grey, // Newbie
  '1200-1399': Colors.green, // Pupil
  '1400-1599': Colors.cyan, // Specialist
  '1600-1899': const Color.fromARGB(255, 11, 35, 243), // Expert
  '1900-2099': Colors.purple, // Candidate Master
  '2100-2299': Colors.orange, // Master
  '2300-2399': Colors.orangeAccent, // International Master
  '2400-2599': Colors.red, // Grandmaster
  '2600-2899': Colors.redAccent, // International Grandmaster
  '2900-': const Color.fromARGB(255, 128, 0, 0), // Legendary Grandmaster
};

Color getColorForRating(int rating) {
  if (rating <= 1199) {
    return ratingRangeColor['0-1199']!;
  } else if (rating <= 1399) {
    return ratingRangeColor['1200-1399']!;
  } else if (rating <= 1599) {
    return ratingRangeColor['1400-1599']!;
  } else if (rating <= 1899) {
    return ratingRangeColor['1600-1899']!;
  } else if (rating <= 2099) {
    return ratingRangeColor['1900-2099']!;
  } else if (rating <= 2299) {
    return ratingRangeColor['2100-2299']!;
  } else if (rating <= 2399) {
    return ratingRangeColor['2300-2399']!;
  } else if (rating <= 2599) {
    return ratingRangeColor['2400-2599']!;
  } else if (rating <= 2899) {
    return ratingRangeColor['2600-2899']!;
  } else {
    return ratingRangeColor['2900-']!;
  }
}

  late Future<Map<String, dynamic>> userInfo;
  late Future<List<dynamic>> ratingHistory;
  late Future<List<dynamic>> submissions;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    userInfo = ApiService().getUserInfo(widget.handle);
    ratingHistory = ApiService().getRatingHistory(widget.handle);
    submissions = ApiService().getSubmissions(widget.handle);
  }

  void _retryFetchData() {
    setState(() {
      _fetchData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
    await Future.wait([userInfo, ratingHistory, submissions]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        centerTitle: true,
        elevation: 15,
        shadowColor: Colors.black,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        surfaceTintColor: Colors.red,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              } else if (value == 'signout') {
                final authService = AuthService();
                authService.signOut(context);
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
            color: Colors.white, // Dropdown background color
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text('Settings', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text('Sign Out', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
      future: Future.wait([userInfo, ratingHistory, submissions]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: const LoadingCard(primaryColor: Colors.red),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorWidget();
        }
        final userData = snapshot.data![0] as Map<String, dynamic>;
        final ratingHistoryData = snapshot.data![1] as List<dynamic>;
        final submissionsData = snapshot.data![2] as List<dynamic>;

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.black,
          backgroundColor: Colors.red,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(userData),
                const SizedBox(height: 24),
                _buildStatisticsCard(userData),
                const SizedBox(height: 24),
                _buildRatingCard(userData, ratingHistoryData),
                const SizedBox(height: 24),
                _buildSubmissionCard(submissionsData),
                const SizedBox(height: 24),
                _buildContestHistoryCard(ratingHistoryData),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildProfileHeader(Map<String, dynamic> data) {
    final onlineStatus = _getOnlineStatus(data['lastOnlineTimeSeconds']);
    final isOnline = onlineStatus == 'Online';
    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                data['titlePhoto'] ?? 'https://placekitten.com/200/200',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data['rank'] ?? 'Unranked',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ratingColor[data['rank']]),
            ),
            const SizedBox(height: 8),
            Text(
              data['handle'] ?? 'Unknown',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              onlineStatus,
              style: TextStyle(
                fontSize: 15,
                color: isOnline ? Colors.green : Colors.red[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatItem(FontAwesomeIcons.user, 'Name', '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'),
            _buildStatItem(FontAwesomeIcons.envelope, 'Email', data['email'] ?? 'N/A'),
            _buildStatItem(FontAwesomeIcons.locationDot, 'From', '${data['city'] ?? 'City X'}, ${data['country'] ?? 'Country Y'}'),
            _buildStatItem(FontAwesomeIcons.handHoldingHeart, 'Contribution', data['contribution']?.toString() ?? 'N/A'),
            _buildStatItem(FontAwesomeIcons.userFriends, 'Friend of', data['friendOfCount']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> userData, List<dynamic> ratingHistoryList) {
    final currentRating = userData['rating'] ?? 0;
    final maxRating = userData['maxRating'] ?? 0;
    final maxRank = userData['maxRank'] ?? 'Unknown';

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rating',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRatingInfo(FontAwesomeIcons.chartLine, 'Current Rating', currentRating.toString(), ratingColor[userData['rank']]!),
            _buildRatingInfo(FontAwesomeIcons.trophy, 'Max Rating', maxRating.toString(), ratingColor[maxRank]!),
            _buildRatingInfo(FontAwesomeIcons.crown, 'Max Rank', maxRank, ratingColor[maxRank]!),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Last 20 Rating Changes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(right: 10),
              height: 200,
              child: _buildRatingHistoryGraph(ratingHistoryList),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Least Recent', style: TextStyle(fontSize: 10),),
                Text('Most Recent', style: TextStyle(fontSize: 10),),
              ],
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap on graph for details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingInfo(IconData icon, String label, String value, Color color) {
    return LayoutBuilder(
      builder: (context,constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon, size: constraints.maxWidth*0.07, color: Colors.grey[600]),
              SizedBox(
                width: constraints.maxWidth * 0.88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[600])),
                    Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildRatingHistoryGraph(List<dynamic> ratingHistory) {
    if (ratingHistory.isEmpty) {
      return const Center(child: Text('No rating history available'));
    }

    // Take only the most recent 30 points
    final recentHistory = ratingHistory.reversed.take(20).toList().reversed.toList();

    final List<FlSpot> spots = recentHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['newRating'].toDouble());
    }).toList();

    final minRating = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxRating = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    //final List<double> horizontalLines = [1200, 1400, 1600, 1800, 2000];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            );
          },
          horizontalInterval: 50,
        ),
        titlesData: FlTitlesData(
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              maxIncluded: false,
              minIncluded: false,
              interval: 50,
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (recentHistory.length - 1).toDouble(),
        minY: minRating-100,
        maxY: maxRating+100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.red,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                final contest = recentHistory[index];
                final date = DateTime.fromMillisecondsSinceEpoch(contest['ratingUpdateTimeSeconds'] * 1000);
                final formattedDate = DateFormat('MMM dd, yyyy').format(date);
                final newRating = contest['newRating'];
                final oldRating = contest['oldRating'];
                final delta = newRating - oldRating;
                final sign = delta >= 0 ? '+' : '';
                return LineTooltipItem(
                  '$formattedDate\nRank: ${contest['rank']}\nRating: $newRating ($sign$delta)',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
            //tooltipDuration: const Duration(seconds: 5),
          ),
        ),
        //backgroundColor: _getBackgroundGradient(),
      ),
    );
  }

  Widget _buildContestHistoryCard(List<dynamic> contests) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              child: Text(
                'Contest History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contests.length > 15 ? 15 : contests.length,
              itemBuilder: (context, index) {
                final contest = contests[contests.length - 1 - index];
                return ListTile(
                  leading: FaIcon(FontAwesomeIcons.solidFlag, size: 10, color: (contest['newRating'] >= contest['oldRating']) ? Colors.green : Colors.red),
                  minLeadingWidth: 12,
                  minVerticalPadding: 10,
                  title: Text(contest['contestName'] ?? 'Unknown Contest'),
                  subtitle: Text('Rank: ${contest['rank']}', style: TextStyle(color: (contest['newRating'] >= contest['oldRating']) ? Colors.green : Colors.red)),
                  trailing: Column(
                    children: [
                      Text('${contest['newRating']}', style: TextStyle(fontSize: 14, color: getColorForRating(contest['newRating']), fontWeight: FontWeight.bold)),
                      Text('(${contest['newRating'] - contest['oldRating'] >= 0 ? '+' : '-'}${(contest['newRating'] - contest['oldRating']).abs()})', style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildSubmissionCard(List<dynamic> submissionList) {
    Map<DateTime, int> submissionsMap = {};
    Set<String> uniqSubs = {}, uniqSubsLastMonth = {};
    for (var submission in submissionList) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(submission['creationTimeSeconds'] * 1000);
      DateTime dateOnly = DateTime(date.year, date.month, date.day);
      submissionsMap[dateOnly] = (submissionsMap[dateOnly] ?? 0) + 1;
      if (submission['verdict'] == 'OK') {
        uniqSubs.add('${submission['problem']['contestId']}${submission['problem']['index']}');
        if (date.month == DateTime.now().month && date.year == DateTime.now().year) {
          uniqSubsLastMonth.add('${submission['problem']['contestId']}${submission['problem']['index']}');
        }
      }
    }
    int maxStreak = 0;
    int currentStreak = 0;
    int problemsSolved = uniqSubs.length;
    int problemsSolvedThisMonth = uniqSubsLastMonth.length;
    DateTime? lastSubmission;
    submissionsMap.keys.toList()
      ..sort()
      ..forEach((date) {
        if (lastSubmission == null || date.difference(lastSubmission!).inDays == 1) {
          currentStreak++;
          maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        } else {
          currentStreak = 1;
        }
        lastSubmission = date;
      });

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            HeatMap(
              datasets: submissionsMap,
              colorMode: ColorMode.color,
              defaultColor: Colors.grey[300],
              textColor: Colors.black,
              showColorTip: false,
              showText: false,
              scrollable: true,
              size: 20,
              colorsets: {
                1: Colors.red[100]!,
                4: Colors.red[300]!,
                6: Colors.red[600]!,
                8: Colors.red[900]!,
              },
            ),
            const SizedBox(height: 8),
            const Center(child: Text('<- Swipe to view more ->', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            _buildStatItem(FontAwesomeIcons.listCheck, 'Problems Solved', '$problemsSolved'),
            _buildStatItem(FontAwesomeIcons.calendarDays, 'Problems Solved This Month', '$problemsSolvedThisMonth'),
            _buildStatItem(FontAwesomeIcons.bolt, 'Current Streak', '$currentStreak days'),
            _buildStatItem(FontAwesomeIcons.fire, 'Max Streak', '$maxStreak days'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return LayoutBuilder(
      builder: (context,constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon, size: constraints.maxWidth*0.07, color: Colors.grey[600]),
              SizedBox(
                width: constraints.maxWidth * 0.88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[600])),
                    Text(value.length > 19 ? '${value.substring(0, 19)}...' : value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_outlined, size: 150,),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _retryFetchData,
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor:  Colors.red,
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.black),),
          ),
        ],
      ),
    );
  }
  
}

