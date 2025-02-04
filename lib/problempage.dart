import 'package:cf_buddy/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:cf_buddy/services.dart';

class ProblemPage extends StatefulWidget {
  final int contestId;
  final String index;
  
  const ProblemPage({
    super.key,
    required this.contestId,
    required this.index,
  });

  @override
  State<ProblemPage> createState() => _ProblemPageState();
}

class _ProblemPageState extends State<ProblemPage> {
  late Future<ProblemDetails> problemDetails;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    problemDetails = ApiService().getProblemDetails(widget.contestId, widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          title: Text(
            'Problem ${widget.contestId}${widget.index}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.teal,
          surfaceTintColor: Colors.teal,
        ),
        body: FutureBuilder<ProblemDetails>(
          future: problemDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingCard(primaryColor: Colors.teal);
            }
      
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorWidget();
            }
      
            final problem = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProblemCard(problem),
                  const SizedBox(height: 16),
                  _buildSpecificationCard(
                    title: 'Input',
                    content: problem.inputSpec,
                    icon: Icons.input_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildSpecificationCard(
                    title: 'Output',
                    content: problem.outputSpec,
                    icon: Icons.output_rounded,
                  ),
                  const SizedBox(height: 16),
                  ...problem.examples.asMap().entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildExampleCard(
                          index: entry.key + 1,
                          input: entry.value['input']!,
                          output: entry.value['output']!,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProblemCard(ProblemDetails problem) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.teal, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    problem.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              problem.statement,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard({
    required int index,
    required String input,
    required String output,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Example $index',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Input:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          input,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Output:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          output,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load problem',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}