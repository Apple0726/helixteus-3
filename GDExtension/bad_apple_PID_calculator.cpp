#include "bad_apple_PID_calculator.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void BadApplePIDCalculator::_bind_methods() {
    ClassDB::bind_method(D_METHOD("calculate", "target_values"), &BadApplePIDCalculator::calculate);
    ClassDB::bind_method(D_METHOD("initialize", "size"), &BadApplePIDCalculator::initialize);
    ClassDB::bind_method(D_METHOD("changeKp", "Kp"), &BadApplePIDCalculator::changeKp);
    ClassDB::bind_method(D_METHOD("changeKi", "Ki"), &BadApplePIDCalculator::changeKi);
    ClassDB::bind_method(D_METHOD("changeKd", "Kd"), &BadApplePIDCalculator::changeKd);
}

BadApplePIDCalculator::BadApplePIDCalculator() {
	Kp = 1.0;
	Ki = 0.0;
	Kd = 0.0;
}

BadApplePIDCalculator::~BadApplePIDCalculator() {
	// Add your cleanup here.
}

PackedFloat32Array BadApplePIDCalculator::calculate(PackedFloat32Array iTargetValues) {
	for (int i = 0; i < n; i++) {
        if (UtilityFunctions::is_nan(errors[i])) {
            errors[i] = iTargetValues[i];
        }
        deltaError[i] = errors[i] - (iTargetValues[i] - values[i]);
        errors[i] = iTargetValues[i] - values[i];
        values[i] += Kp * errors[i] + Ki * totalError[i] + Kd * deltaError[i];
        totalError[i] += errors[i];
    }
    return values;
}

void BadApplePIDCalculator::initialize(const unsigned int iSize) {
    n = iSize;
    deltaError.resize(n);
    errors.resize(n);
    totalError.resize(n);
    values.resize(n);
    deltaError.fill(0.0);
    errors.fill(NAN);
    totalError.fill(0.0);
    values.fill(0.0);
}

void BadApplePIDCalculator::changeKp(double iKp) {
    Kp = iKp;
}

void BadApplePIDCalculator::changeKi(double iKi) {
    Ki = iKi;
}

void BadApplePIDCalculator::changeKd(double iKd) {
    Kd = iKd;
}