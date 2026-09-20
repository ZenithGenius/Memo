import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/app_colors.dart';
import 'package:memo/core/theme/contrast.dart';

void main() {
  group('contraste WCAG', () {
    test('noir sur blanc vaut 21', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    });

    test('anthracite sur sable respecte 4,5:1', () {
      expect(
        contrastRatio(AppColors.charcoal, AppColors.sand),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('blanc sur sarcelle (bouton lecture) respecte 4,5:1', () {
      expect(
        contrastRatio(Colors.white, AppColors.teal),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('blanc sur terre cuite (bouton principal) respecte 4,5:1', () {
      expect(
        contrastRatio(Colors.white, AppColors.terracotta),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
