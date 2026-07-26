import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/block_survey.dart';
import '../../models/survey_deletion_log.dart';
import '../../services/survey_repository.dart';
import '../survey/survey_detail_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    required this.isAdmin,
    required this.currentUserId,
    required this.currentUserName,
  });

  final bool isAdmin;
  final String currentUserId;
  final String currentUserName;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _repository = SurveyRepository();
  final _reviewingSurveyIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BlockSurvey>>(
      stream: _repository.watchSurveys(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _NotificationError(error: snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<SurveyDeletionLog>>(
          stream: _repository.watchDeletionLogs(),
          builder: (context, deletionSnapshot) {
            if (deletionSnapshot.hasError) {
              return _NotificationError(error: deletionSnapshot.error!);
            }
            if (!deletionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildNotifications(
              snapshot.data!,
              deletionSnapshot.data!,
            );
          },
        );
      },
    );
  }

  Widget _buildNotifications(
    List<BlockSurvey> allSurveys,
    List<SurveyDeletionLog> deletionLogs,
  ) {
    final surveys = allSurveys.where((survey) {
      return widget.isAdmin ||
          survey.isApproved ||
          survey.createdBy == widget.currentUserId;
    }).toList();
    final entries = <_ActivityEntry>[
      ...surveys.map(_ActivityEntry.survey),
      ...deletionLogs.map(_ActivityEntry.deletion),
    ]..sort((first, second) {
        final firstDate = first.activityAt;
        final secondDate = second.activityAt;
        if (firstDate == null && secondDate == null) {
          return 0;
        }
        if (firstDate == null) {
          return 1;
        }
        if (secondDate == null) {
          return -1;
        }
        return secondDate.compareTo(firstDate);
      });
    final pendingCount = allSurveys.where((survey) => survey.isPending).length;

    return RefreshIndicator(
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _NotificationHeader(
            isAdmin: widget.isAdmin,
            pendingCount: pendingCount,
          ),
          const SizedBox(height: 18),
          Text(
            'Recent activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const _EmptyNotifications()
          else
            for (var index = 0; index < entries.length; index++) ...[
              if (entries[index].survey != null)
                _ActivityCard(
                  survey: entries[index].survey!,
                  isAdmin: widget.isAdmin,
                  showReviewActions:
                      widget.isAdmin && entries[index].survey!.isPending,
                  reviewing: _reviewingSurveyIds.contains(
                    entries[index].survey!.id,
                  ),
                  onApprove: () => _review(
                    entries[index].survey!,
                    approve: true,
                  ),
                  onReject: () => _review(
                    entries[index].survey!,
                    approve: false,
                  ),
                )
              else
                _DeletionActivityCard(log: entries[index].deletionLog!),
              if (index != entries.length - 1)
                const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  Future<void> _review(
    BlockSurvey survey, {
    required bool approve,
  }) async {
    String reviewNote = '';

    if (approve) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.verified_outlined),
          title: const Text('Approve this survey?'),
          content: Text(
            '${survey.blockName} will be added to the approved survey map.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    } else {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.cancel_outlined),
          title: const Text('Reject this survey?'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Reason or correction required',
              hintText: 'Optional note for the surveyor',
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (result == null) {
        return;
      }
      reviewNote = result;
    }

    if (!mounted) {
      return;
    }
    setState(() => _reviewingSurveyIds.add(survey.id));
    try {
      await _repository.reviewSurvey(
        surveyId: survey.id,
        approve: approve,
        reviewerId: widget.currentUserId,
        reviewerName: widget.currentUserName.isEmpty
            ? 'Administrator'
            : widget.currentUserName,
        reviewNote: reviewNote,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '${survey.blockName} was approved.'
                : '${survey.blockName} was rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not review the survey.\n$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _reviewingSurveyIds.remove(survey.id));
      }
    }
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({
    required this.isAdmin,
    required this.pendingCount,
  });

  final bool isAdmin;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isAdmin
                    ? Icons.admin_panel_settings_outlined
                    : Icons.notifications_active_outlined,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin
                        ? '$pendingCount awaiting approval'
                        : 'Survey notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isAdmin
                        ? 'Review surveyor submissions before they appear on '
                              'the approved map and follow deletion activity.'
                        : 'See survey approvals, rejections, and deletions.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry.survey(BlockSurvey value)
    : survey = value,
      deletionLog = null;

  const _ActivityEntry.deletion(SurveyDeletionLog value)
    : survey = null,
      deletionLog = value;

  final BlockSurvey? survey;
  final SurveyDeletionLog? deletionLog;

  DateTime? get activityAt => survey?.activityAt ?? deletionLog?.deletedAt;
}

class _DeletionActivityCard extends StatelessWidget {
  const _DeletionActivityCard({required this.log});

  final SurveyDeletionLog log;

  @override
  Widget build(BuildContext context) {
    final deletedAt = log.deletedAt == null
        ? 'Synchronizing time…'
        : DateFormat('d MMM yyyy, h:mm a').format(log.deletedAt!.toLocal());
    final deletedBy = log.deletedByName.trim().isEmpty
        ? 'An administrator'
        : log.deletedByName;
    final originalCreator = log.originalCreatedByName.trim().isEmpty
        ? 'an unknown user'
        : log.originalCreatedByName;
    final color = Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.delete_forever_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Survey deleted',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$deletedBy deleted ${log.blockName}, originally added '
                    'by $originalCreator.',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _ActivityMeta(
                        icon: Icons.hub_outlined,
                        text: log.centralName,
                      ),
                      _ActivityMeta(
                        icon: Icons.schedule_rounded,
                        text: deletedAt,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.survey,
    required this.isAdmin,
    required this.showReviewActions,
    required this.reviewing,
    required this.onApprove,
    required this.onReject,
  });

  final BlockSurvey survey;
  final bool isAdmin;
  final bool showReviewActions;
  final bool reviewing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final presentation = _ActivityPresentation.fromSurvey(survey);
    final activityDate = survey.activityAt;
    final formattedDate = activityDate == null
        ? 'Synchronizing time…'
        : DateFormat(
            'd MMM yyyy, h:mm a',
          ).format(activityDate.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SurveyDetailScreen(
              survey: survey,
              isAdmin: isAdmin,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: presentation.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      presentation.icon,
                      color: presentation.color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          presentation.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(presentation.message),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            _ActivityMeta(
                              icon: Icons.hub_outlined,
                              text: survey.centralName,
                            ),
                            _ActivityMeta(
                              icon: Icons.schedule_rounded,
                              text: formattedDate,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              if (survey.reviewNote.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Review note: ${survey.reviewNote}'),
                ),
              ],
              if (showReviewActions) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: reviewing ? null : onReject,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: reviewing ? null : onApprove,
                        icon: reviewing
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(reviewing ? 'Saving…' : 'Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityMeta extends StatelessWidget {
  const _ActivityMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ActivityPresentation {
  const _ActivityPresentation({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;

  factory _ActivityPresentation.fromSurvey(BlockSurvey survey) {
    final blockName = survey.blockName;
    final creator = survey.createdByName.isEmpty
        ? 'A surveyor'
        : survey.createdByName;
    final reviewer = survey.reviewedByName.isEmpty
        ? 'An administrator'
        : survey.reviewedByName;

    if (survey.isPending) {
      return _ActivityPresentation(
        title: 'Approval required',
        message: '$creator submitted $blockName for approval.',
        icon: Icons.pending_actions_rounded,
        color: Colors.orange.shade700,
      );
    }

    if (survey.isRejected) {
      return _ActivityPresentation(
        title: 'Survey rejected',
        message: '$reviewer rejected $blockName, submitted by $creator.',
        icon: Icons.cancel_outlined,
        color: Colors.red.shade700,
      );
    }

    if (survey.wasAddedDirectlyByAdmin) {
      return _ActivityPresentation(
        title: 'Survey added',
        message: '$creator added and approved $blockName.',
        icon: Icons.add_task_rounded,
        color: Colors.green.shade700,
      );
    }

    return _ActivityPresentation(
      title: 'Survey approved',
      message: '$reviewer approved $blockName, submitted by $creator.',
      icon: Icons.verified_rounded,
      color: Colors.green.shade700,
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.notifications_none_rounded, size: 52),
            const SizedBox(height: 12),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Survey submissions, approval decisions, and deletions will '
              'appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load notifications.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
