import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class CallLogScreen extends StatefulWidget {
  const CallLogScreen({super.key});

  @override
  State<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> with SingleTickerProviderStateMixin {
  List<CallLogEntry> _callLogs = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late TabController _tabController;
  Map<CallType, List<CallLogEntry>> _categorizedCalls = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _getCallLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCallLogs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (await Permission.phone.request().isGranted) {
      try {
        Iterable<CallLogEntry> callLogs = await CallLog.get();
        
        // Categorize calls by type
        Map<CallType, List<CallLogEntry>> categorized = {};
        for (var call in callLogs) {
          final type = call.callType ?? CallType.incoming;
          if (!categorized.containsKey(type)) {
            categorized[type] = [];
          }
          categorized[type]!.add(call);
        }

        setState(() {
          _callLogs = callLogs.toList();
          _categorizedCalls = categorized;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = "Error fetching call logs: $e";
        });
        print("Error fetching call logs: $e");
      }
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Phone permission is required to access call logs.";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone permission is required to access call logs."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getCallTypeColor(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return Colors.green;
      case CallType.outgoing:
        return Colors.blue;
      case CallType.missed:
        return Colors.red;
      case CallType.rejected:
        return Colors.orange;
      case CallType.blocked:
        return Colors.purple;
      case CallType.voiceMail:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Icon _getCallTypeIcon(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return Icon(Icons.call_received, color: _getCallTypeColor(callType));
      case CallType.outgoing:
        return Icon(Icons.call_made, color: _getCallTypeColor(callType));
      case CallType.missed:
        return Icon(Icons.call_missed, color: _getCallTypeColor(callType));
      case CallType.rejected:
        return Icon(Icons.call_end, color: _getCallTypeColor(callType));
      case CallType.blocked:
        return Icon(Icons.block, color: _getCallTypeColor(callType));
      case CallType.voiceMail:
        return Icon(Icons.voicemail, color: _getCallTypeColor(callType));
      default:
        return Icon(Icons.call, color: _getCallTypeColor(callType));
    }
  }

  String _getCallTypeText(CallType? callType) {
    switch (callType) {
      case CallType.incoming:
        return "Incoming";
      case CallType.outgoing:
        return "Outgoing";
      case CallType.missed:
        return "Missed";
      case CallType.rejected:
        return "Rejected";
      case CallType.blocked:
        return "Blocked";
      case CallType.voiceMail:
        return "Voicemail";
      default:
        return "Unknown";
    }
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'Unknown';
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today, ${DateFormat.jm().format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat('MMM d, y - h:mm a').format(date);
    }
  }

  String _durationToString(int? duration) {
    if (duration == null || duration == 0) return 'No duration';
    final Duration d = Duration(seconds: duration);
    
    if (d.inHours > 0) {
      return '${d.inHours}h ${(d.inMinutes % 60)}m ${(d.inSeconds % 60)}s';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${(d.inSeconds % 60)}s';
    } else {
      return '${d.inSeconds}s';
    }
  }

  Widget _buildCallItem(CallLogEntry call) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCallTypeColor(call.callType).withOpacity(0.2),
          radius: 25,
          child: _getCallTypeIcon(call.callType),
        ),
        title: Text(
          call.name?.isNotEmpty == true ? call.name! : (call.number ?? "Unknown"),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (call.name?.isNotEmpty == true) 
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  call.number ?? "Unknown number",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatDate(call.timestamp),
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Text(
                    _getCallTypeText(call.callType),
                    style: TextStyle(
                      color: _getCallTypeColor(call.callType),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _durationToString(call.duration),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.blue),
          onPressed: () {
            // Implement call functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Calling ${call.number}"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        onLongPress: () {
          // Show options menu
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.call),
                  title: const Text('Call'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement call
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.message),
                  title: const Text('Message'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement message
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Block number'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement block
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(List<CallLogEntry>? calls) {
    if (calls == null || calls.isEmpty) {
      return const Center(
        child: Text("No call records found"),
      );
    }

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) => _buildCallItem(calls[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Call Logs", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.blue,
          tabs: [
            const Tab(text: "All"),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_received, color: _getCallTypeColor(CallType.incoming), size: 16),
                  const SizedBox(width: 4),
                  const Text("Incoming"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_made, color: _getCallTypeColor(CallType.outgoing), size: 16),
                  const SizedBox(width: 4),
                  const Text("Outgoing"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_missed, color: _getCallTypeColor(CallType.missed), size: 16),
                  const SizedBox(width: 4),
                  const Text("Missed"),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, color: _getCallTypeColor(CallType.rejected), size: 16),
                  const SizedBox(width: 4),
                  const Text("Rejected"),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _getCallLogs,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(_callLogs),
                    _buildTabContent(_categorizedCalls[CallType.incoming]),
                    _buildTabContent(_categorizedCalls[CallType.outgoing]),
                    _buildTabContent(_categorizedCalls[CallType.missed]),
                    _buildTabContent(_categorizedCalls[CallType.rejected]),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCallLogs,
        tooltip: 'Refresh Logs',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}