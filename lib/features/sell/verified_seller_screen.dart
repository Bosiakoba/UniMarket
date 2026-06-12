import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/verification_criteria.dart';
import '../../core/data/stores/seller_store.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/verified_badge.dart';
import 'sell_entry.dart';
import 'widgets/seller_status_layout.dart';

class VerifiedSellerScreen extends StatelessWidget {
  const VerifiedSellerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SellerStoreScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.isSeller) {
          return SellerStatusLayout(
            tone: SellerStatusTone.neutral,
            heroIcon: LucideIcons.store,
            badgeLabel: 'SELLER FIRST',
            title: 'Apply to sell first',
            subtitle:
                'Complete your seller application before you can request '
                'the verified badge.',
            bottom: UniButton(
              label: 'Apply to sell',
              variant: UniButtonVariant.green,
              onPressed: () => SellEntry.openSellerApplication(context),
            ),
            children: const [],
          );
        }

        if (store.isVerified) {
          return _VerifiedSuccessView(storeName: store.storeName);
        }

        if (store.verificationPending) {
          return const _VerificationPendingView();
        }

        return _VerificationProgressView(store: store);
      },
    );
  }
}

class _VerifiedSuccessView extends StatelessWidget {
  const _VerifiedSuccessView({required this.storeName});

  final String storeName;

  @override
  Widget build(BuildContext context) {
    return SellerStatusLayout(
      tone: SellerStatusTone.verified,
      heroIcon: LucideIcons.shieldCheck,
      badgeLabel: 'VERIFIED SELLER',
      title: 'You are verified',
      subtitle:
          '$storeName now shows the verified badge on listings and profile. '
          'Campus buyers can trust you faster.',
      bottom: Column(
        children: [
          const VerifiedBadge(),
          const SizedBox(height: 16),
          UniButton(
            label: 'Back to profile',
            variant: UniButtonVariant.green,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      children: const [
        SellerStatusStepCard(
          steps: [
            SellerStatusStep(
              label: 'Priority in search',
              detail: 'Verified listings appear ahead of regular sellers.',
              state: SellerStatusStepState.done,
            ),
            SellerStatusStep(
              label: 'Trust badge on every listing',
              detail: 'Buyers see you passed campus seller checks.',
              state: SellerStatusStepState.done,
            ),
            SellerStatusStep(
              label: 'Keep your rating high',
              detail: 'Great meetups and honest listings protect your badge.',
              state: SellerStatusStepState.done,
            ),
          ],
        ),
      ],
    );
  }
}

class _VerificationPendingView extends StatelessWidget {
  const _VerificationPendingView();

  @override
  Widget build(BuildContext context) {
    return SellerStatusLayout(
      tone: SellerStatusTone.pending,
      heroIcon: LucideIcons.shield,
      badgeLabel: 'VERIFICATION IN PROGRESS',
      title: 'Badge review underway',
      subtitle:
          'You met every requirement. Our campus team is confirming your '
          'seller history before the verified badge goes live.',
      bottom: UniButton(
        label: 'Review in progress',
        variant: UniButtonVariant.secondary,
        onPressed: null,
      ),
      children: const [
        SellerStatusStepCard(
          steps: [
            SellerStatusStep(
              label: 'Requirements met',
              detail: 'Listings, sales, rating, and tenure all passed.',
              state: SellerStatusStepState.done,
            ),
            SellerStatusStep(
              label: 'Campus trust review',
              detail: 'This usually completes within a day.',
              state: SellerStatusStepState.active,
            ),
            SellerStatusStep(
              label: 'Verified badge live',
              detail: 'You will see it on profile and listings.',
              state: SellerStatusStepState.upcoming,
            ),
          ],
        ),
      ],
    );
  }
}

class _VerificationProgressView extends StatelessWidget {
  const _VerificationProgressView({required this.store});

  final SellerStore store;

  @override
  Widget build(BuildContext context) {
    final eligible = store.canApplyForVerification;

    return SellerStatusLayout(
      tone: SellerStatusTone.neutral,
      heroIcon: LucideIcons.award,
      badgeLabel: 'VERIFIED BADGE',
      title: 'Build campus trust',
      subtitle:
          'You can already sell on Uni Market. The verified badge is a '
          'separate step that unlocks after strong seller performance.',
      bottom: UniButton(
        label: eligible ? 'Apply for verified badge' : 'Keep building trust',
        variant: UniButtonVariant.green,
        onPressed: eligible
            ? () async {
                final client = ApiClientScope.of(context);
                final error = await store.submitVerificationApplication(
                  client: client,
                );
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification submitted for review.'),
                  ),
                );
              }
            : null,
      ),
      children: [
        SellerCriteriaCard(
          items: [
            SellerCriteriaItem(
              label: 'Student ID on file',
              detail: 'From your seller application',
              met: store.hasStudentIdOnFile,
            ),
            SellerCriteriaItem(
              label:
                  '${VerificationCriteria.minTotalListings}+ listings posted',
              detail: '${store.totalListings} posted so far',
              met: store.meetsListingsCriteria,
            ),
            SellerCriteriaItem(
              label:
                  '${VerificationCriteria.minCompletedSales}+ completed sales',
              detail: '${store.soldCount} sold so far',
              met: store.meetsSalesCriteria,
            ),
            SellerCriteriaItem(
              label:
                  '${VerificationCriteria.minSellerRating}+ seller rating',
              detail: '${store.sellerRating.toStringAsFixed(1)} average',
              met: store.meetsRatingCriteria,
            ),
            SellerCriteriaItem(
              label:
                  '${VerificationCriteria.minDaysAsSeller}+ days as a seller',
              detail: '${store.daysAsSeller} days on campus market',
              met: store.meetsTenureCriteria,
            ),
          ],
        ),
      ],
    );
  }
}
