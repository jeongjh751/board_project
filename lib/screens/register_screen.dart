import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);

      try {
        final response = await ApiService.register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입 성공! ${response['user']['username']}님 환영합니다')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입 실패: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.person_add,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            const Text(
              '새 계정 만들기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '사용자 이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '사용자 이름을 입력하세요';
                }
                if (value.length < 3) {
                  return '사용자 이름은 3자 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력하세요';
                }
                if (!value.contains('@')) {
                  return '올바른 이메일 형식이 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력하세요';
                }
                if (value.length < 6) {
                  return '비밀번호는 6자 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              enabled: !isSubmitting,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 다시 입력하세요';
                }
                if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add),
                          SizedBox(width: 8),
                          Text('회원가입', style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('이미 계정이 있으신가요? 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}