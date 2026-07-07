import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  final _loginFormKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  String? _verificationId;
  bool _isPhoneLoading = false;
  bool _isCheckingLogin = true;

  late AnimationController _fadeCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _floatAnim;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(
          parent: _floatCtrl, curve: Curves.easeInOut),
    );

    final rng = math.Random();
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 6 + 3,
        speed: rng.nextDouble() * 0.3 + 0.1,
        opacity: rng.nextDouble() * 0.4 + 0.1,
      ));
    }

    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername =
        prefs.getString(AppConstants.usernameKey);
    final savedPassword =
        prefs.getString(AppConstants.passwordKey);
    final remember = prefs.getBool('remember_me') ?? false;
    if (savedUsername != null && remember) {
      setState(() {
        _usernameCtrl.text = savedUsername;
        _passwordCtrl.text = savedPassword ?? '';
        _rememberMe = true;
      });
    }
    setState(() => _isCheckingLogin = false);
    _fadeCtrl.forward();
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(
          AppConstants.usernameKey, _usernameCtrl.text);
      await prefs.setString(
          AppConstants.passwordKey, _passwordCtrl.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove(AppConstants.usernameKey);
      await prefs.remove(AppConstants.passwordKey);
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    await _saveCredentials();
    final success = await ref
        .read(authProvider.notifier)
        .login(
          _usernameCtrl.text.trim(),
          _passwordCtrl.text.trim(),
        );
    if (success && mounted) context.go('/dashboard');
  }

  Future<void> _googleSignIn() async {
    try {
      setState(() => _isPhoneLoading = true);
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isPhoneLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance
          .signInWithCredential(credential);
      final success = await ref
          .read(authProvider.notifier)
          .login('admin', 'admin123');
      if (success && mounted) context.go('/dashboard');
    } catch (e) {
      _showMsg('Google sign in failed', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isPhoneLoading = false);
      }
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      _showMsg('Enter valid 10-digit number',
          isError: true);
      return;
    }
    setState(() => _isPhoneLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        verificationCompleted:
            (PhoneAuthCredential cred) async {
          await FirebaseAuth.instance
              .signInWithCredential(cred);
          if (mounted) {
            final ok = await ref
                .read(authProvider.notifier)
                .login('admin', 'admin123');
            if (ok && mounted) context.go('/dashboard');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isPhoneLoading = false);
          _showMsg(e.message ?? 'Verification failed',
              isError: true);
        },
        codeSent: (String vid, int? token) {
          setState(() {
            _verificationId = vid;
            _otpSent = true;
            _isPhoneLoading = false;
          });
          _showMsg('OTP sent to +91$phone ✅');
        },
        codeAutoRetrievalTimeout: (String vid) {
          _verificationId = vid;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isPhoneLoading = false);
      _showMsg('Failed to send OTP', isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 6) {
      _showMsg('Enter 6-digit OTP', isError: true);
      return;
    }
    if (_verificationId == null) return;
    setState(() => _isPhoneLoading = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await FirebaseAuth.instance
          .signInWithCredential(cred);
      final ok = await ref
          .read(authProvider.notifier)
          .login('admin', 'admin123');
      if (ok && mounted) context.go('/dashboard');
    } catch (e) {
      _showMsg('Invalid OTP', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isPhoneLoading = false);
      }
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? Colors.red.shade700 : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (_isCheckingLogin) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D47A1),
        body: Center(
          child: CircularProgressIndicator(
              color: Colors.white),
        ),
      );
    }

    // ── FIXED: dynamic card height, error state included ──
    double cardHeight;
    if (_currentPage == 0) {
      cardHeight =
          authState.error != null ? 430 : 370;
    } else {
      cardHeight = _otpSent ? 430 : 370;
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1565C0),
                  Color(0xFF0D47A1),
                  Color(0xFF1A237E),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleCtrl.value,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color:
                      Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    Colors.blue.withValues(alpha: 0.08),
                border: Border.all(
                  color:
                      Colors.blue.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      AnimatedBuilder(
                        animation: _floatAnim,
                        builder: (context, child) =>
                            Transform.translate(
                          offset:
                              Offset(0, _floatAnim.value),
                          child: child,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient:
                                    const LinearGradient(
                                  begin:
                                      Alignment.topLeft,
                                  end: Alignment
                                      .bottomRight,
                                  colors: [
                                    Color(0xFF42A5F5),
                                    Color(0xFF1565C0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                            0xFF42A5F5)
                                        .withValues(
                                            alpha: 0.4),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.phone_android,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'SR Mobiles',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 16,
                                  vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(
                                        alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(
                                        20),
                                border: Border.all(
                                  color: Colors.white
                                      .withValues(
                                          alpha: 0.2),
                                ),
                              ),
                              child: const Text(
                                'S T O C K   M A N A G E R',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _buildTab('Sign In', 0),
                            _buildTab('Phone OTP', 1),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 250),
                        curve: Curves.easeOut,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset:
                                  const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: PageView(
                          controller: _pageCtrl,
                          onPageChanged: (i) => setState(
                              () => _currentPage = i),
                          children: [
                            _buildSignInPage(authState),
                            _buildPhonePage(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.white
                                      .withValues(
                                          alpha: 0.2))),
                          Padding(
                            padding: const EdgeInsets
                                .symmetric(
                                horizontal: 12),
                            child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                    color: Colors.white
                                        .withValues(
                                            alpha: 0.5),
                                    fontSize: 10,
                                    letterSpacing: 1)),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.white
                                      .withValues(
                                          alpha: 0.2))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _isPhoneLoading
                            ? null
                            : _googleSignIn,
                        child: Container(
                          padding: const EdgeInsets
                              .symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(
                                        alpha: 0.15),
                                blurRadius: 12,
                                offset:
                                    const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              _isPhoneLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(
                                            0xFF1565C0),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.g_mobiledata,
                                      color: Color(
                                          0xFF4285F4),
                                      size: 22,
                                    ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w600,
                                  color:
                                      Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SR Mobiles © 2024 · All rights reserved',
                        style: TextStyle(
                          color: Colors.white
                              .withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _currentPage == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentPage = index);
          _pageCtrl.animateToPage(index,
              duration:
                  const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding:
              const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF1565C0)
                  : Colors.white70,
              fontWeight: isActive
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── FIXED: scrollable, no Spacer ──────────────────────
  Widget _buildSignInPage(AuthState authState) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome Back 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to manage your stock',
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _glassField(
              controller: _usernameCtrl,
              label: 'Username',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _glassField(
              controller: _passwordCtrl,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              obscure: _obscurePassword,
              onToggle: () => setState(() =>
                  _obscurePassword = !_obscurePassword),
              validator: (v) =>
                  v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(
                      () => _rememberMe = !_rememberMe),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _rememberMe
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(5),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    child: _rememberMe
                        ? const Icon(Icons.check,
                            size: 13,
                            color: Color(0xFF1565C0))
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Remember me',
                    style: TextStyle(
                        color: Colors.white
                            .withValues(alpha: 0.7),
                        fontSize: 13)),
              ],
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red
                      .withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.red
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white70,
                        size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(authState.error!,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _glowButton(
              label: authState.isLoading
                  ? null
                  : 'Sign In',
              isLoading: authState.isLoading,
              onTap: _login,
            ),
          ],
        ),
      ),
    );
  }

  // ── FIXED: scrollable, no Spacer ──────────────────────
  Widget _buildPhonePage() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Phone Verification 📱',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your Indian mobile number',
            style: TextStyle(
                fontSize: 13,
                color: Colors.white
                    .withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white
                          .withValues(alpha: 0.2)),
                ),
                child: const Text('+91',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _glassField(
                  controller: _phoneCtrl,
                  label: 'Mobile Number',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          if (_otpSent) ...[
            const SizedBox(height: 14),
            _glassField(
              controller: _otpCtrl,
              label: '6-Digit OTP',
              icon: Icons.lock_clock_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    _isPhoneLoading ? null : _sendOtp,
                child: Text('Resend OTP',
                    style: TextStyle(
                        color: Colors.white
                            .withValues(alpha: 0.7),
                        fontSize: 12)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _glowButton(
            label: _isPhoneLoading
                ? null
                : _otpSent
                    ? 'Verify OTP'
                    : 'Send OTP',
            isLoading: _isPhoneLoading,
            onTap: _otpSent ? _verifyOtp : _sendOtp,
          ),
        ],
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      style: const TextStyle(
          color: Colors.white, fontSize: 14),
      validator: validator,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13),
        prefixIcon: Icon(icon,
            color: Colors.white.withValues(alpha: 0.6),
            size: 18),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white
                      .withValues(alpha: 0.6),
                  size: 18,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor:
            Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Colors.white
                  .withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Colors.white
                  .withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: Colors.white, width: 1.5),
        ),
        errorStyle: const TextStyle(
            color: Colors.orangeAccent, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _glowButton({
    String? label,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFE3F2FD),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.white.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1565C0),
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── PARTICLE SYSTEM ────────────────────────────────────────────
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y + progress * p.speed) % 1.0;
      final paint = Paint()
        ..color = Colors.white
            .withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}