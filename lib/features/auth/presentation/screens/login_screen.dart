import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_repository.dart';
import '../../../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseFillAllFields)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/logo_no_bg.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  l10n.welcomeBack,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.signInToContinue,
                  style: TextStyle(
                    fontSize: 16,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                _buildTextField(
                  controller: _emailController,
                  label: l10n.emailAddress,
                  icon: LucideIcons.mail,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: l10n.password,
                  icon: LucideIcons.lock,
                  isDark: isDark,
                  isPassword: true,
                ),
                const SizedBox(height: 40),
                _buildLoginButton(isDark, l10n),
                const SizedBox(height: 30),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: RichText(
                      text: TextSpan(
                        text: "${l10n.dontHaveAccount} ",
                        style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.6),
                        ),
                        children: [
                          TextSpan(
                            text: l10n.createOne,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.5,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isDark, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                l10n.login,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
