import 'package:akimat_project/core/di.dart';
import 'package:akimat_project/core/ui/app_colors.dart';
import 'package:akimat_project/core/ui/app_padding.dart';
import 'package:akimat_project/core/ui/app_size.dart';
import 'package:akimat_project/core/ui/app_textstyle.dart';
import 'package:akimat_project/l10n/l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PhoneLoginWidget extends ConsumerStatefulWidget {
  final Function(String phoneNumber) onCodeSent;
  final Function(String phoneNumber, String code) onVerified;

  const PhoneLoginWidget({
    super.key,
    required this.onCodeSent,
    required this.onVerified,
  });

  @override
  ConsumerState<PhoneLoginWidget> createState() => _PhoneLoginWidgetState();
}

class _PhoneLoginWidgetState extends ConsumerState<PhoneLoginWidget> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isCodeSent = false;
  bool _isLoading = false;
  bool _isAutoVerified = false; // Флаг автоматической верификации
  String? _verificationId;
  int? _resendToken;
  String? _fullPhoneNumber; // Полный номер в формате E.164 (+7XXXXXXXXXX)

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendSmsCode() async {
    if (_fullPhoneNumber == null || _fullPhoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
      return;
    }

    // Убеждаемся, что номер в формате E.164 (+7XXXXXXXXXX)
    // completeNumber уже возвращает номер в формате +7XXXXXXXXXX
    String phoneNumber = _fullPhoneNumber!;
    
    // Дополнительная проверка и нормализация
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+$phoneNumber';
    }
    
    // Удаляем все пробелы и дефисы
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Проверяем минимальную длину (минимум +7 + 10 цифр = 12 символов)
    if (phoneNumber.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Номер телефона слишком короткий'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    debugPrint('Sending SMS to: $phoneNumber'); // Для отладки

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = FirebaseAuth.instance;

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Автоматическая верификация (Android) - происходит без ввода кода
          debugPrint('Auto verification completed'); // Для отладки
          setState(() {
            _isAutoVerified = true;
            _isLoading = true;
          });
          
          try {
            final userCredential = await auth.signInWithCredential(credential);
            debugPrint('Auto verification successful, user: ${userCredential.user?.phoneNumber}'); // Для отладки
            
            if (userCredential.user != null && mounted) {
              // Используем сохраненный полный номер
              widget.onVerified(_fullPhoneNumber ?? phoneNumber, '');
            }
          } catch (e) {
            debugPrint('Auto verification error: $e'); // Для отладки
            setState(() {
              _isAutoVerified = false;
              _isLoading = false;
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          
          String errorMessage = 'Ошибка отправки SMS';
          if (e.code == 'billing_not_enabled') {
            errorMessage = 'Биллинг не включен в Firebase. Включите биллинг в Firebase Console для использования Phone Authentication.';
          } else if (e.code == 'invalid-phone-number') {
            errorMessage = 'Некорректный номер телефона. Проверьте формат номера.';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Слишком много запросов. Попробуйте позже.';
          } else if (e.code == 'missing-app-identifier' || 
                     e.message?.contains('missing a valid app identifier') == true ||
                     e.message?.contains('Play integrity checks') == true) {
            // Показываем диалог для длинного сообщения
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ошибка: Не добавлены SHA отпечатки'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Необходимо добавить SHA-1 и SHA-256 отпечатки в Firebase Console.\n'),
                        const Text('Решение:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('1. Откройте Firebase Console → Project settings'),
                        const Text('2. Найдите ваше Android app'),
                        const Text('3. Добавьте SHA-1:'),
                        const SelectableText('7B:A9:E4:14:1B:04:38:A0:1A:A0:8B:A7:94:67:35:17:71:12:4E:4A', 
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('4. Добавьте SHA-256:'),
                        const SelectableText('43:A4:D1:55:A8:F6:DD:D0:D0:2A:38:43:26:75:3B:8F:FA:63:78:FD:C5:B9:F7:78:3A:9C:04:BE:C9:15:A9:B7',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                        const SizedBox(height: 8),
                        const Text('5. Пересоберите приложение'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Понятно'),
                    ),
                  ],
                ),
              );
            }
            return; // Не показываем SnackBar, так как уже показали диалог
          } else {
            errorMessage = 'Ошибка: ${e.message ?? e.code}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Code sent, verificationId: ${verificationId.substring(0, 20)}...'); // Для отладки
          
          // Если автоматическая верификация не произошла, показываем поле для ввода кода
          if (!_isAutoVerified) {
            setState(() {
              _isCodeSent = true;
              _isLoading = false;
              _verificationId = verificationId;
              _resendToken = resendToken;
            });
            // Используем сохраненный полный номер
            widget.onCodeSent(_fullPhoneNumber ?? phoneNumber);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SMS-код отправлен'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Если была автоматическая верификация, не показываем поле для ввода
            debugPrint('Code sent but auto verification already completed'); // Для отладки
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки SMS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    // Очищаем код от пробелов и других символов, оставляем только цифры
    String code = _codeController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите код из SMS')),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала отправьте SMS-код')),
      );
      return;
    }

    debugPrint('Verifying code: $code'); // Для отладки
    debugPrint('Verification ID: ${_verificationId?.substring(0, 20)}...'); // Для отладки

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      debugPrint('Credential created, signing in...'); // Для отладки

      final userCredential = await auth.signInWithCredential(credential);
      
      debugPrint('Sign in successful, user: ${userCredential.user?.phoneNumber}'); // Для отладки
      
      if (userCredential.user != null) {
        // Используем сохраненный полный номер в формате E.164
        final phoneNumber = _fullPhoneNumber ?? _phoneController.text.trim();
        widget.onVerified(phoneNumber, code);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Неверный код';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Неверный код. Проверьте код и попробуйте снова.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'Сессия истекла. Запросите новый код.';
        // Сбрасываем состояние, чтобы пользователь мог запросить новый код
        setState(() {
          _isCodeSent = false;
          _codeController.clear();
          _verificationId = null;
        });
      } else if (e.code == 'invalid-verification-id') {
        errorMessage = 'Ошибка верификации. Запросите новый код.';
        setState(() {
          _isCodeSent = false;
          _codeController.clear();
          _verificationId = null;
        });
      } else {
        errorMessage = 'Ошибка: ${e.message ?? e.code}';
      }
      
      debugPrint('Verification error: ${e.code} - ${e.message}'); // Для отладки
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Unexpected error during verification: $e'); // Для отладки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка верификации: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IntlPhoneField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Номер телефона',
            labelStyle: AppTextStyles.body,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.cardRadius),
            ),
          ),
          initialCountryCode: 'KZ',
          enabled: !_isCodeSent,
          onChanged: (phone) {
            // Сохраняем полный номер в формате E.164 (+7XXXXXXXXXX)
            // completeNumber возвращает номер в формате +7XXXXXXXXXX
            _fullPhoneNumber = phone.completeNumber;
            debugPrint('Phone number: ${phone.completeNumber}'); // Для отладки
          },
          invalidNumberMessage: 'Некорректный номер телефона',
        ),
        if (!_isCodeSent) ...[
          const SizedBox(height: AppPadding.large),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _sendSmsCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSize.cardRadius),
                      ),
                    ),
                    child: Text(
                      'Отправить код',
                      style: AppTextStyles.button,
                    ),
                  ),
          ),
        ],
        if (_isCodeSent) ...[
          const SizedBox(height: AppPadding.normal),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6, // Обычно SMS коды состоят из 6 цифр
            inputFormatters: [
              // Разрешаем только цифры
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Код из SMS',
              labelStyle: AppTextStyles.body,
              hintText: 'Введите 6-значный код',
              counterText: '', // Скрываем счетчик символов
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSize.cardRadius),
              ),
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8, // Увеличиваем расстояние между цифрами для читаемости
            ),
          ),
          const SizedBox(height: AppPadding.large),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSize.cardRadius),
                      ),
                    ),
                    child: Text(
                      'Подтвердить',
                      style: AppTextStyles.button,
                    ),
                  ),
          ),
          const SizedBox(height: AppPadding.small),
          TextButton(
            onPressed: () {
              setState(() {
                _isCodeSent = false;
                _isAutoVerified = false;
                _codeController.clear();
                _verificationId = null;
                _resendToken = null;
                _fullPhoneNumber = null; // Сбрасываем сохраненный номер
              });
            },
            child: const Text('Изменить номер'),
          ),
        ],
      ],
    );
  }
}

