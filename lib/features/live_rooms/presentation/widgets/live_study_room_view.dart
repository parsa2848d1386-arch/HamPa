import 'package:flutter/material.dart';
import '../../domain/models/live_study_room_state.dart';

class LiveStudyRoomView extends StatelessWidget {
  final LiveStudyRoomState roomState;
  final void Function(String peerId)? onSendCheer;

  const LiveStudyRoomView({
    super.key,
    required this.roomState,
    this.onSendCheer,
  });

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(roomState.roomName),
        actions: [
          Chip(
            label: Text('${roomState.peers.where((p) => p.status == PeerPresenceStatus.studying).length} Studying'),
            backgroundColor: Colors.green.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: roomState.peers.length,
        itemBuilder: (context, index) {
          final peer = roomState.peers[index];
          final isStudying = peer.status == PeerPresenceStatus.studying;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isStudying ? Colors.green : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isStudying ? Colors.green.shade100 : Colors.grey.shade200,
                    child: Text(
                      peer.displayName.isNotEmpty ? peer.displayName[0] : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isStudying ? Colors.green.shade800 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    peer.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (peer.activeSubject != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      peer.activeSubject!,
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(peer.elapsedSeconds),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => onSendCheer?.call(peer.id),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                            const SizedBox(width: 2),
                            Text(
                              '${peer.cheersReceived}',
                              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
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
        },
      ),
    );
  }
}
