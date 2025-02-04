import 'dart:convert';
import 'dart:math';
import 'package:cf_buddy/landing_page.dart';
import 'package:cf_buddy/models/user.dart';
import 'package:cf_buddy/providers/user_provider.dart';
import 'package:cf_buddy/utils/constant.dart';
import 'package:cf_buddy/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProblemDetails {
  final String title;
  final String statement;
  final String inputSpec;
  final String outputSpec;
  final List<Map<String, String>> examples;

  ProblemDetails({
    required this.title,
    required this.statement,
    required this.inputSpec,
    required this.outputSpec,
    required this.examples,
  });
}

class AuthService{

  void signUpUser({
    required BuildContext context,
    required String email,
    required String password,
    required String handle,
  }) async {
    try {
      User user = User(
        id: '',
        handle: handle,
        password: password,
        email: email,
        token: '',
      );
      print('${Constants.uri}/api/signup');
      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signup'),
        body: user.toJson(),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(res.body);

      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () {
          showAlert(
            context,
            'Account created! Login with the same credentials!',
          );
        },
      );
    } catch (e) {
      showAlert(context, e.toString());
    }
  }

  void signInUser({
    required BuildContext context,
    required String handle,
    required String password,
  }) async {
    try {
      print('Signing in');
      var userProvider = Provider.of<UserProvider>(context, listen: false);
      final navigator = Navigator.of(context);
      http.Response res = await http.post(
        Uri.parse('${Constants.uri}/api/signin'),
        body: jsonEncode({
          'handle': handle,
          'password': password,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      print(res.body);
      httpErrorHandle(
        response: res,
        context: context,
        onSuccess: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          userProvider.setUser(res.body);
          await prefs.setString('x-auth-token', jsonDecode(res.body)['token']);
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LandingPage(),
            ),
            (route) => false,
          );
        },
      );
    } catch (e) {
      showAlert(context, e.toString());
    }
  }
}

class ApiService {
  final String baseUrl = 'https://codeforces.com/api/'; // Replace with your server's URL if deployed
  final String apiKey = dotenv.env['API_KEY']!; // Get your API key from Codeforces
  final String apiSecret = dotenv.env['API_SECRET']!; // Get your API secret from Codeforces

  Future<ProblemDetails> getProblemDetails(int contestId, String index) async {
    final url = 'https://codeforces.com/problemset/problem/$contestId/$index';
    
    // This would be your actual API endpoint that runs puppeteer
    // For now, returning mock data
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    
    return ProblemDetails(
      title: 'Nuetral Tonality',
      statement: 'Given an array a of n positive integers. In one operation, you can pick any pair of indexes (i,j) such that ai and aj have distinct parity, then replace the smaller one with the sum of them. More formally: \n\nIf ai<aj, replace ai with ai+aj; \nOtherwise, replace aj with ai+aj. \n\nFind the minimum number of operations needed to make all elements of the array have the same parity.',
      inputSpec: 'The first line contains two integers n and m (1 ≤ n, m ≤ 100) — the number of rows and columns in the matrix.',
      outputSpec: 'Print "YES" (without quotes) if it is possible to make the matrix beautiful, or "NO" (without quotes) otherwise.',
      examples: [
        {
          'input': '3\n2 1 3',
          'output': '1 2 3',
        },
        {
          'input': '5\n1 2 3 5 4',
          'output': '1 2 3 4 5',
        },
      ],
    );
  }

