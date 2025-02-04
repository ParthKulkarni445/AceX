import 'package:cf_buddy/problempage.dart';
import 'package:cf_buddy/services.dart';
import 'package:cf_buddy/utils/loading_widget.dart';
import 'package:flutter/material.dart';
//import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SubmissionsPage extends StatefulWidget {
  final String handle;
  const SubmissionsPage({super.key, required this.handle});

  @override
  State<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  late Future<List<dynamic>> submissions;
  late Future<Map<String,dynamic>> problems;
  final int _pageSize = 50;
  int _currentPage = 1;
  List<dynamic> _allSubmissions = [];
  List<dynamic> _problems = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    submissions = ApiService().getSubmissions(widget.handle);
    problems = ApiService().getProlblemSet();
  }

  void _retryFetchData() {
    setState(() {
      _fetchData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
      _currentPage = 1;
    });
    await Future.wait([submissions, problems]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Submissions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.green,
          surfaceTintColor: Colors.green,
        ),
        body: FutureBuilder(
          future: Future.wait([submissions, problems]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: const LoadingCard(primaryColor: Colors.green,),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _buildErrorWidget();
            }
            _allSubmissions = snapshot.data![0];
            _problems = snapshot.data![1]['problems'];
            
            return RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.black,
              backgroundColor: Colors.green,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(5.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSubmissionsList(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmissionsList() {
    final int totalPages = (_allSubmissions.length / _pageSize).ceil();
    final int startIndex = (_currentPage - 1) * _pageSize;
    final int endIndex = startIndex + _pageSize > _allSubmissions.length 
        ? _allSubmissions.length 
        : startIndex + _pageSize;
    final List<dynamic> currentPageSubmissions = _allSubmissions.sublist(startIndex, endIndex);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentPageSubmissions.length,
          itemBuilder: (context, index) => _buildSubmissionTile(currentPageSubmissions[index]),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _currentPage > 1 
                  ? () => setState(() => _currentPage--)
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Icon(Icons.chevron_left),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page $_currentPage of $totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionTile(dynamic submission) {
    final submissionTime = DateTime.fromMillisecondsSinceEpoch(
      submission['creationTimeSeconds'] * 1000
    );
    final dateFormat = DateFormat('MMM/dd/yy,HH:mm');
    final formattedDate = dateFormat.format(submissionTime);
    final isAccepted = submission['verdict'] == 'OK';
    final problem = _problems.firstWhere(
      (element) => (element['contestId'] == submission['problem']['contestId'] && 
                   element['index'] == submission['problem']['index'])||element['name']==submission['problem']['name']);
    final rating = problem['rating'];
    List<String> tags = problem['tags'].cast<String>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 7,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isAccepted ? Colors.green[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAccepted ? Colors.green[200]! : Colors.red[200]!,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final contestId = submission['problem']['contestId'];
              final submissionId = submission['id']; // Assuming 'id' is the key for submission ID
              final uri = Uri.parse('https://codeforces.com/contest/$contestId/submission/$submissionId');
              if (!await launchUrl(
                uri,
                mode: LaunchMode.inAppBrowserView,
              )) {
                throw Exception('Could not launch $uri');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          submission['problem']['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            height: 1.3,
                          ),
                        ),
                      ),
                      if(rating != null) Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey[400]!,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time,
                    'Submitted:',
                    formattedDate,
                    Colors.blue[600]!,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.check_circle_outline,
                    'Verdict:',
                    submission['verdict'],
                    isAccepted ? Colors.green[700]! : Colors.red[700]!,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.label_outline,
                    'Tags:',
                    tags.join(', '),
                    Colors.grey[600]!,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
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
              backgroundColor: Colors.green,
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