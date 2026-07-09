import 'package:flutter/material.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class AfterSalesDetailPage extends StatefulWidget {
  const AfterSalesDetailPage({super.key});

  static const routeName = 'after-sales-detail';
  static const routePath = '/after-sales/details';

  @override
  State<AfterSalesDetailPage> createState() => _AfterSalesDetailPageState();
}

class _AfterSalesDetailPageState extends State<AfterSalesDetailPage> {
  static const _servicePhotoPlaceholder =
      'assets/images/after_sales_service_photo_placeholder.png';

  late final TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(
      text:
          'After replacing the battery, it returned to normal and has been '
          'settled',
    );
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.notificationBackground,
      appBar: FlinxNavigationBar(
        title: l10n.afterSalesDetailsTitle,
        showBottomDivider: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.notificationCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                        icon: Icons.help_outline_rounded,
                        label: l10n.afterSalesProblemDescription,
                      ),
                      const SizedBox(height: 10),
                      const _ReadonlyBox(
                        text:
                            'The battery life has significantly decreased, '
                            'and after being fully charged, it can be used for '
                            'less than 2 hours. The warranty has expired, but '
                            'we hope to assist in testing.',
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(
                        icon: Icons.calendar_month_outlined,
                        label: l10n.afterSalesAppointmentTime,
                      ),
                      const SizedBox(height: 10),
                      const _ReadonlyBox(
                        text: '2026-04-28 10:00',
                        minHeight: 44,
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(
                        icon: Icons.edit_note_rounded,
                        label: l10n.afterSalesRemark,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        key: const ValueKey('after-sales-remark-field'),
                        controller: _remarkController,
                        minLines: 2,
                        maxLines: 4,
                        style: AppTextTokens.afterSalesField(
                          Theme.of(context).textTheme,
                        ),
                        decoration: _fieldDecoration(),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(
                        icon: Icons.image_outlined,
                        label: l10n.afterSalesPicture,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          _servicePhotoPlaceholder,
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 66,
                            height: 66,
                            color: AppColors.afterSalesPhotoPlaceholder,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.garage_outlined,
                              color: AppColors.afterSalesPhotoIcon,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SectionLabel(
                        icon: Icons.engineering_outlined,
                        label: l10n.afterSalesInstallerConfirm,
                      ),
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.afterSalesConfirmedSurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Text(
                            l10n.afterSalesConfirmed,
                            style: AppTextTokens.afterSalesConfirmed(
                              Theme.of(context).textTheme,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _InstallerSummary(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ActionButton(
                label: l10n.afterSalesFeedback,
                primary: true,
                onPressed: () =>
                    _showPlaceholder(context, l10n.afterSalesFeedbackSubmitted),
              ),
              const SizedBox(height: 14),
              _ActionButton(
                label: l10n.afterSalesContactInstaller,
                onPressed: () =>
                    _showPlaceholder(context, l10n.afterSalesContactComingSoon),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.all(10),
      filled: true,
      fillColor: AppColors.notificationCard,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.afterSalesFieldBorder),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.brandPrimary),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.notificationIcon),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextTokens.afterSalesSectionTitle(
              Theme.of(context).textTheme,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyBox extends StatelessWidget {
  const _ReadonlyBox({required this.text, this.minHeight = 88});

  final String text;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.afterSalesFieldBorder),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: AppTextTokens.afterSalesField(Theme.of(context).textTheme),
      ),
    );
  }
}

class _InstallerSummary extends StatelessWidget {
  const _InstallerSummary();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.afterSalesSummarySurface,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '2026/6/17',
              style: AppTextTokens.afterSalesMeta(textTheme),
            ),
          ),
          const Icon(Icons.engineering_outlined, size: 17),
          const SizedBox(width: 7),
          Expanded(
            flex: 2,
            child: Text(
              'Installer: Mr. Zhang',
              overflow: TextOverflow.ellipsis,
              style: AppTextTokens.afterSalesMeta(textTheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? AppColors.brandPrimary
              : AppColors.notificationCard,
          foregroundColor: primary ? Colors.white : AppColors.notificationIcon,
          shape: const StadiumBorder(),
          side: primary
              ? BorderSide.none
              : const BorderSide(color: AppColors.afterSalesSecondaryBorder),
        ),
        child: Text(
          label,
          style:
              AppTextTokens.notificationPrimaryButton(
                Theme.of(context).textTheme,
              ).copyWith(
                color: primary ? Colors.white : AppColors.notificationIcon,
              ),
        ),
      ),
    );
  }
}