  Future<List<dynamic>> getContests() async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/contest.list'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest details');
      }
    } else {
      throw Exception('Failed to load contest details');
    }
  }

  Future<Map<String, dynamic>> getContestDetails(int contestId) async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/contest.standings?contestId=$contestId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest details');
      }
    } else {
      throw Exception('Failed to load contest details');
    }
  }

  //getContestRatingChanges
  Future<List<dynamic>> getContestRatingChanges(int contestId) async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/contest.ratingChanges?contestId=$contestId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load contest rating changes');
      }
    } else {
      throw Exception('Failed to load contest rating changes');
    }
  }

  Future<Map<String,dynamic>> getUserStandings(int contestId, String handle) async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/contest.standings?contestId=$contestId&handles=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user standings');
      }
    } else {
      throw Exception('Failed to fetch user standings');
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String handle) async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/user.info?handles=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'][0];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  Future<List<dynamic>> getRatingHistory(String handle) async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/user.rating?handle=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info 1');
      }
    } else {
      throw Exception('Failed to fetch user info 2');
    }
  }

  Future<List<dynamic>> getSubmissions(String handle) async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/user.status?handle=$handle'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch user info');
      }
    } else {
      throw Exception('Failed to fetch user info');
    }
  }

  Future<Map<String,dynamic>> getProlblemSet() async {
    final response = await http.get(Uri.parse('https://codeforces.com/api/problemset.problems'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch problem set');
      }
    } else {
      throw Exception('Failed to fetch problem set');
    }
  }

  String _generateApiSig(int time, String methodName, String paramString) {
  // Create random string of 6 characters
  final rand = Random().nextInt(900000) + 100000; // Generates a number between 100000 and 999999
  
  // Format: rand/methodName?param1=value1&param2=value2#apiSecret
  final strToHash = '$rand/$methodName?$paramString#$apiSecret';
  
  // Generate SHA512 hash
  final bytes = utf8.encode(strToHash);
  final hash = sha512.convert(bytes);
  
  return '$rand${hash.toString()}';
}

Future<Map<String,dynamic>> getFriendStandings(String handle, int contestId) async {
  //print('Start fetching standings for $handle, ${DateTime.now()}');
    const methodName = 'contest.standings';
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    // Fetch friends' handles
    final friendsInfo = await fetchFriends(handle, false);
    print(friendsInfo);
    final friendsHandles = friendsInfo.join(';');

    // Create parameter string
    final paramString = 'apiKey=$apiKey&contestId=$contestId&handles=$handle;$friendsHandles&time=$time';

    // Generate API signature
    final apiSig = _generateApiSig(time, methodName, paramString);
    //print('$baseUrl$methodName?$paramString&apiSig=$apiSig');
    // Construct full URL with authentication
    final url = Uri.parse(
      '$baseUrl$methodName?$paramString&apiSig=$apiSig'
    );
    print(url);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to fetch standings');
      }
    } else {
      throw Exception('Failed to fetch standings');
    }
}

 Future<List<dynamic>> fetchFriends(String handle, bool isOnline) async {
    const methodName = 'user.friends';
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    
    // Create parameter string
    final paramString = 'apiKey=$apiKey&onlyOnline=$isOnline&time=$time';
    
    // Generate API signature
    final apiSig = _generateApiSig(time, methodName, paramString);
    // Construct full URL with authentication
    final url = Uri.parse(
      '$baseUrl$methodName?$paramString&apiSig=$apiSig'
    );
    print(url);
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['result'];
      } else {
        throw Exception('Failed to load friends list: ${data['comment']}');
      }
    } else {
      throw Exception('Failed to load friends list');
    }
  }

Future<List<dynamic>> getFriendsList(String handle) async {
  //print('Start fetching friends for $handle, ${DateTime.now()}');
  const methodName = 'user.friends';
  final time = (DateTime.now().millisecondsSinceEpoch / 1000).round();
  
  // Create parameter string
  final paramString = 'apiKey=$apiKey&time=$time';
  
  // Generate API signature
  final apiSig = _generateApiSig(time, methodName, paramString);
  
  // Construct full URL with authentication
  final url = Uri.parse(
    '$baseUrl$methodName?$paramString&apiSig=$apiSig'
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      final friends = data['result'];
      //print('Fetched friends for $handle, ${DateTime.now()}');
      return friends;
    } else {
      throw Exception('Failed to fetch friends: ${data['comment'] ?? 'Unknown error'}');
    }
  } else {
    throw Exception('Failed to fetch friends: HTTP ${response.statusCode}');
  }
}



}

