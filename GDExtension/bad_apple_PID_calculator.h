#ifndef BA_PID_CALC_H
#define BA_PID_CALC_H

#include <godot_cpp/classes/node.hpp>

namespace godot {

class BadApplePIDCalculator : public Node {
	GDCLASS(BadApplePIDCalculator, Node)

private:
	int n;
    double Kp;
    double Ki;
    double Kd;
    PackedFloat32Array deltaError;
    PackedFloat32Array errors;
    PackedFloat32Array totalError;
    PackedFloat32Array values;

protected:
	static void _bind_methods();

public:
	BadApplePIDCalculator();
	~BadApplePIDCalculator();
    PackedFloat32Array calculate(PackedFloat32Array iTargetValues);
    void initialize(const unsigned int iSize);
    void changeKp(double iKp);
    void changeKi(double iKi);
    void changeKd(double iKd);
};

}

#endif