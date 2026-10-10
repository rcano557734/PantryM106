import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:io';

import '../../services/notification_service.dart';
import 'edit_profile_view.dart';
import '../../services/app_colors.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/app_theme_controller.dart';
import '../login_view.dart';
import 'search_history_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.title});

  final String title;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const Color orange = Color(0xFFE8813A);
  static const Color green = Color(0xFF639922);

  bool _haptics = true;
  bool _mealReminders = false;
  bool _loading = true;
  String? _profilePhotoPath;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final photoPath = uid == null
          ? null
          : prefs.getString('pantrymatch_profile_photo_$uid');

      if (!mounted) return;

      setState(() {
        _haptics = prefs.getBool('pantrymatch_haptics') ?? true;
        _mealReminders = prefs.getBool('pantrymatch_meal_reminders') ?? false;

        _reminderTime = TimeOfDay(
          hour: prefs.getInt('pantrymatch_reminder_hour') ?? 10,
          minute: prefs.getInt('pantrymatch_reminder_minute') ?? 0,
        );
        _profilePhotoPath = photoPath;
      });
    } catch (e) {
      debugPrint('Could not load profile preferences: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectTheme(ThemeMode mode) async {
    try {
      await AppThemeController.instance.setMode(mode);

      if (!mounted) return;

      // Refresh the selected theme indicator immediately.
      setState(() {});

      if (_haptics) {
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('Could not change theme: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not change the appearance. Please try again.'),
        ),
      );
    }
  }

  Future<void> _setHaptics(bool value) async {
    setState(() {
      _haptics = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pantrymatch_haptics', value);

    if (value) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _setMealReminders(bool value) async {
    try {
      if (value) {
        // Request permission and schedule the daily reminder.
        final scheduled = await NotificationService.instance
            .scheduleDailyReminder(
              hour: _reminderTime.hour,
              minute: _reminderTime.minute,
            );

        final prefs = await SharedPreferences.getInstance();

        if (!scheduled) {
          await prefs.setBool('pantrymatch_meal_reminders', false);

          if (!mounted) return;

          setState(() {
            _mealReminders = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission was denied. Enable notifications '
                'for PantryMatch in your phone settings.',
              ),
            ),
          );
          return;
        }

        await prefs.setBool('pantrymatch_meal_reminders', true);

        if (!mounted) return;

        setState(() {
          _mealReminders = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Daily meal reminder enabled for '
              '${_reminderTime.format(context)}.',
            ),
          ),
        );
      } else {
        // Cancel the scheduled reminder.
        await NotificationService.instance.cancelDailyReminder();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pantrymatch_meal_reminders', false);

        if (!mounted) return;

        setState(() {
          _mealReminders = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily meal reminders turned off.')),
        );
      }

      if (_haptics && mounted) {
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('Meal reminder error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update meal reminders. Please try again.'),
        ),
      );
    }
  }

  Future<void> _chooseReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'Choose your preferred meal reminder time',
    );

    if (selected == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('pantrymatch_reminder_hour', selected.hour);
      await prefs.setInt('pantrymatch_reminder_minute', selected.minute);

      if (!mounted) return;

      if (_mealReminders) {
        final scheduled = await NotificationService.instance
            .scheduleDailyReminder(
              hour: selected.hour,
              minute: selected.minute,
            );

        if (!mounted) return;

        if (!scheduled) {
          await prefs.setBool('pantrymatch_meal_reminders', false);

          if (!mounted) return;

          setState(() {
            _reminderTime = selected;
            _mealReminders = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission is unavailable. '
                'Meal reminders have been turned off.',
              ),
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      setState(() {
        _reminderTime = selected;
      });

      if (_haptics) {
        HapticFeedback.selectionClick();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mealReminders
                ? 'Meal reminder updated to ${selected.format(context)}.'
                : 'Reminder time saved: ${selected.format(context)}.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Could not update reminder time: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the reminder time.')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView(title: 'Login')),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = AppColors.background(context);
    final surface = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final muted = AppColors.muted(context);
    final border = AppColors.border(context);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email available';
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (email.contains('@') ? email.split('@').first : 'Home Cook');

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: orange))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your profile',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Your kitchen, your preferences.',
                      style: TextStyle(fontSize: 13, color: muted),
                    ),

                    const SizedBox(height: 22),

                    _card(
                      surface: surface,
                      border: border,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.greenSoft(context),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border(context),
                                  width: 2,
                                ),
                              ),
                              child:
                                  _profilePhotoPath != null &&
                                      File(_profilePhotoPath!).existsSync()
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_profilePhotoPath!),
                                        width: 68,
                                        height: 68,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.person_rounded,
                                                size: 36,
                                                color: AppColors.greenAccent(
                                                  context,
                                                ),
                                              );
                                            },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 36,
                                      color: AppColors.greenAccent(context),
                                    ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    _card(
                      surface: surface,
                      border: border,
                      child: _row(
                        icon: Icons.manage_accounts_rounded,
                        color: green,
                        title: 'Edit Profile',
                        subtitle: 'Change your photo, name, or email address',
                        textColor: textColor,
                        muted: muted,
                        onTap: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileView(),
                            ),
                          );

                          if (!mounted) return;

                          if (updated == true) {
                            await FirebaseAuth.instance.currentUser?.reload();
                            await _loadPreferences();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle('YOUR ACTIVITY', muted),

                    const SizedBox(height: 10),

                    _card(
                      surface: surface,
                      border: border,
                      child: _row(
                        icon: Icons.history_rounded,
                        color: orange,
                        title: 'Search history',
                        subtitle: 'Repeat or remove previous searches',
                        textColor: textColor,
                        muted: muted,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SearchHistoryView(
                                title: 'Search History',
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle('PREFERENCES', muted),

                    const SizedBox(height: 10),

                    _card(
                      surface: surface,
                      border: border,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              'Choose how PantryMatch looks',
                              style: TextStyle(fontSize: 12, color: muted),
                            ),

                            const SizedBox(height: 15),

                            Row(
                              children: [
                                _themeOption(
                                  label: 'Light',
                                  icon: Icons.light_mode_outlined,
                                  mode: ThemeMode.light,
                                  selected:
                                      AppThemeController.instance.mode ==
                                      ThemeMode.light,
                                  surface: surface,
                                  border: border,
                                  textColor: textColor,
                                  muted: muted,
                                ),
                                const SizedBox(width: 8),
                                _themeOption(
                                  label: 'Dark',
                                  icon: Icons.dark_mode_outlined,
                                  mode: ThemeMode.dark,
                                  selected:
                                      AppThemeController.instance.mode ==
                                      ThemeMode.dark,
                                  surface: surface,
                                  border: border,
                                  textColor: textColor,
                                  muted: muted,
                                ),
                                const SizedBox(width: 8),
                                _themeOption(
                                  label: 'System',
                                  icon: Icons.settings_brightness_outlined,
                                  mode: ThemeMode.system,
                                  selected:
                                      AppThemeController.instance.mode ==
                                      ThemeMode.system,
                                  surface: surface,
                                  border: border,
                                  textColor: textColor,
                                  muted: muted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _card(
                      surface: surface,
                      border: border,
                      child: Column(
                        children: [
                          _settingRow(
                            icon: Icons.vibration_rounded,
                            title: 'Haptic feedback',
                            subtitle: _haptics
                                ? 'Touch feedback enabled'
                                : 'Touch feedback disabled',
                            iconColor: orange,
                            value: _haptics,
                            textColor: textColor,
                            muted: muted,
                            onChanged: _setHaptics,
                          ),

                          Divider(height: 1, color: border),

                          _row(
                            icon: Icons.notifications_active_outlined,
                            color: green,
                            title: 'Meal reminders',
                            subtitle: _mealReminders
                                ? 'Preferred time: ${_reminderTime.format(context)}'
                                : 'Choose when to receive meal reminders',
                            textColor: textColor,
                            muted: muted,
                            trailing: Switch(
                              value: _mealReminders,
                              activeThumbColor: green,
                              onChanged: _setMealReminders,
                            ),
                            onTap: () => _setMealReminders(!_mealReminders),
                          ),

                          if (_mealReminders) ...[
                            Divider(height: 1, color: border),
                            _row(
                              icon: Icons.schedule_rounded,
                              color: orange,
                              title: 'Reminder time',
                              subtitle: _reminderTime.format(context),
                              textColor: textColor,
                              muted: muted,
                              onTap: _chooseReminderTime,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _sectionTitle('ABOUT & SUPPORT', muted),

                    const SizedBox(height: 10),

                    _card(
                      surface: surface,
                      border: border,
                      child: Column(
                        children: [
                          _row(
                            icon: Icons.privacy_tip_outlined,
                            color: green,
                            title: 'Privacy',
                            subtitle: 'How your account data is stored',
                            textColor: textColor,
                            muted: muted,
                            onTap: () => _showInfo(
                              'Privacy',
                              'PantryMatch stores your pantry ingredients, '
                                  'favorites and search history in Firestore '
                                  'under your signed-in user account.',
                            ),
                          ),

                          Divider(height: 1, color: border),

                          _row(
                            icon: Icons.info_outline_rounded,
                            color: orange,
                            title: 'About PantryMatch',
                            subtitle: 'App information and version',
                            textColor: textColor,
                            muted: muted,
                            onTap: () => _showInfo(
                              'About PantryMatch',
                              'PantryMatch helps you discover meals using '
                                  'ingredients you already have at home.',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log out'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: const Color(0xFFB5502E),
                          side: const BorderSide(color: Color(0xFFE4D9C3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: Text(
                        'PANTRYMATCH  |  COOK SMARTER, WASTE LESS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color muted) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: muted,
      ),
    );
  }

  Widget _card({
    required Color surface,
    required Color border,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }

  Widget _themeOption({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool selected,
    required Color surface,
    required Color border,
    required Color textColor,
    required Color muted,
  }) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.greenSoft(context) : surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: () => _selectTheme(mode),
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? AppColors.greenAccent(context) : border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.greenAccent(context) : muted,
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.greenAccent(context)
                        : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required Color textColor,
    required Color muted,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 11, color: muted)),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: green, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color muted,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              _iconBox(icon, color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt(context),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface(dialogContext),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
