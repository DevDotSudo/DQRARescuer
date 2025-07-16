// screens/rescuer/auth/rescuer_login_screen.dart
import 'package:flutter/material.dart';
import 'package:rescuer/auth/login_preferences.dart';
import 'package:rescuer/constants/app_colors.dart';
import 'package:rescuer/model/rescuer_model.dart';
import 'package:rescuer/services/rescuer_services.dart';
import 'package:rescuer/views/screen/rescuer_home_screen.dart';
import 'package:rescuer/views/screen/widgets/custom_dialog.dart';
import 'package:rescuer/views/screen/widgets/custom_textfields.dart';
import 'package:rescuer/views/screen/widgets/rescuer_auth_header.dart';

class RescuerLoginScreen extends StatefulWidget {
  const RescuerLoginScreen({super.key});

  @override
  State<RescuerLoginScreen> createState() => _RescuerLoginScreenState();
}

class _RescuerLoginScreenState extends State<RescuerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final RescuerService _service = RescuerService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    Map<String, dynamic>? loginState = await RescuerLoginPreferences.getLoginState();
    if (loginState != null) {
      String username = loginState['Username'];
      String password = loginState['Password'];

      final exists = await _service.usernameExists(username);
      String? storedPassword = await _service.getPasswordByUsername(username);

      if (exists && storedPassword == password) {
        final Rescuer? rescuer = await _service.getRescuerByUsername(username);
        if (rescuer != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RescuerHomeScreen(currentRescuer: rescuer),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const AuthHeader(
                  title: "Rescuer Login",
                  subtitle: "Rescuer Login - Access emergency management",
                ),
                CustomTextField(
                  label: "Username",
                  controller: _usernameController,
                  validator: (value) => value!.isEmpty ? 'Username is required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Password",
                  controller: _passwordController,
                  isPassword: !_showPassword,
                  validator: (value) => value!.isEmpty ? 'Password is required' : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        const Text("Remember me"),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _login,
                    child: const Text(
                      "LOGIN AS RESCUER",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();

      try {
        final exists = await _service.usernameExists(username);
        String? storedPassword = await _service.getPasswordByUsername(username);

        if (exists && storedPassword == password) {
          Rescuer? rescuer = await _service.getRescuerByUsername(username);

          if (rescuer != null) {
            Navigator.pop(context);

            if (_rememberMe) {
              await RescuerLoginPreferences.saveLoginState(username, password, true);
            }

            showDialog(
              context: context,
              builder: (context) => CustomDialog(
                message: "Login successful!",
                isSuccess: true,
                onOk: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RescuerHomeScreen(currentRescuer: rescuer),
                    ),
                  );
                },
              ),
            );
          } else {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => CustomDialog(
                message: "Rescuer data not found",
                isSuccess: false,
              ),
            );
          }
        } else {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => CustomDialog(
              message: "Invalid username or password",
              isSuccess: false,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => CustomDialog(
            message: "Error during login: ${e.toString()}",
            isSuccess: false,
          ),
        );
      }
    }
  }
}