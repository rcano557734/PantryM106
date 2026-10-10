import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.title});

  final String title;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const Color cream = Color(0xFFFBF6EC);
  static const Color darkBrown = Color(0xFF3A3226);
  static const Color mutedBrown = Color(0xFF8A7F6B);
  static const Color orange = Color(0xFFE8813A);
  static const Color green = Color(0xFF639922);
  static const Color borderColor = Color(0xFFE4D9C3);

  String _theme = 'Light';
  bool _haptics = true;
  bool _mealReminders = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedHour = prefs.getInt('pantrymatch_reminder_hour') ?? 10;
      final savedMinute = prefs.getInt('pantrymatch_reminder_minute') ?? 0;

      if (!mounted) return;

      setState(() {
        _theme = prefs.getString('pantrymatch_theme') ?? 'Light';
        _haptics = prefs.getBool('pantrymatch_haptics') ?? true;
        _mealReminders = prefs.getBool('pantrymatch_meal_reminders') ?? false;

        _reminderTime = TimeOfDay(hour: savedHour, minute: savedMinute);
      });
    } catch (e) {
      debugPrint('Could not load settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectTheme(String theme) async {
    setState(() {
      _theme = theme;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pantrymatch_theme', theme);

    _feedback();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$theme appearance preference saved.'),
        duration: const Duration(seconds: 2),
      ),
    );
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
    setState(() {
      _mealReminders = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pantrymatch_meal_reminders', value);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Reminder preference enabled.'
              : 'Reminder preference disabled.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _chooseReminderTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'Choose your preferred meal reminder time',
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _reminderTime = selectedTime;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pantrymatch_reminder_hour', selectedTime.hour);
    await prefs.setInt('pantrymatch_reminder_minute', selectedTime.minute);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferred reminder time saved.')),
    );
  }

  void _feedback() {
    if (_haptics) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: orange))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: darkBrown,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Make PantryMatch feel like yours.',
                      style: TextStyle(fontSize: 13, color: mutedBrown),
                    ),

                    const SizedBox(height: 28),

                    _sectionHeading('PREFERENCES'),

                    const SizedBox(height: 12),

                    _card(
                      child: Padding(
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: darkBrown,
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              'Choose your preferred theme',
                              style: TextStyle(fontSize: 12, color: mutedBrown),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                _themeOption(
                                  'Light',
                                  Icons.light_mode_outlined,
                                ),
                                const SizedBox(width: 8),
                                _themeOption('Dark', Icons.dark_mode_outlined),
                                const SizedBox(width: 8),
                                _themeOption(
                                  'System',
                                  Icons.settings_brightness_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _card(
                      child: Column(
                        children: [
                          _settingTile(
                            icon: Icons.vibration_rounded,
                            title: 'Haptic feedback',
                            subtitle: _haptics
                                ? 'Feedback is enabled'
                                : 'Feedback is disabled',
                            iconColor: orange,
                            trailing: Switch(
                              value: _haptics,
                              activeThumbColor: green,
                              onChanged: _setHaptics,
                            ),
                          ),

                          _divider(),

                          _settingTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Meal reminders',
                            subtitle: _mealReminders
                                ? 'Preferred time: ${_reminderTime.format(context)}'
                                : 'Reminder preference is off',
                            iconColor: green,
                            onTap: _chooseReminderTime,
                            trailing: Switch(
                              value: _mealReminders,
                              activeThumbColor: green,
                              onChanged: _setMealReminders,
                            ),
                          ),

                          if (_mealReminders) ...[
                            _divider(),
                            InkWell(
                              onTap: _chooseReminderTime,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Preferred reminder time',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: darkBrown,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _reminderTime.format(context),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: green,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: mutedBrown,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    _sectionHeading('ABOUT & SUPPORT'),

                    const SizedBox(height: 12),

                    _card(
                      child: Column(
                        children: [
                          _settingTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy',
                            subtitle: 'How PantryMatch handles your data',
                            iconColor: green,
                            onTap: _showPrivacy,
                          ),

                          _divider(),

                          _settingTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About PantryMatch',
                            subtitle: 'App information and version',
                            iconColor: orange,
                            onTap: _showAbout,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'PANTRYMATCH  •  MADE FOR YOUR KITCHEN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Color(0xFFB0A48E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: mutedBrown,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _themeOption(String label, IconData icon) {
    final selected = _theme == label;

    return Expanded(
      child: Material(
        color: selected ? const Color(0xFFDCEBCB) : const Color(0xFFFBF6EC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _selectTheme(label),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? green : borderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: selected ? green : mutedBrown, size: 23),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? green : darkBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? _feedback,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EADA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: mutedBrown),
                    ),
                  ],
                ),
              ),

              if (trailing != null)
                trailing
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB3A88F),
                  size: 23,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: borderColor),
    );
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Privacy'),
        content: const Text(
          'PantryMatch uses Firebase Authentication to manage your account '
          'and Cloud Firestore to store your pantry ingredients, saved '
          'recipes, and search history under your user account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'PantryMatch',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.soup_kitchen_rounded,
        color: green,
        size: 35,
      ),
      applicationLegalese: 'Discover recipes from the ingredients you have.',
    );
  }
}
