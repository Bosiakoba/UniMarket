import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/message_thread.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/message_store_scope.dart';
import '../../core/widgets/uni_text_field.dart';
import 'chat_screen.dart';
import 'widgets/inbox_empty_state.dart';
import 'widgets/thread_tile.dart';

enum _InboxFilter { all, unread }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  _InboxFilter _filter = _InboxFilter.all;
  String _query = '';

  List<MessageThread> _visibleThreads(List<MessageThread> threads) {
    var result = threads;
    if (_filter == _InboxFilter.unread) {
      result = result.where((t) => t.unread).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (t) =>
                t.sellerName.toLowerCase().contains(q) ||
                t.preview.toLowerCase().contains(q),
          )
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final store = MessageStoreScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final threads = store.threads;
            final unreadCount = threads.where((t) => t.unread).length;
            final visible = _visibleThreads(threads);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(LucideIcons.arrowLeft),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Messages', style: AppTypography.h2()),
                            if (unreadCount > 0)
                              Text(
                                '$unreadCount unread conversation'
                                '${unreadCount == 1 ? '' : 's'}',
                                style: AppTypography.caption(
                                  color: AppColors.forestGreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: UniTextField(
                    hint: 'Search conversations',
                    prefixIcon: LucideIcons.search,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == _InboxFilter.all,
                        onTap: () =>
                            setState(() => _filter = _InboxFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Unread',
                        count: unreadCount,
                        selected: _filter == _InboxFilter.unread,
                        onTap: () =>
                            setState(() => _filter = _InboxFilter.unread),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: threads.isEmpty
                      ? const InboxEmptyState()
                      : visible.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  _filter == _InboxFilter.unread
                                      ? 'You are all caught up.'
                                      : 'No conversations match your search.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                bottom + 20,
                              ),
                              itemCount: visible.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final thread = visible[index];
                                return ThreadTile(
                                  thread: thread,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ChatScreen(threadId: thread.id),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.black : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption(
                color: selected ? AppColors.white : AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.forestGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.caption(
                    color: selected ? AppColors.white : AppColors.forestGreen,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
