import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/captcha_generator.dart';
import '../../../seleccionar_empresa/seleccionar_empresa_args.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/widgets/number_form_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(
        loginUseCase: getIt<LoginUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        repo: getIt<AuthRepository>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey     = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl   = TextEditingController();
  final _captchaCtrl = TextEditingController();

  bool _obscurePassword = true;
  late Captcha _captcha;

  @override
  void initState() {
    super.initState();
    _refreshCaptcha();
  }

  void _refreshCaptcha() {
    setState(() {
      _captcha = CaptchaGenerator.generate();
      _captchaCtrl.clear();
    });
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _claveCtrl.dispose();
    _captchaCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      LoginRequested(
        usuario: _usuarioCtrl.text.trim(),
        clave: _claveCtrl.text,
        captchaA: _captcha.a,
        captchaB: _captcha.b,
        captchaAnswer: int.tryParse(_captchaCtrl.text.trim()) ?? -1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthEmpresaSelectionRequired) {
            context.go(
              '/seleccionar-empresa',
              extra: SeleccionarEmpresaArgs.postLogin(
                preAuthToken: state.preAuthToken,
                empresas: state.empresas,
              ),
            );
          } else if (state is AuthFailure) {
            _refreshCaptcha();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFC62828),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildForm(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_aries.png',
          height: 56,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'ARIES',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A2B45),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sistema de gestión empresarial',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, letterSpacing: 0.3),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Iniciar sesión',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A2B45)),
              ),
              const SizedBox(height: 14),

              // Usuario
              const _FieldLabel('Usuario'),
              TextFormField(
                controller: _usuarioCtrl,
                decoration: const InputDecoration(
                  hintText: 'Código de usuario',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su usuario' : null,
              ),
              const SizedBox(height: 12),

              // Clave
              const _FieldLabel('Contraseña'),
              TextFormField(
                controller: _claveCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Ingrese su contraseña' : null,
              ),
              const SizedBox(height: 12),

              // Captcha
              const _FieldLabel('Verificación'),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2F8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD0DAE8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _captcha.question,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                          InkWell(
                            onTap: _refreshCaptcha,
                            child: const Icon(Icons.refresh, size: 20, color: Color(0xFF1565C0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: NumberFormField(
                      controller: _captchaCtrl,
                      allowDecimal: false,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(hintText: '?'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final ans = int.tryParse(v);
                        if (ans == null || ans != _captcha.answer) return 'Incorrecto';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Submit
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : () => _submit(context),
                      child: loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Ingresar'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A4A5C),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
