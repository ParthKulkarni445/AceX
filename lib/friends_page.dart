import 'package:cf_buddy/settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cf_buddy/friends_landpage.dart';
import 'package:cf_buddy/providers/user_provider.dart';
import 'package:cf_buddy/services.dart';
import 'package:cf_buddy/utils/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final storage = const FlutterSecureStorage();
  bool isLoading = true;
  bool hasCredentials = false;
  
  final FocusNode _searchFocusNode = FocusNode();
  late String _handle;
  late Future<List<dynamic>> friends;
  late Future<List<dynamic>> onlineFriends;

  final List<Color> avatarColors = [
    Colors.red[400]!,
    Colors.yellow[600]!,
    Colors.green[400]!,
    Colors.blue[400]!,
    Colors.purple[400]!,
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _checkCredentials();
  }

  Future<void> _checkCredentials() async {
    final apiKey = await storage.read(key: 'api_key');
    final apiSecret = await storage.read(key: 'api_secret');
    
    if (apiKey != null && apiSecret != null) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      _handle = user.handle;
      _fetchData();
      setState(() {
        hasCredentials = true;
        isLoading = false;
      });
    } else {
      setState(() {
        hasCredentials = false;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  void _fetchData() {
    friends = ApiService().fetchFriends(_handle, false);
    onlineFriends = ApiService().fetchFriends(_handle, true);
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
    await Future.wait([friends, onlineFriends]);
  }

  Widget _buildNoCredentialsMessage() {
    return Center(
      child: Card(
        color: Colors.white,
        elevation: 10,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'API Credentials Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please go to Settings and enter your API credentials to view friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 5
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                },
                child: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    return const Color.fromARGB(255, 128, 0, 0);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Friends',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          surfaceTintColor: Colors.blue,
        ),
        body: const Center(child: LoadingCard(primaryColor: Colors.blue)),
      );
    }

    if (!hasCredentials) {
      return Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          centerTitle: true,
          elevation: 15,
          shadowColor: Colors.black,
          title: const Text(
            'Friends',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.blue,
          surfaceTintColor: Colors.blue,
        ),
        body: _buildNoCredentialsMessage(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        centerTitle: true,
        elevation: 15,
        shadowColor: Colors.black,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        surfaceTintColor: Colors.blue,
      ),
      body: FutureBuilder<List<List<dynamic>>>(
        future: Future.wait([onlineFriends, friends]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingCard(primaryColor: Colors.blue),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _buildErrorWidget();
          }

          final onlineFriendsList = snapshot.data![0];
          final allFriendsList = snapshot.data![1];
          final offlineFriendsList = allFriendsList
              .where((friend) => !onlineFriendsList.contains(friend))
              .toList();

          return RefreshIndicator(
            color: Colors.black,
            backgroundColor: Colors.blue,
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildSearchBar(),
                ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, searchQuery, child) {
                    final filteredOnlineFriends = onlineFriendsList
                        .where((friend) =>
                            friend.toString().toLowerCase().contains(searchQuery))
                        .toList();
                    final filteredOfflineFriends = offlineFriendsList
                        .where((friend) =>
                            friend.toString().toLowerCase().contains(searchQuery))
                        .toList();

                    if (onlineFriendsList.isEmpty && allFriendsList.isEmpty) {
                      return Center(child: _buildEmptyState());
                    }
                    if (filteredOnlineFriends.isEmpty &&
                        filteredOfflineFriends.isEmpty &&
                        searchQuery.isNotEmpty) {
                      return Center(child: _buildNoSearchResults());
                    }

                    return Column(
                      children: [
                        ...filteredOnlineFriends
                            .map((friend) => _buildFriendCard(friend, true)),
                        ...filteredOfflineFriends
                            .map((friend) => _buildFriendCard(friend, false)),
                        const SizedBox(height: 60),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      elevation: 7,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          cursorColor: Colors.blue,
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search friends...',
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.grey),
            contentPadding: const EdgeInsets.only(top: 10),
            suffixIcon: ValueListenableBuilder<String>(
              valueListenable: _searchQueryNotifier,
              builder: (context, value, child) {
                return value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchQueryNotifier.value = '';
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
          ),
          onChanged: (value) {
            _searchQueryNotifier.value = value.toLowerCase();
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
            size: 150,
          ),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 150, color: Colors.blue),
          const SizedBox(height: 18),
          Text(
            'No friends found for $_handle',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              elevation: 6,
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 64),
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No friends found matching "$_searchQuery"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(dynamic friend, bool isOnline) {
    final handle = friend;
    final colorIndex = handle.hashCode % avatarColors.length;
    final avatarColor = avatarColors[colorIndex];

    return Card(
      elevation: 7,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: (isOnline) ? Colors.green.withOpacity(0.25) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isOnline
              ? Border.all(
                  color: Colors.green[400]!,
                  width: 1.5,
                )
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            
            Future.delayed(const Duration(milliseconds: 100), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendLandingPage(handle: handle),
                ),
              );
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: avatarColor,
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withOpacity(0.5),
                        blurRadius: isOnline ? 8 : 4,
                        spreadRadius: isOnline ? 1 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (handle.length > 2)
                          ? handle.substring(0, 2).toUpperCase()
                          : handle.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      handle,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    (isOnline)
                        ? Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.green[400],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}