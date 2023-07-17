#ifndef GALAXY_GENERATOR_H
#define GALAXY_GENERATOR_H

#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

class GalaxyGenerator : public Sprite2D {
    GDCLASS(GalaxyGenerator, Sprite2D)

private:
	Array objShapes;
	Array objShapes2;
	PackedInt32Array starsFailed;
	Array systemData;
	double galaxyDifficulty;
	double maxOuterRadius;
	double getBiggestStarSize(const unsigned int id);
	void calculateSystemDifficulty(Vector2 pos, Dictionary s_i)
	void generateSpiralGalaxyPart(const unsigned int nInit, const double r, const double th, const bool center);

protected:
    static void _bind_methods();

public:
    GalaxyGenerator();
    ~GalaxyGenerator();
	
	void generateSpiralGalaxy();
	void setGalaxyProperties(double _difficulty);
	void setSystemData(Array _systemData);
};

}

#endif
