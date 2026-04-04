import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../main_screen.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showResendButton = false;
  String _errorMessage = '';

  Future<void> _loginWithGoogle() async {
    setState(() { _errorMessage = ''; _isLoading = true; });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // التحقق من وجود المستخدم في Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // أول مستخدم يسجل بـ Google وكان اسمه Artiatech (تقريباً) قد لا ينجح هذا الفحص التلقائي هنا
          // لذا سنعتمد على الاسم المعطى من جوجل كـ username مبدئي
          String username = googleUser.displayName?.replaceAll(' ', '').toLowerCase() ?? 'user${user.uid.substring(0, 5)}';
          
          // تأكد من فرادة الاسم
          final existing = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: username).get();
          if (existing.docs.isNotEmpty) username = "$username${DateTime.now().millisecond}";

          // قاعدة الأدمن: إذا كان المشروع جديداً تماماً وكان هذا أول مستخدم واسمه مطابق
          bool isAdmin = username == 'artiatech';
          if (!isAdmin) {
             final allUsers = await FirebaseFirestore.instance.collection('users').limit(1).get();
             if (allUsers.docs.isEmpty && (username.contains('artiatech') || user.email == 'artiateech@gmail.com')) {
               isAdmin = true;
               username = 'artiatech';
             }
          }

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'username': username,
            'usernameLower': username.toLowerCase(),
            'email': user.email,
            'role': isAdmin ? 'admin' : 'user',
            'isTrusted': isAdmin,
            'createdAt': FieldValue.serverTimestamp(),
            'avatarUrl': googleUser.photoUrl ?? '',
            'followers': [],
            'following': [],
            'followersCount': 0,
            'followingCount': 0,
            'bio': 'مبدع جديد في أرتياتك! 🚀',
          });
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'خطأ في تسجيل جوجل: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
      _showResendButton = false;
      _isLoading = true;
    });

    final input = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى إدخال البريد/اسم المستخدم وكلمة المرور';
        _isLoading = false;
      });
      return;
    }

    String email = input;

    try {
      // Check if input is username (not containing @)
      if (!input.contains('@')) {
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (result.docs.isEmpty) {
          setState(() {
            _errorMessage = 'اسم المستخدم غير موجود.';
            _isLoading = false;
          });
          return;
        }
        email = result.docs.first.get('email');
      }

      // Login with Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check Verification
      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'حسابك يحتاج للتفعيل. يرجى مراجعة رابط التفعيل في بريدك الإلكتروني.';
          _showResendButton = true;
        });
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'خطأ في الربط مع الحساب.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      final input = _identifierController.text.trim();
      final password = _passwordController.text.trim();
      
      // We must sign in temporarily to send the email
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: input.contains('@') ? input : (await _getEmailFromUsername(input)) ?? '',
        password: password,
      );
      
      await userCredential.user!.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رابط التفعيل الجديد لبريدك.')));
        setState(() => _showResendButton = false);
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإرسال: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _getEmailFromUsername(String username) async {
    final QuerySnapshot result = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: username).limit(1).get();
    return result.docs.isEmpty ? null : result.docs.first.get('email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول أرتياتك')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.shield_outlined, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    if (_showResendButton)
                      TextButton(
                        onPressed: _resendVerificationEmail,
                        child: const Text('ألم يصلك الرابط بعد؟ أعد الإرسال', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم أو البريد',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                child: const Text('هل نسيت كلمة المرور؟'),
              ),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 15),
                      // ✅ زر الدخول بجوجل الفاخر
                      OutlinedButton.icon(
                        onPressed: _loginWithGoogle,
                        icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png', height: 20),
                        label: const Text('الدخول بواسطة جوجل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ليس لديك حساب بعد؟'),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('أنشئ حسابك الآن'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
