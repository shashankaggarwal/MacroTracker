import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';

class LogEntryManager extends StatefulWidget {
  final Function onLogSubmitted;
  final AdService adService;
  final int logLimit;

  const LogEntryManager({
    required this.onLogSubmitted,
    required this.adService,
    this.logLimit = 3,
    Key? key,
  }) : super(key: key);

  @override
  _LogEntryManagerState createState() => _LogEntryManagerState();
}

class _LogEntryManagerState extends State<LogEntryManager> {
  int _logCount = 0;
  bool _adWatched = false;

  @override
  void initState() {
    super.initState();
    _initLogCount();
  }

  Future<void> _initLogCount() async {
    await _loadLogCount();
  }

  Future<void> _loadLogCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _logCount = prefs.getInt('logCount') ?? 0;
      _adWatched = prefs.getBool('adWatched') ?? false;
    });
  }

  Future<void> _incrementLogCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _logCount++;
      _adWatched = false;
    });
    await prefs.setInt('logCount', _logCount);
    await prefs.setBool('adWatched', _adWatched);
  }

  Future<void> _resetLogCount() async {
    print('_resetLogCount called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('logCount', 0);
    await prefs.setBool('adWatched', true);
    setState(() {
      _logCount = 0;
      _adWatched = true;
    });
    print('_logCount reset to 0');
  }

  void _handleLog() {
    if (_logCount < widget.logLimit) {
      widget.onLogSubmitted();
      _incrementLogCount();
    } else {
      _showAdPrompt();
    }
  }

  void _showAdPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Watch Ad to Continue'),
        content: Text(
            'You have reached your free log limit. Watch an ad to unlock ${widget.logLimit} more log entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.adService.showRewardedAd(() {
                _resetLogCount().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Thank you for watching the ad! You can continue logging.'),
                    ),
                  );
                  setState(() {});
                });
              });
            },
            child: Text('Watch Ad'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _handleLog,
          child: Text('Add to Log'),
        ),
        SizedBox(height: 10),
        Text(
          'Logs remaining before ad: ${widget.logLimit - _logCount}',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
