#ifndef GALAXY_GENERATOR_H
#define GALAXY_GENERATOR_H

#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

class GalaxyGenerator : public Sprite2D {
    GDCLASS(GalaxyGenerator, Sprite2D)

private:
	double PI;
	Array objShapes;
	Array objShapes2;
	PackedInt32Array starsFailed;
	Array systemData;
	int sysN;
	unsigned int c_g_g;
	double galaxyDifficulty;
	double maxOuterRadius;
	double getBiggestStarSize(const unsigned int id);
	bool sortShapes(Dictionary a, Dictionary b);
	double calculateSystemDifficulty(Vector2 pos, Array stars);
	unsigned int generateSpiralGalaxyPart(const unsigned int nInit, const double r, const double th, const bool center = false);
	Array newSystemPositions;
	Array newSystemDifficulties;

protected:
    static void _bind_methods();

public:
    GalaxyGenerator();
    ~GalaxyGenerator();
	
	Array generateSpiralGalaxy();
	Array generateClusterGalaxy();
	void setGalaxyProperties(unsigned int _c_g_g, int _sysN, double _difficulty);
	void setSystemData(Array _systemData);
};

}

#endif
