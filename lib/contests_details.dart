import 'package:cf_buddy/services.dart';
import 'package:cf_buddy/utils/loading_widget.dart';
import 'package:cf_buddy/utils/rating_calculator.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ContestDetailsPage extends StatefulWidget {
  final int contestId;

  const ContestDetailsPage({super.key, required this.contestId});

  @override
  State<ContestDetailsPage> createState() => _ContestDetailsPageState();
}

class _ContestDetailsPageState extends State<ContestDetailsPage> {
  late Future<Map<String, dynamic>> contestDetails;
  late Future<Map<String, dynamic>> userStandings;
  late Future<List<dynamic>> contestRatingChanges;
  late Future<Map<String,dynamic>> friends;
  final String _handle = 'IamAddictedtoCP';

   Color getColorForRating(int? rating) {
    if (rating == null || rating <= 1199) return Colors.grey;
    if (rating <= 1399) return Colors.green;
    if (rating <= 1599) return Colors.cyan;
    if (rating <= 1899) return const Color.fromARGB(255, 11, 35, 243);
    if (rating <= 2099) return Colors.purple;
    if (rating <= 2299) return Colors.orange;
    if (rating <= 2399) return Colors.orangeAccent;
    if (rating <= 2599) return Colors.red;
    if (rating <= 2899) return Colors.redAccent;
    return const Color.fromARGB(255, 128, 0, 0); // Dark Red
  }


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    contestDetails = ApiService().getContestDetails(widget.contestId);
    userStandings = ApiService().getUserStandings(widget.contestId, _handle);
    contestRatingChanges = ApiService().getContestRatingChanges(widget.contestId);
    friends = ApiService().getFriendStandings(_handle, widget.contestId);
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
    await Future.wait([contestDetails, userStandings, contestRatingChanges, friends]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          shadowColor: Colors.black,
          elevation: 15,
          centerTitle: true,
          title: const Text('Contest Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
        ),
        body: FutureBuilder(
          future: Future.wait([contestDetails, userStandings, contestRatingChanges]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingCard(primaryColor: Colors.orange));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorWidget();
            }
            final contestDetails = snapshot.data![0] as Map<String, dynamic>;
            final contestData = contestDetails['contest'];
            final problems = contestDetails['problems'];
            final ranklistRows = contestDetails['rows'];
            final userStandingsData = snapshot.data![1] as Map<String, dynamic>;
            final ratingChanges = snapshot.data![2] as List<dynamic>;
            
            return RefreshIndicator(
              onRefresh: _refreshData,
              backgroundColor: Colors.orange,
              color: Colors.black,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailsCard(contestData),
                    const SizedBox(height: 24),
                    _buildYourPerformanceCard(contestData, userStandingsData, problems, ranklistRows, ratingChanges),
                    const SizedBox(height: 24),
                    _buildProblemsCard(problems,userStandingsData, ranklistRows, ratingChanges),
                    const SizedBox(height: 24),
                    _buildRankingsCard(ratingChanges,ranklistRows),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
  
  Widget _buildDetailsCard(Map<String, dynamic> contestData) {
    return Card(
      elevation: 7,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              contestData['name'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(FontAwesomeIcons.tag, 'Type', contestData['type']),
            _buildDetailRow(FontAwesomeIcons.hourglassHalf, 'Phase', contestData['phase']),
            _buildDetailRow(FontAwesomeIcons.calendarDays, 'Date', 
              DateFormat('MMM/dd/yyyy').format(DateTime.fromMillisecondsSinceEpoch(contestData['startTimeSeconds'] * 1000))),
            _buildDetailRow(FontAwesomeIcons.clock, 'Start Time', 
              DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(contestData['startTimeSeconds'] * 1000))),
            _buildDetailRow(FontAwesomeIcons.hourglass, 'Duration', 
              '${Duration(seconds: contestData['durationSeconds']).inHours} hours'),
            _buildDetailRow(FontAwesomeIcons.snowflake, 'Frozen', contestData['frozen'] ? 'Yes' : 'No'),
            const SizedBox(height: 8),
            ElevatedButton(
            
              onPressed: () async {
                final uri = Uri.parse('https://codeforces.com/contest/${contestData['id']}');
                if (!await launchUrl(
                  uri,
                  mode: LaunchMode.inAppBrowserView,
                )) {
                  throw Exception('Could not launch $uri');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                elevation: 8,
                maximumSize: Size.fromWidth(125)
              ),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.open_in_new, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Visit', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourPerformanceCard(Map<String, dynamic> contestData ,Map<String, dynamic> userStandingsData, List<dynamic> problems, List<dynamic> ranklistRows, List<dynamic> ratingChanges) {
    if (userStandingsData['rows'].isEmpty) {
      return Card(
        elevation: 7,
        color: Colors.white,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.trophy,
                  size: 20,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
              SizedBox(height: 32),
              Center(child: Text('You haven\'t participated in this contest')),
              SizedBox(height: 32),
            ],
          ),
        ),
      );
    }

    final userRow = userStandingsData['rows'][0];
    final userRatingRow = ratingChanges.firstWhere((r) => r['handle'] == _handle, orElse: () => {});
    final rank = userRow['rank'];
    final totalParticipants = ratingChanges.length;
    final problemResults = userRow['problemResults'];
    final problemsSolved = problemResults.where((p) => p is Map<String, dynamic> && p['points'] is num && p['points'] > 0).length;
    final totalProblems = problemResults.length;
    final totalPenalty = userRow['penalty'];
    final points = userRow['points'];
    final maxPoints = problems.fold(0.0, (sum, p) => sum + (p['points'] ?? 1.0));

    // Calculate percentages for progress indicators
    final rankPercentile = totalParticipants > 0 ? (100 - (rank / totalParticipants * 100)) : 0.0;
    final problemsProgress = totalProblems > 0 ? (problemsSolved / totalProblems * 100) : 0.0;
    final pointsProgress = maxPoints > 0 ? (points / maxPoints * 100) : 0.0;

    return Card(
      elevation: 7,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.trophy,
                  size: 20,
                  color: Colors.orange[700],
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildMetricCircular(
              icon: FontAwesomeIcons.crown,
              iconColor: Colors.purple,
              label: 'Rank',
              value: '#$rank',
              progress: rankPercentile.toDouble(),
              subtitle: 'Top ${rankPercentile.toStringAsFixed(1)}% of $totalParticipants participants',
            ),
            const SizedBox(height: 16),

            _buildMetricSection(
              icon: FontAwesomeIcons.brain,
              iconColor: Colors.green,
              label: 'Problems Solved',
              value: '$problemsSolved/$totalProblems',
              progress: problemsProgress,
              subtitle: 'Solved ${problemsProgress.toStringAsFixed(1)}% of problems',
            ),
            if(contestData['type']=='CF')const SizedBox(height: 16),
            if(contestData['type']=='CF')_buildMetricSection(
              icon: FontAwesomeIcons.bullseye,
              iconColor: Colors.blue,
              label: 'Points Earned',
              value: '$points/${maxPoints.toStringAsFixed(0)}',
              progress: pointsProgress,
              subtitle: 'Earned ${pointsProgress.toStringAsFixed(1)}% of total points',
            ),
            if(contestData['type']=='ICPC')...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[500]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.triangleExclamation,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Penalty',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      totalPenalty.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (userRatingRow['oldRating'] != null && userRatingRow['newRating'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[500]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.award,
                          size: 20,
                          color: Colors.red[800],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Rating Change',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${userRatingRow['newRating'] - userRatingRow['oldRating']}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: userRatingRow['newRating'] >= userRatingRow['oldRating'] ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSection({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required double progress,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[500]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(
                    icon,
                    size: 16,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress / 100,
              color: iconColor,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCircular({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required double progress,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[500]!, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Row with Icon and Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Circular Progress Indicator
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Circle
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade300),
                  ),
                ),
                // Foreground Progress Circle
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                ),
                // Percentage Text
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProblemsCard(List<dynamic> problems, Map<String, dynamic> userStandingsData, List<dynamic> ranklistRows, List<dynamic> ratingChanges) {
  return Card(
    elevation: 7,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(width: 8),
              Text(
                'Problems',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: problems.length,
            itemBuilder: (context, index) {
              final problem = problems[index];
              final userPoints = (!userStandingsData['rows'].isEmpty)?userStandingsData['rows'][0]['problemResults'][index]['points']:0;
              final userResult = (!userStandingsData['rows'].isEmpty)?userStandingsData['rows'][0]['problemResults'][index] : {};
              final isCorrect = (!userStandingsData['rows'].isEmpty)?userResult['points'] > 0 : false;
              final wrongAttempts = (!userStandingsData['rows'].isEmpty)?userResult['rejectedAttemptCount'] : 0;
              final totalAttempts = ratingChanges.length;
              final correctAttempts = ranklistRows.fold(0, (sum, row) => (sum + (row['problemResults'][index]['points'] != null && row['problemResults'][index]['points'] > 0 ? 1 : 0)).toInt());
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withOpacity(0.1) : 
                         wrongAttempts > 0 ? Colors.red.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect ? Colors.green.withOpacity(0.3) : 
                           wrongAttempts > 0 ? Colors.red.withOpacity(0.3) : 
                           Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      String.fromCharCode(65 + index), // Convert 0->A, 1->B, etc.
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    problem['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (problem['points'] != null) 
                      Text(
                        'Points: $userPoints/${problem['points']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if(problem['points'] != null)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: LinearProgressIndicator(
                          value: userPoints / problem['points'],
                          backgroundColor: Colors.grey[400],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[800]!),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : 
                            wrongAttempts > 0 ? Icons.error : Icons.circle_outlined,
                            size: 16,
                            color: isCorrect ? Colors.green : 
                                   wrongAttempts > 0 ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCorrect ? 'Solved' : 
                            wrongAttempts > 0 ? 'Wrong attempts: $wrongAttempts' : 'Not attempted',
                            style: TextStyle(
                              color: isCorrect ? Colors.green : 
                                     wrongAttempts > 0 ? Colors.red : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solved by $correctAttempts/$totalAttempts',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final contestId = problem['contestId']; // Assuming 'problem' is the object containing contest details
                    final index = problem['index']; // Assuming 'index' is the key for problem index
                    final url = Uri.parse('https://codeforces.com/contest/$contestId/problem/$index');

                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.inAppBrowserView,
                    )) {
                      throw Exception('Could not launch $url');
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}


Widget _buildRankingsCard(List<dynamic> ratingChanges, List<dynamic> ranklistRows) {
  return Card(
    elevation: 8,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.trophy,
                  size: 24,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Friend Rankings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          FutureBuilder(
            future: friends,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState();
              }

              final friendsData = snapshot.data!;
              if (friendsData['rows'] == null || friendsData['rows'].isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: friendsData['rows'].length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildParticipantCard(
                  friendsData['rows'][index], 
                  index,
                  ratingChanges.length, // Pass total participants
                  ranklistRows,
                  ratingChanges,
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget _buildParticipantCard(Map<String, dynamic> row, int index, int totalParticipants, List<dynamic> ranklistRows, List<dynamic> ratingChanges) {
  final handle = row['party']['members'][0]['handle'];
  final isCurrentUser = handle == _handle;
  final rank = row['rank'];
  final points = row['points'];
  final problemResults = row['problemResults'];
  final projectedRating = calculatePerformanceRating(
    rank:  rank,
    totalParticipants:  totalParticipants,
    averageRating: 1150,
    beta: 525,
  );
  final ratingColor = getColorForRating(projectedRating);
  
  // Find rating change for the participant
  final ratingRow = ratingChanges.firstWhere(
    (r) => r['handle'] == handle,
    orElse: () => {'oldRating': null, 'newRating': null}
  );
  final oldRating = ratingRow['oldRating'];
  final newRating = ratingRow['newRating'];
  final ratingDelta = oldRating != null && newRating != null ? newRating - oldRating : null;

  // Calculate responsive sizes based on problem count
  final problemCount = problemResults.length;
  final num iconSize = problemCount <= 7 ? 16 : 14 - (problemCount - 7) * 0.5;
  final num fontSize = problemCount <= 7 ? 10 : 8 - (problemCount - 7) * 0.25;

  // Function to format submission time
  String formatSubmissionTime(int timeSeconds) {
    final duration = Duration(seconds: timeSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isCurrentUser ? Colors.orange.shade50 : Colors.white,
      border: Border.all(
        color: isCurrentUser ? Colors.orange.shade200 : Colors.grey[300]!,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: ratingColor.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                handle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ratingColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    points.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Performance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ratingColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ratingColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      projectedRating.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ratingColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Delta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (ratingDelta != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ratingDelta > 0 
                          ? Colors.green.shade50 
                          : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: ratingDelta > 0 
                            ? Colors.green.shade200 
                            : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${ratingDelta > 0 ? '+' : ''}$ratingDelta',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ratingDelta > 0 
                                ? Colors.green 
                                : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '-',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Problems Status Row with border
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: List.generate(problemResults.length, (i) {
              final result = problemResults[i];
              final isSolved = result['points'] != null && result['points'] > 0;
              final submissionTime = result['bestSubmissionTimeSeconds'];
              final attempts = result['rejectedAttemptCount'] ?? 0;
      
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      right: i < problemResults.length - 1 
                        ? BorderSide(color: Colors.grey.shade300)
                        : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        String.fromCharCode(65 + i),
                        style: TextStyle(
                          fontSize: fontSize + 2,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isSolved) ...[
                        Icon(
                          Icons.add_circle,
                          size: iconSize.toDouble(),
                          color: Colors.green,
                        ),
                        if (submissionTime != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            formatSubmissionTime(submissionTime),
                            style: TextStyle(
                              fontSize: fontSize.toDouble(),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          attempts > 0 ? '-$attempts' : '-',
                          style: TextStyle(
                            fontSize: fontSize + 2,
                            fontWeight: FontWeight.bold,
                            color: attempts > 0 ? Colors.red : Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmptyState() {
  return Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: [
        Icon(
          Icons.people_outline,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'No friends participated',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share the contest with your friends!',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorState() {
  return Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.red[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load rankings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please try again later',
          style: TextStyle(
            color: Colors.red,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon, size: constraints.maxWidth * 0.07, color: Colors.grey[600]),
              SizedBox(
                width: constraints.maxWidth * 0.88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[600])),
                    Text(
                      value.length > 19 ? '${value.substring(0, 19)}...' : value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
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
              backgroundColor: Colors.yellow[600],
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.black),),
          ),
        ],
      ),
    );
  }
}

