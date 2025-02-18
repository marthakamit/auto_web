import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MaterialApp(
    home: PaginatedCommentsScreen(),
  ));
}

class PaginatedCommentsScreen extends StatefulWidget {
  const PaginatedCommentsScreen({super.key});

  @override
  _PaginatedCommentsScreenState createState() => _PaginatedCommentsScreenState();
}

class _PaginatedCommentsScreenState extends State<PaginatedCommentsScreen> {
  final List<Map<String, dynamic>> _comments = [];
  int _page = 1;
  final int _limit = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalRound = 1; // Count of total rounds
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _scrollController.addListener(_scrollListener);
  }

  // Fetch comments with pagination
  Future<void> _fetchComments() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/comments',
        queryParameters: {'_page': _page, '_limit': _limit},
      );

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> newComments = List<Map<String, dynamic>>.from(response.data);

        // Check if id == 500, then reset everything and increase totalRound
        if (newComments.any((comment) => comment['id'] == 500)) { //500
          setState(() => _totalRound++); // Increase total round count
          _resetPagination();
          return;
        }

        setState(() {
          _comments.addAll(newComments);
          _isLoading = false;
          _page++;
          if (newComments.length < _limit) _hasMore = false; // No more data
        });

        // Auto-scroll to last element after new page loads
        Future.delayed(const Duration(milliseconds: 500), () {
          _scrollToLastElement();
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching comments: $e');
    }
  }

  // Reset everything and start from the first page
  void _resetPagination() {
    setState(() {
      _comments.clear();
      _page = 1;
      _hasMore = true;
      _isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchComments();
    });
  }

  // Scroll to the last element after each fetch
  void _scrollToLastElement() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  // Scroll listener to auto-fetch the next page
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      _fetchComments();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pagination & Reset Feature")),
      body: Column(
        children: [
          // Display Total Rounds
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey.shade100,
            child: Text(
              "Total Rounds: $_totalRound",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // ListView to display comments
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _comments.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _comments.length) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                final comment = _comments[index];
                return ListTile(
                  title: Text(comment['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(comment['body']),
                  trailing: Text("#${comment['id']}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
