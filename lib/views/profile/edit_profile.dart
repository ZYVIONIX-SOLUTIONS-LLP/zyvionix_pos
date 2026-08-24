import 'package:flutter/material.dart';
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

    // Always attempt to update the backend profile since all users are in MongoDB
    success = await ApiService.updateProfile(data);

    if (success || storageType == 'Device Storage') {
      // Update local storage so that offline components reflect the new profile
      await _box.put('offline_email', _emailController.text.trim());
      await _box.put('offline_mobile', _phoneController.text.trim());
      await _box.put('user_email', _emailController.text.trim());
      await _box.put('user_phone', _phoneController.text.trim());

      if (storageType == 'Device Storage') {
        success =
            true; // In device storage, we consider local update a success even if API fails (offline)
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        children: [
                          CustomTextField(
                            label: 'Email Address',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            readOnly: true,
                            suffixIcon: Icon(Icons.lock),
                          ),
                          CustomTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            readOnly: true,
                            suffixIcon: Icon(Icons.lock),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
