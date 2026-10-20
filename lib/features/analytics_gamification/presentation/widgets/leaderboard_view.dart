import 'package:flutter/material.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../services/leaderboard_service.dart';

class LeaderboardView extends StatefulWidget {
  final List<Map<String, dynamic>>? rawUserStats;
  final List<LeaderboardEntry>? initialEntries;
  final LeaderboardService? leaderboardService;
  final bool initialAnonymizedMode;
  final LeaderboardTier initialTier;
  final ValueChanged<bool>? onAnonymizedChanged;
  final ValueChanged<LeaderboardTier>? onTierChanged;

  const LeaderboardView({
    super.key,
    this.rawUserStats,
    this.initialEntries,
    this.leaderboardService,
    this.initialAnonymizedMode = false,
    this.initialTier = LeaderboardTier.national,
    this.onAnonymizedChanged,
    this.onTierChanged,
  });

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> with SingleTickerProviderStateMixin {
  late final LeaderboardService _service;
  late bool _anonymizedMode;
  late LeaderboardTier _selectedTier;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _service = widget.leaderboardService ?? LeaderboardService();
    _anonymizedMode = widget.initialAnonymizedMode;
    _selectedTier = widget.initialTier;
    _tabController = TabController(
      length: LeaderboardTier.values.length,
      vsync: this,
      initialIndex: _selectedTier.index,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTier = LeaderboardTier.values[_tabController.index];
        });
        widget.onTierChanged?.call(_selectedTier);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LeaderboardEntry> _getEntriesForCurrentTier() {
    if (widget.initialEntries != null && widget.rawUserStats == null) {
      return widget.initialEntries!.where((e) => e.tier == _selectedTier).toList();
    }

    final stats = widget.rawUserStats ?? [];
    return _service.generateLeaderboard(
      rawUserStats: stats,
      tier: _selectedTier,
      anonymizedMode: _anonymizedMode,
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return const Text('🥇', style: TextStyle(fontSize: 22));
    } else if (rank == 2) {
      return const Text('🥈', style: TextStyle(fontSize: 22));
    } else if (rank == 3) {
      return const Text('🥉', style: TextStyle(fontSize: 22));
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _getEntriesForCurrentTier();

    return Column(
      children: [
        // Multi-Tier Tab Bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'National'),
            Tab(text: 'Group'),
            Tab(text: 'Peer'),
          ],
        ),

        // Privacy & Anonymized Mode Switch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _anonymizedMode ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: _anonymizedMode ? theme.colorScheme.primary : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anonymized Mode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _anonymizedMode,
                onChanged: (val) {
                  setState(() {
                    _anonymizedMode = val;
                  });
                  widget.onAnonymizedChanged?.call(val);
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Leaderboard List
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'No participants in this tier yet.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRankBadge(item.rank),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                            child: item.isAnonymous
                                ? const Icon(Icons.person_outline, size: 20)
                                : Text(
                                    item.displayName.isNotEmpty
                                        ? item.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      title: Text(
                        item.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: item.subjectName != null
                          ? Text(
                              item.subjectName!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            )
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.formattedDuration,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
