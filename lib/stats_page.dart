import 'dart:math';
import 'package:cf_buddy/services.dart';
import 'package:cf_buddy/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StatsPage extends StatefulWidget {
  final String handle;
  const StatsPage({super.key, required this.handle});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late Future<List<dynamic>> submissions;
  late Future<Map<String, dynamic>> problems;
  late Future<List<dynamic>> contests;
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);
  late Map<String, Map<int, int>> rankCounts;
  final List<String> _divisions = ['Div. 1', 'Div. 2', 'Div. 3', 'Div. 4', 'Global', 'Div. 1 + Div. 2'];
  String _selectedDivision = 'Div. 1';

  final Map<String, Map<String, dynamic>> rankInfo = {
    'newbie': {
      'color': const Color(0xFF808080),
      'name': 'Newbie',
      'range': [800, 1199],
    },
    'pupil': {
      'color': const Color(0xFF008000),
      'name': 'Pupil',
      'range': [1200, 1399],
    },
    'specialist': {
      'color': const Color(0xFF03A89E),
      'name': 'Specialist',
      'range': [1400, 1599],
    },
    'expert': {
      'color': const Color(0xFF0000FF),
      'name': 'Expert',
      'range': [1600, 1899],
    },
    'candidate': {
      'color': const Color(0xFF800080),
      'name': 'Candidate Master',
      'range': [1900, 2099],
    },
    'master': {
      'color': const Color(0xFFFF8C00),
      'name': 'Master',
      'range': [2100, 2299],
    },
    'international': {
      'color': const Color(0xFFFF0000),
      'name': 'International Master',
      'range': [2300, 2399],
    },
    'grandmaster': {
      'color': const Color(0xFFFF0000),
      'name': 'Grandmaster',
      'range': [2400, 2599],
    },
    'legendary': {
      'color': const Color(0xFF8B0000),
      'name': 'Legendary Grandmaster',
      'range': [2600, 3500],
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _fetchData() {
    submissions = ApiService().getSubmissions(widget.handle);
    problems = ApiService().getProlblemSet();
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
    });
    await Future.wait([submissions, problems, contests]);
  }

  Map<String, Map<int, int>> processSubmissions(List<dynamic> subs, Map<String, dynamic> probs) {
    Map<String, Map<String, dynamic>> acceptedProblems = {};

    for (var submission in subs) {
      if (submission['verdict'] == 'OK') {
        String problemId = '${submission['problem']['contestId']}-${submission['problem']['index']}';
        if (!acceptedProblems.containsKey(problemId)) {
          acceptedProblems[problemId] = submission['problem'];
        }
      }
    }

    Map<String, Map<int, int>> nonEmptyRankCounts = {};

    for (var problem in acceptedProblems.values) {
      if (problem['rating'] != null) {
        int rating = problem['rating'];
        int ratingKey = (rating ~/ 100) * 100;
        if (ratingKey < 800) ratingKey = 800;

        for (var rank in rankInfo.keys) {
          final range = rankInfo[rank]!['range'] as List<int>;
          if (ratingKey >= range[0] && ratingKey <= range[1]) {
            if (!nonEmptyRankCounts.containsKey(rank)) {
              nonEmptyRankCounts[rank] = {};
            }
            if (!nonEmptyRankCounts[rank]!.containsKey(ratingKey)) {
              nonEmptyRankCounts[rank]![ratingKey] = 0;
            }
            nonEmptyRankCounts[rank]![ratingKey] = (nonEmptyRankCounts[rank]![ratingKey] ?? 0) + 1;
            break;
          }
        }
      }
    }

    return nonEmptyRankCounts;
  }

  List<dynamic> _filterContestsByDivision(List<dynamic> contests) {
    if (_selectedDivision == 'Div. 1') return contests.where((contest) => contest['name'].toString().toLowerCase().contains('div. 1')).toList();
    if (_selectedDivision == 'Div. 2') return contests.where((contest) => contest['name'].toString().toLowerCase().contains('div. 2')).toList();
    if (_selectedDivision == 'Div. 3') return contests.where((contest) => contest['name'].toString().toLowerCase().contains('div. 3')).toList();
    if (_selectedDivision == 'Div. 4') return contests.where((contest) => contest['name'].toString().toLowerCase().contains('div. 4')).toList();
    if (_selectedDivision == 'Global') return contests.where((contest) => !contest['name'].toString().toLowerCase().contains('div')).toList();
    if (_selectedDivision == 'Div. 1 + Div. 2') return contests.where((contest) => contest['name'].toString().toLowerCase().contains('div. 1') || contest['name'].toString().toLowerCase().contains('div. 2')).toList();
    return contests;
  }

  Map<String, dynamic> getTopicStats(List<dynamic> submissions) {
    Map<String, Set<String>> solvedByTag = {};
    Map<String, int> failedAttemptsByTag = {};
    Map<String, ({
      int correctAttempts,
      int wrongAttempts,
      int totalAttempts,
      double successRate
    })> topicStats = {};

    // Calculate total submissions for threshold
    final int totalSubmissions = submissions.length;
    final int minimumSubmissions = (totalSubmissions * 0.03).ceil(); // 3% threshold

    // Collect solved and failed attempts
    for (var submission in submissions) {
      if (submission['problem']['tags'] != null) {
        List<dynamic> tags = submission['problem']['tags'];
        String problemId = '${submission['problem']['contestId']}-${submission['problem']['index']}';
        String verdict = submission['verdict'];

        for (var tag in tags) {
          if (verdict == 'OK') {
            if (!solvedByTag.containsKey(tag)) {
              solvedByTag[tag] = {};
            }
            solvedByTag[tag]!.add(problemId);
          }

          if (verdict != 'OK') {
            failedAttemptsByTag[tag] = (failedAttemptsByTag[tag] ?? 0) + 1;
          }
        }
      }
    }

    // Combine stats and calculate percentages
    for (var tag in {...solvedByTag.keys, ...failedAttemptsByTag.keys}) {
      final correctAttempts = solvedByTag[tag]?.length ?? 0;
      final wrongAttempts = failedAttemptsByTag[tag] ?? 0;
      final totalAttempts = correctAttempts + wrongAttempts;

      // Only include tags with more than 3% of total submissions
      if (totalAttempts >= minimumSubmissions) {
        final successRate = totalAttempts > 0 ? (correctAttempts / totalAttempts * 100) : 0.0;

        topicStats[tag] = (
          correctAttempts: correctAttempts,
          wrongAttempts: wrongAttempts,
          totalAttempts: totalAttempts,
          successRate: successRate
        );
      }
    }

    // Sort by success rate
    var sortedTopics = topicStats.entries.toList()
      ..sort((a, b) => b.value.successRate.compareTo(a.value.successRate));

    // Get top 5 and bottom 5
    var top5 = sortedTopics.take(5).toList();
    var worst5 = sortedTopics.reversed.take(5).toList();

    return {
      'top5': top5,
      'worst5': worst5,
    };
  }

  Widget _buildContestStatsCard(List<dynamic> submissions, List<dynamic> contests) {
    String selectedDivision = _divisions[0];
    Map<String, int> indexCounts = {};

    void updateIndexCounts(StateSetter setState) {
      indexCounts.clear();
      final filteredContests = _filterContestsByDivision(contests);
      final filteredContestIds = filteredContests.map((c) => c['id'] as int).toSet();
      Map<String, Map<String, int>> indexStats = {};

      for (var submission in submissions) {
        if (submission['author']['participantType'] == 'CONTESTANT') {
          final problem = submission['problem'];
          final contestId = problem['contestId'] as int;
          final index = problem['index'];

          if (filteredContestIds.contains(contestId)) {
            final baseIndex = index.substring(0, 1);

            if (!indexStats.containsKey(baseIndex)) {
              indexStats[baseIndex] = {
                'attempts': 0,
                'solves': 0,
              };
            }

            indexStats[baseIndex]!['attempts'] = (indexStats[baseIndex]!['attempts'] ?? 0) + 1;
            if (submission['verdict'] == 'OK') {
              indexStats[baseIndex]!['solves'] = (indexStats[baseIndex]!['solves'] ?? 0) + 1;
              indexCounts[baseIndex] = (indexCounts[baseIndex] ?? 0) + 1;
            }
          }
        }
      }

      indexCounts = Map.fromEntries(
        indexCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
    }

    return StatefulBuilder(
      builder: (context, setState) {
        updateIndexCounts(setState);

        return Card(
          elevation: 4,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contest Problem Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: selectedDivision,
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    items: _divisions.map((division) {
                      return DropdownMenuItem<String>(
                        value: division,
                        child: Text(division),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedDivision = value;
                          _selectedDivision = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalBars = indexCounts.length;
                      final availableWidth = constraints.maxWidth;
                      const barSpacing = 10.0;
                      final barWidth = totalBars > 0
                          ? (availableWidth - (barSpacing * (totalBars - 1))) / totalBars
                          : 0;

                      return BarChart(
                        BarChartData(
                          backgroundColor: Colors.purple.withOpacity(0.15),
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (indexCounts.isEmpty ? 1 : indexCounts.values.reduce((a, b) => a > b ? a : b)).toDouble() + 10,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final keys = indexCounts.keys.toList();
                                final index = keys[group.x.toInt()];
                                final count = indexCounts[index];
                                return BarTooltipItem(
                                  '$count problems',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final keys = indexCounts.keys.toList();
                                  if (value < 0 || value >= keys.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      keys[value.toInt()],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                maxIncluded: false,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: true),
                          barGroups: indexCounts.entries.map((entry) {
                            int x = indexCounts.keys.toList().indexOf(entry.key);
                            return BarChartGroupData(
                              x: x,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.toDouble(),
                                  color: Colors.purple,
                                  width: barWidth * 0.8,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBarGraph(Map<int, int> rankData, Color rankColor) {
    final maxProblems = rankData.values.isNotEmpty ? rankData.values.reduce(max) : 1;
    final sortedEntries = rankData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final total = rankData.values.isNotEmpty ? rankData.values.reduce((a, b) => a + b) : 0;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxProblems.toDouble() + 50,
              backgroundColor: rankColor.withOpacity(0.1),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} problems',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= sortedEntries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${sortedEntries[value.toInt()].key}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    maxIncluded: false,
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxProblems > 0) ? max(10, maxProblems / 5) : 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[400],
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
              ),
              barGroups: sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data.value.toDouble(),
                      color: rankColor,
                      width: 45,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: rankColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: rankColor.withOpacity(0.2)),
          ),
          child: Text(
            'Total Problems: $total',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicStatsCard(List<dynamic> submissions) {
    final topicStats = getTopicStats(submissions);
    final bestTopics = topicStats['top5'] as List<MapEntry<String, ({
      int correctAttempts,
      int wrongAttempts,
      int totalAttempts,
      double successRate
    })>>;
    final worstTopics = topicStats['worst5'] as List<MapEntry<String, ({
      int correctAttempts,
      int wrongAttempts,
      int totalAttempts,
      double successRate
    })>>;

    Color getColorForSuccessRate(double rate) {
      if (rate >= 80) return Colors.green;
      if (rate >= 60) return Colors.blue;
      if (rate >= 40) return Colors.orange;
      return Colors.red;
    }

    Widget buildTopicItem(MapEntry<String, ({
      int correctAttempts,
      int wrongAttempts,
      int totalAttempts,
      double successRate
    })> entry) {
      final topic = entry.key;
      final stats = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${stats.successRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: getColorForSuccessRate(stats.successRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                // Background progress bar
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Success rate progress bar
                FractionallySizedBox(
                  widthFactor: stats.successRate / 100,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          getColorForSuccessRate(stats.successRate).withOpacity(0.7),
                          getColorForSuccessRate(stats.successRate),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Stats text
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '✓ ${stats.correctAttempts}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '✗ ${stats.wrongAttempts}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Total attempts: ${stats.totalAttempts}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Topic Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Best Topics Section
            const Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Best Performing Topics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...bestTopics.map(buildTopicItem),
            const Divider(height: 32),
            // Worst Topics Section
            const Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Topics Needing Improvement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...worstTopics.map(buildTopicItem),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStatsCard(List<dynamic> submissions) {
    Map<String, dynamic> getSubmissionStats() {
      Map<String, int> verdictCounts = {
        'Accepted': 0,
        'Wrong Answer': 0,
        'Time Limit': 0,
        'Others': 0
      };
      Map<String, Set<String>> problemAttempts = {};
      int total = submissions.length;

      for (var submission in submissions) {
        String verdict = submission['verdict'];
        if (verdict == 'OK') {
          verdictCounts['Accepted'] = verdictCounts['Accepted']! + 1;
        } else if (verdict == 'WRONG_ANSWER') {
          verdictCounts['Wrong Answer'] = verdictCounts['Wrong Answer']! + 1;
        } else if (verdict == 'TIME_LIMIT_EXCEEDED') {
          verdictCounts['Time Limit'] = verdictCounts['Time Limit']! + 1;
        } else {
          verdictCounts['Others'] = verdictCounts['Others']! + 1;
        }

        String problemId = '${submission['problem']['contestId']}-${submission['problem']['index']}';
        if (!problemAttempts.containsKey(problemId)) {
          problemAttempts[problemId] = {};
        }
        problemAttempts[problemId]!.add(verdict);
      }

      int problemsWithMultipleAttempts = problemAttempts.values
          .where((attempts) => attempts.length > 1 && attempts.contains('OK'))
          .length;

      return {
        'verdicts': verdictCounts,
        'total': total,
        'multipleAttempts': problemsWithMultipleAttempts,
        'uniqueProblems': problemAttempts.length,
      };
    }

    final stats = getSubmissionStats();
    final verdictColors = {
      'Accepted': Colors.green,
      'Wrong Answer': Colors.red,
      'Time Limit': Colors.orange,
      'Others': Colors.grey,
    };

    final Map<String, int> verdicts = stats['verdicts'];
    final acceptanceRate = (verdicts['Accepted'] ?? 0) / stats['total'] * 100;
    final avgAttempts = stats['multipleAttempts'] > 0
        ? (stats['total'] - (verdicts['Accepted'] ?? 0)) / stats['multipleAttempts']
        : 0.0;

    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submission Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: 180,
                    pieTouchData: PieTouchData(
                      enabled: true,
                    ),
                    sections: verdicts.entries.map((entry) {
                      final verdict = entry.key;
                      final count = entry.value;
                      final percentage = (count / stats['total'] * 100);
                      return PieChartSectionData(
                        color: verdictColors[verdict]!,
                        value: count.toDouble(),
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 80,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        titlePositionPercentageOffset: 0.7,
                        borderSide: BorderSide(
                          color: Colors.grey[600]!,
                          width: 3,
                        ),
                        showTitle: true,
                      );
                    }).toList(),
                  ),
                  duration: const Duration(milliseconds: 500),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: verdicts.entries.map((entry) {
                final verdict = entry.key;
                final count = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: verdictColors[verdict] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$verdict ($count)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                _buildStatItem(FontAwesomeIcons.fileLines, 'Total Submissions:', '${stats['total']}'),
                _buildStatItem(FontAwesomeIcons.circleQuestion, 'Total Problems:', '${stats['uniqueProblems']}'),
                _buildStatItem(FontAwesomeIcons.check, 'Acceptance Rate:', '${acceptanceRate.toStringAsFixed(2)}%'),
                _buildStatItem(FontAwesomeIcons.circleXmark, 'Avg Incorrect Attempts:', avgAttempts.toStringAsFixed(0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
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
      },
    );
  }

  Widget _buildRankStatsCard() {
    List<String> getSortedRankKeys() {
      final rankOrder = [
        'newbie', 'pupil', 'specialist', 'expert', 'candidate',
        'master', 'international', 'grandmaster', 'legendary'
      ];
      return rankOrder.where((rank) => rankCounts.containsKey(rank)).toList();
    }

    final sortedRankKeys = getSortedRankKeys();

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          elevation: 7,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Problem Rating Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                DropdownButton<int>(
                  dropdownColor: Colors.white,
                  value: _currentPage,
                  isExpanded: true,
                  items: sortedRankKeys.asMap().entries.map((mapEntry) {
                    final menuIndex = mapEntry.key;
                    final rankKey = mapEntry.value;
                    final menuRank = rankInfo[rankKey]!;

                    return DropdownMenuItem<int>(
                      value: menuIndex,
                      child: Text(
                        menuRank['name'],
                        style: TextStyle(
                          color: menuRank['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (index) {
                    if (index != null) {
                      setState(() {
                        _currentPage = index;
                      });
                      _pageController.jumpToPage(index);
                    }
                  },
                ),
                SizedBox(
                  height: 330,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: sortedRankKeys.length,
                    itemBuilder: (context, index) {
                      final rankKey = sortedRankKeys[index];
                      final rank = rankInfo[rankKey]!;
                      final rankData = rankCounts[rankKey]!;
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0, right: 10.0, left: 10.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: buildBarGraph(
                                  rankData,
                                  rank['color'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
            'Statistics',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.purple,
          surfaceTintColor: Colors.purple,
        ),
        body: FutureBuilder(
          future: Future.wait([submissions, problems, contests]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: const LoadingCard(primaryColor: Colors.purple),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorWidget();
            }

            rankCounts = processSubmissions(
              snapshot.data![0] as List<dynamic>,
              snapshot.data![1] as Map<String, dynamic>,
            );

            return RefreshIndicator(
              color: Colors.black,
              backgroundColor: Colors.purple,
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSubmissionStatsCard(snapshot.data![0] as List<dynamic>),
                      const SizedBox(height: 16),
                      _buildRankStatsCard(),
                      const SizedBox(height: 16),
                      _buildContestStatsCard(snapshot.data![0] as List<dynamic>, snapshot.data![2] as List<dynamic>),
                      const SizedBox(height: 16),
                      _buildTopicStatsCard(snapshot.data![0] as List<dynamic>),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
              backgroundColor: Colors.purple,
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

