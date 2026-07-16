import 'dart:math';

class Captcha {
  final int a;
  final int b;
  final int answer;
  final String question;

  const Captcha({
    required this.a,
    required this.b,
    required this.answer,
    required this.question,
  });
}

class CaptchaGenerator {
  static final _rng = Random();

  static Captcha generate() {
    final a = _rng.nextInt(9) + 1; // 1–9
    final b = _rng.nextInt(9) + 1; // 1–9
    return Captcha(
      a: a,
      b: b,
      answer: a + b,
      question: '$a + $b = ?',
    );
  }
}
