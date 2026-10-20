import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/focus_session_state.dart';
import '../controllers/focus_timer_cubit.dart';

class FocusTimerView extends StatelessWidget {
  final VoidCallback? onOpenScratchpad;

  const FocusTimerView({super.key, this.onOpenScratchpad});

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<FocusTimerCubit, FocusSessionState>(
      builder: (context, state) {
        final cubit = context.read<FocusTimerCubit>();
        final displaySeconds = (state.mode == TimerMode.pomodoro || state.mode == TimerMode.exam)
            ? (state.targetSeconds - state.elapsedSeconds).clamp(0, state.targetSeconds)
            : state.elapsedSeconds;

        return Scaffold(
          backgroundColor: state.isStrictLockActive ? Colors.black : theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              state.mode == TimerMode.pomodoro
                  ? 'Pomodoro Focus'
                  : state.mode == TimerMode.exam
                      ? 'Exam Countdown'
                      : 'Stopwatch',
              style: TextStyle(
                color: state.isStrictLockActive ? Colors.white70 : theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  state.isStrictLockActive ? Icons.lock : Icons.lock_open,
                  color: state.isStrictLockActive ? Colors.redAccent : Colors.grey,
                ),
                tooltip: 'Strict Anti-Distraction Lock',
                onPressed: () => cubit.toggleStrictLock(),
              ),
              IconButton(
                icon: Icon(
                  state.isAmbientSoundPlaying ? Icons.volume_up : Icons.volume_off,
                  color: state.isAmbientSoundPlaying ? theme.colorScheme.primary : Colors.grey,
                ),
                tooltip: 'Ambient Soundscape',
                onPressed: () => cubit.toggleAmbientSound('Rain & Coffee'),
              ),
              if (onOpenScratchpad != null)
                IconButton(
                  icon: const Icon(Icons.note_alt_outlined),
                  tooltip: 'In-Session Scratchpad',
                  onPressed: onOpenScratchpad,
                ),
            ],
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Task & Subject display
                  if (state.taskTitle != null || state.subjectName != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          if (state.taskTitle != null)
                            Text(
                              state.taskTitle!,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: state.isStrictLockActive ? Colors.white : theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (state.subjectName != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: state.isStrictLockActive
                                    ? Colors.white24
                                    : theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state.subjectName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: state.isStrictLockActive
                                      ? Colors.white
                                      : theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Interruption badge & Grace period alert
                  if (state.isGracePeriodActive) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        'Anti-distraction: Return to app in ${state.graceRemainingSeconds}s',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else if (state.interruptionCount > 0) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'Interruptions: ${state.interruptionCount} (${state.interruptionDurationSeconds}s)',
                            style: const TextStyle(fontSize: 12, color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Timer circular display
                  Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: state.isRunning
                          ? (state.isStrictLockActive ? Colors.redAccent : theme.colorScheme.primary)
                          : theme.dividerColor,
                      width: 8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(displaySeconds),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: state.isStrictLockActive ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (state.mode == TimerMode.pomodoro || state.mode == TimerMode.exam)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Target: ${_formatTime(state.targetSeconds)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: state.isStrictLockActive ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!state.isRunning && !state.isPaused)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Focus'),
                        onPressed: () => cubit.startTimer(
                          subjectId: state.activeSubjectId ?? 'default_subject',
                          mode: state.mode,
                        ),
                      ),
                    if (state.isRunning) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Lap'),
                        onPressed: () => cubit.recordLap(),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                        onPressed: () => cubit.pauseTimer(),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Finish'),
                        onPressed: () => cubit.completeSession(),
                      ),
                    ],
                    if (state.isPaused) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Resume'),
                        onPressed: () => cubit.resumeTimer(),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Discard', style: TextStyle(color: Colors.red)),
                        onPressed: () => cubit.discardSession(),
                      ),
                    ],
                  ],
                ),

                // Laps list
                if (state.laps.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 100,
                    width: 300,
                    child: ListView.builder(
                      itemCount: state.laps.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Lap ${i + 1}', style: const TextStyle(color: Colors.grey)),
                              Text(_formatTime(state.laps[i]), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
  }
}
