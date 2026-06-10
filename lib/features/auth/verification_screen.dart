import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/widgets/figma_asset.dart';
import '../../core/widgets/green_flow_layout.dart';
import '../../core/widgets/uni_button.dart';
import '../../routes/app_routes.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GreenFlowLayout(
      showBackButton: false,
      illustration: const FigmaAsset(
        path: AppAssets.verificationIllustration,
        width: 280,
        height: 300,
        fit: BoxFit.contain,
      ),
      title: 'Verify your email',
      subtitle:
          'Open your inbox and confirm you own this campus email to continue.',
      bottom: UniButton(
        label: 'Confirm verification',
        variant: UniButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pushReplacementNamed(
          AppRoutes.profileCompletion,
        ),
      ),
      children: const [],
    );
  }
}
