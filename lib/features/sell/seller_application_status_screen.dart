import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/user_session_scope.dart';
import 'post_listing_screen.dart';
import 'seller_application_screen.dart';
import 'widgets/seller_status_layout.dart';

class SellerApplicationStatusScreen extends StatefulWidget {
  const SellerApplicationStatusScreen({
    super.key,
    this.continueToListing = false,
  });

  final bool continueToListing;

  static Future<bool?> open(
    BuildContext context, {
    bool continueToListing = false,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SellerApplicationStatusScreen(
          continueToListing: continueToListing,
        ),
      ),
    );
  }

  @override
  State<SellerApplicationStatusScreen> createState() =>
      _SellerApplicationStatusScreenState();
}

class _SellerApplicationStatusScreenState
    extends State<SellerApplicationStatusScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final session = UserSessionScope.of(context);
    final store = SellerStoreScope.of(context);
    final client = ApiClientScope.of(context);

    await store.refreshApplicationStatus(
      client: client,
      onUserUpdated: session.setCurrentUser,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SellerStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.isSeller) {
          return _ApprovedView(continueToListing: widget.continueToListing);
        }

        if (store.sellerApplicationRejected) {
          return SellerStatusLayout(
            tone: SellerStatusTone.neutral,
            heroIcon: LucideIcons.xCircle,
            badgeLabel: 'APPLICATION UPDATE',
            title: 'We need a quick fix',
            subtitle:
                'Your seller application could not be approved yet. Update '
                'your campus details and student ID, then submit again.',
            bottom: UniButton(
              label: 'Update application',
              variant: UniButtonVariant.green,
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => const SellerApplicationScreen(
                      continueToListing: true,
                    ),
                  ),
                );
              },
            ),
            children: const [
              SellerStatusStepCard(
                steps: [
                  SellerStatusStep(
                    label: 'Check your student email',
                    detail: 'Use your official @university.edu address.',
                    state: SellerStatusStepState.upcoming,
                  ),
                  SellerStatusStep(
                    label: 'Re-upload a clear student ID',
                    detail: 'Photo must show your name and campus clearly.',
                    state: SellerStatusStepState.upcoming,
                  ),
                ],
              ),
            ],
          );
        }

        return SellerStatusLayout(
          tone: SellerStatusTone.pending,
          heroIcon: LucideIcons.store,
          badgeLabel: 'UNDER REVIEW',
          title: 'Seller checks in progress',
          subtitle:
              'Campus admins are reviewing your student ID and store details. '
              'This page updates automatically when you are approved.',
          bottom: UniButton(
            label: 'Refresh status',
            variant: UniButtonVariant.secondary,
            onPressed: _refresh,
          ),
          children: const [
            SellerStatusStepCard(
              steps: [
                SellerStatusStep(
                  label: 'Application received',
                  detail: 'Your details were submitted successfully.',
                  state: SellerStatusStepState.done,
                ),
                SellerStatusStep(
                  label: 'Campus identity review',
                  detail: 'An admin verifies your student ID and email.',
                  state: SellerStatusStepState.active,
                ),
                SellerStatusStep(
                  label: 'Start posting listings',
                  detail: 'Opens automatically once approved.',
                  state: SellerStatusStepState.upcoming,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ApprovedView extends StatelessWidget {
  const _ApprovedView({required this.continueToListing});

  final bool continueToListing;

  @override
  Widget build(BuildContext context) {
    return SellerStatusLayout(
      tone: SellerStatusTone.success,
      heroIcon: LucideIcons.partyPopper,
      badgeLabel: 'APPROVED',
      title: 'You can sell on campus',
      subtitle:
          'Your seller application is approved. Buyers can contact you '
          'directly for meetups and payment.',
      bottom: UniButton(
        label: continueToListing ? 'Continue to post listing' : 'Start selling',
        variant: UniButtonVariant.green,
        onPressed: () {
          if (continueToListing) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const PostListingScreen(),
              ),
            );
            return;
          }
          Navigator.of(context).pop(true);
        },
      ),
      children: const [
        SellerStatusStepCard(
          steps: [
            SellerStatusStep(
              label: 'Campus seller access',
              detail: 'Post listings, manage sales, and reply to buyers.',
              state: SellerStatusStepState.done,
            ),
            SellerStatusStep(
              label: 'Verified badge',
              detail: 'Unlock later after sales, ratings, and tenure.',
              state: SellerStatusStepState.upcoming,
            ),
          ],
        ),
      ],
    );
  }
}
