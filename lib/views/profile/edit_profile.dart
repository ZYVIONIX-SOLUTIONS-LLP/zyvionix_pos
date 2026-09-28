import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';
import 'package:zyvionix_pos/database/hive_boxes.dart';
import 'package:zyvionix_pos/services/api_service.dart';
import 'package:zyvionix_pos/widgets/custom_text_field.dart';
import 'package:zyvionix_pos/widgets/primary_button.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _box = HiveBoxes.getSettingsBox();
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    print('gtgtgggggggggggggggggggggggggggggggggggggggggggggg');
    final profile = await ApiService.getProfile();
    if (profile != null) {
      setState(() {
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['mobileNumber'] ?? '';
        _isLoading = false;
      });
    } else {
      // Fallback to hive
      setState(() {
        _emailController.text = _box.get('user_email', defaultValue: '');
        _phoneController.text = _box.get('user_phone', defaultValue: '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    final storageType = _box.get('storageType', defaultValue: 'Device Storage');
    bool success = false;

    final data = {
      'email': _emailController.text.trim(),
      'mobileNumber': _phoneController.text.trim(),
    };

    success = await ApiService.updateProfile(data);

    if (success || storageType == 'Device Storage') {
      await _box.put('offline_email', _emailController.text.trim());
      await _box.put('offline_mobile', _phoneController.text.trim());
      await _box.put('user_email', _emailController.text.trim());
      await _box.put('user_phone', _phoneController.text.trim());

      if (storageType == 'Device Storage') {
        success = true;
      }
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              'Profile updated successfully!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Failed to update profile.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        title: Text(
          context.tr('edit_profile'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: _isLoading
          ? _buildLoadingScreen(isDark)
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Email Address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            readOnly: true,
                            suffixIcon: Icon(
                              Icons.lock,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          CustomTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            readOnly: true,
                            suffixIcon: Icon(
                              Icons.lock,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: context.tr('save_changes'),
                      onPressed: _saveProfile,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitCircle(color: Color(0xFF1EA1F2), size: 60.0),
          const SizedBox(height: 24),
          Text(
            'Loading profile data...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
