import '../../domain/entities/user_profile.dart';

const double kgToLb = 2.2046226218;

/// Formats a weight stored internally in kilograms for display in the
/// user's preferred unit system. Storage always stays in kg — only the
/// presentation layer converts.
extension WeightDisplay on double {
  String displayWeight(UnitSystem unit, {int decimals = 1}) {
    final value = unit == UnitSystem.imperial ? this * kgToLb : this;
    final suffix = unit == UnitSystem.imperial ? 'lb' : 'kg';
    return '${value.toStringAsFixed(decimals)} $suffix';
  }
}
