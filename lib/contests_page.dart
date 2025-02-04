import 'package:cf_buddy/contests_details.dart';
import 'package:cf_buddy/services.dart';
import 'package:cf_buddy/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ContestsPage extends StatefulWidget {
  const ContestsPage({super.key});

  @override
  State<ContestsPage> createState() => _ContestsPageState();
}

class _ContestsPageState extends State<ContestsPage> {
  late Future<List<dynamic>> contests;
  final Map<String, List<dynamic>> _groupedContests = {};
  final Map<String, int> _currentPage = {};
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    contests = ApiService().getContests();
  }

  void _retryFetchData() {
    setState(() {
      _fetchData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
      _groupedContests.clear();
      _currentPage.clear();
    });
    await Future.wait([contests]);
  }

  Map<String, List<dynamic>> _groupContests(List<dynamic> contests) {
    final grouped = <String, List<dynamic>>{};
    for (final contest in contests) {
      final status = _getContestStatus(contest);
      if (!grouped.containsKey(status)) {
        grouped[status] = [];
      }
      grouped[status]!.add(contest);
    }
    if (grouped.containsKey('Upcoming')) {
      grouped['Upcoming']!.sort((a, b) => a['startTimeSeconds'].compareTo(b['startTimeSeconds']));
    }
    return grouped;
  }

  String _getContestStatus(dynamic contest) {
    switch (contest['phase']) {
      case 'CODING':
        return 'Ongoing';
      case 'BEFORE':
        return 'Upcoming';
      default:
        return 'Finished';
    }
  }

  Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(
    uri,
    mode: LaunchMode.inAppBrowserView,
  )) {
    throw Exception('Could not launch $url');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        centerTitle: true,
        elevation: 15,
        shadowColor: Colors.black,
        title: const Text('Contests', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.yellow[600],
        surfaceTintColor: Colors.yellow[600],
      ),
      body: FutureBuilder(
        future: Future.wait([contests]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingCard(primaryColor: Colors.yellow),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _buildErrorWidget();
          }
          final allContests = snapshot.data![0];
          _groupedContests.addAll(_groupContests(allContests));
          final List<Widget> contestWidgets = [];
          for (var entry in _groupedContests.entries) {
            contestWidgets.add(_buildContestGroup(entry.key, entry.value));
            contestWidgets.add(const SizedBox(height: 24));
          }
          contestWidgets.add(const SizedBox(height: 80));
    
          return RefreshIndicator(
            color: Colors.black,
            backgroundColor: Colors.yellow[600],
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: contestWidgets,
              ),
            ),
          );
        }
      )
    );
  }

  Widget _buildContestGroup(String status, List<dynamic> contests) {
    if (!_currentPage.containsKey(status)) {
      _currentPage[status] = 1;
    }

    final int totalPages = (contests.length / _pageSize).ceil();

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final int startIndex = (_currentPage[status]! - 1) * _pageSize;
        final int endIndex = startIndex + _pageSize > contests.length 
            ? contests.length 
            : startIndex + _pageSize;
        final List<dynamic> currentPageContests = contests.sublist(startIndex, endIndex);

        return Card(
          elevation: 7,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.yellow[600],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentPageContests.length,
                itemBuilder: (context, index) => _buildContestTile(currentPageContests[index]),
                separatorBuilder: (context, index) => const Divider(color: Colors.grey, thickness: 2,),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _currentPage[status]! > 1 ? () {
                        setState(() {
                          _currentPage[status] = _currentPage[status]! - 1;
                        });
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[600],
                        elevation: 5
                      ),
                      child: const Icon(Icons.chevron_left, size: 25, color: Colors.black),
                    ),
                    Text('Page ${_currentPage[status]} of $totalPages', textAlign: TextAlign.center,),
                    ElevatedButton(
                      onPressed: _currentPage[status]! < totalPages ? () {
                        setState(() {
                          _currentPage[status] = _currentPage[status]! + 1;
                        });
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[600],
                        elevation: 5
                      ),
                      child: const Icon(Icons.chevron_right, size: 25, color: Colors.black,),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContestTile(dynamic contest) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(contest['startTimeSeconds'] * 1000);
    final duration = Duration(seconds: contest['durationSeconds']);
    
    final dateFormat = DateFormat('MMM/dd/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    final formattedDate = dateFormat.format(startTime);
    final formattedTime = timeFormat.format(startTime);
    final formattedDuration = '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}';
    
    return ListTile(
      title: Text(contest['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.calendarDays, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Date: ', style: TextStyle(color: Colors.grey[600])),
                  Text(formattedDate, style: const TextStyle(color: Color.fromARGB(255, 11, 35, 243)),),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.clock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Start Time: ', style: TextStyle(color: Colors.grey[600])),
                  Text('$formattedTime (IST)',  style: const TextStyle(color:Color.fromARGB(255, 11, 35, 243)),)
                ],
              ),
              const SizedBox(height: 6),
               Row(
                children: [
                  FaIcon(FontAwesomeIcons.hourglassHalf, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Duration: ',style: TextStyle(color: Colors.grey[600])),
                  Text('$formattedDuration hrs')
                ],
              ),
              const SizedBox(height: 10),
               (contest['phase']=='BEFORE')?Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final url = 'https://codeforces.com/contestRegistration/${contest['id']}';
                      _launchURL(url);
                    },
                    style: ElevatedButton.styleFrom(
                      side:const BorderSide(color: Colors.black, width: 1.5),
                      backgroundColor: Colors.yellow[600],
                      elevation: 5
                    ),
                    child: const Text('Register', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ):Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContestDetailsPage(contestId: contest['id']),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      side:const BorderSide(color: Colors.black, width: 1.5),
                      backgroundColor: Colors.yellow[600],
                      elevation: 5
                    ),
                    child: const Text('View Details', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 10),
            // Make the card square
            SizedBox(
            width: 80,
            height: 80,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.black, width: 2),
              ),
              color: Colors.yellow[600],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Text(startTime.day.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(DateFormat('MMM').format(startTime), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_statusbar_connected_no_internet_4_outlined, 
            size: 150
          ),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 22, 
              color: Colors.black, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _retryFetchData,
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: Colors.yellow[600],
            ),
            child: const Text(
              'Retry', 
              style: TextStyle(color: Colors.black)
            ),
          ),
        ],
      ),
    );
  }
}

