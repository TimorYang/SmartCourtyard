import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_design_tokens.dart';
import '../../../../shared/l10n/app_localizations.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/flinx_navigation_bar.dart';

class AfterSalesAppointmentPage extends StatefulWidget {
  const AfterSalesAppointmentPage({super.key});

  static const routeName = 'after-sales-appointment';
  static const routePath = '/after-sales/appointment';

  @override
  State<AfterSalesAppointmentPage> createState() =>
      _AfterSalesAppointmentPageState();
}

class _AfterSalesAppointmentPageState extends State<AfterSalesAppointmentPage> {
  static const _timeSlots = ['10:00-12:00', '13:00-15:00', '16:00-18:00'];

  late final TextEditingController _descriptionController;
  DateTime _date = DateTime(2026, 4, 28);
  String _timeSlot = _timeSlots.last;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text:
          'Device: Intelligent Gateway (SN-2024-012)\n'
          'The current battery level is 12%, below the threshold of 15%.',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.notificationBackground,
      appBar: FlinxNavigationBar(
        title: l10n.afterSalesAppointmentTitle,
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
                      _AppointmentLabel(
                        icon: Icons.help_outline_rounded,
                        label: l10n.afterSalesProblemDescription,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        key: const ValueKey(
                          'after-sales-problem-description-field',
                        ),
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        style: AppTextTokens.afterSalesField(textTheme),
                        decoration: _inputDecoration(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.afterSalesDescriptionHint,
                        style: AppTextTokens.afterSalesHint(textTheme),
                      ),
                      const SizedBox(height: 20),
                      _AppointmentLabel(
                        icon: Icons.calendar_month_outlined,
                        label: l10n.afterSalesAppointmentTime,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: DateFormat('yyyy-MM-dd HH:mm').format(
                                DateTime(
                                  _date.year,
                                  _date.month,
                                  _date.day,
                                  10,
                                ),
                              ),
                              onPressed: _selectDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: const ValueKey(
                                'after-sales-time-slot-field',
                              ),
                              initialValue: _timeSlot,
                              decoration: _inputDecoration(),
                              style: AppTextTokens.afterSalesField(textTheme),
                              items: [
                                for (final slot in _timeSlots)
                                  DropdownMenuItem(
                                    value: slot,
                                    child: Text(slot),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _timeSlot = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _AppointmentLabel(
                        icon: Icons.image_outlined,
                        label: l10n.afterSalesPicture,
                      ),
                      const SizedBox(height: 10),
                      _PhotoPicker(bytes: _photoBytes, onTap: _pickPhoto),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 50,
                child: FilledButton(
                  key: const ValueKey('after-sales-submit-button'),
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    l10n.afterSalesSubmitToEngineer,
                    style: AppTextTokens.notificationPrimaryButton(textTheme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (mounted) setState(() => _photoBytes = bytes);
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    if (_descriptionController.text.trim().isEmpty) {
      AppToast.error(context, l10n.afterSalesDescriptionRequired);
      return;
    }
    AppToast.success(context, l10n.afterSalesSubmitSuccess);
  }
}

class _AppointmentLabel extends StatelessWidget {
  const _AppointmentLabel({required this.icon, required this.label});

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

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        key: const ValueKey('after-sales-date-button'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.notificationIcon,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: const BorderSide(color: AppColors.afterSalesFieldBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextTokens.afterSalesField(
                  Theme.of(context).textTheme,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 17),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.bytes, required this.onTap});

  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('after-sales-photo-picker'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 68,
        height: 68,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.notificationCard,
          border: Border.all(color: AppColors.afterSalesFieldBorder),
          borderRadius: BorderRadius.circular(5),
        ),
        child: bytes == null
            ? const Icon(Icons.add, color: AppColors.afterSalesPhotoIcon)
            : Image.memory(bytes!, fit: BoxFit.cover),
      ),
    );
  }
}
