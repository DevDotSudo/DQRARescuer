import 'package:flutter/material.dart';
import 'package:rescuer/constants/app_colors.dart';
import 'package:rescuer/services/rescuer_services.dart';
import 'package:rescuer/utils/login_pref.dart';
import 'package:rescuer/views/screen/widgets/custom_dialog.dart';
import 'package:rescuer/views/screen/widgets/custom_textfields.dart';
import 'package:rescuer/views/screen/widgets/rescuer_auth_header.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final loginState = await LoginPreferences.getLoginState();
    if (loginState != null) {
      final exists = await _service.usernameExists(loginState['Username']);
      final storedPassword = await _service.getPasswordByUsername(loginState['Username']);

      if (exists && storedPassword == loginState['Password']) {
        final rescuer = await _service.getRescuerByUsername(loginState['Username']);
        if (rescuer != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(currentRescuer: rescuer),
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
                  subtitle: "Access emergency management system",
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: "Username",
                  controller: _usernameController,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Password",
                  controller: _passwordController,
                  isPassword: !_showPassword,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textLight,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                      activeColor: AppColors.primary,
                    ),
                    const Text("Remember me"),
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
                      "LOGIN",
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

      try {
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        final exists = await _service.usernameExists(username);
        final storedPassword = await _service.getPasswordByUsername(username);

        if (exists && storedPassword == password) {
          final rescuer = await _service.getRescuerByUsername(username);
          if (mounted) Navigator.pop(context);

          if (rescuer != null) {
            if (_rememberMe) {
              await LoginPreferences.saveLoginState(username, password, true);
            }

            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => CustomDialog(
                  message: "Login successful!",
                  isSuccess: true,
                  onOk: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(currentRescuer: rescuer),
                      ),
                      
                    );
                  },
                ),
              );
            }
          } else {
            if (mounted) {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => CustomDialog(
                  message: "User data not found",
                  isSuccess: false,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => CustomDialog(
                message: "Invalid credentials",
                isSuccess: false,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => CustomDialog(
              message: "Error: ${e.toString()}",
              isSuccess: false,
            ),
          );
        }
      }
    }
  }
}