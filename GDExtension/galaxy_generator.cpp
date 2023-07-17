#include "galaxy_generator.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;
using namespace UtilityFunctions;

void GalaxyGenerator::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_system_data", "system_data"), &GalaxyGenerator::setSystemData);
    ClassDB::bind_method(D_METHOD("set_galaxy_properties", "difficulty"), &GalaxyGenerator::setGalaxyProperties);
    ClassDB::bind_method(D_METHOD("generate_spiral_galaxy"), &GalaxyGenerator::generateSpiralGalaxy);
}

GalaxyGenerator::GalaxyGenerator() {
    // Initialize any variables here.
    maxOuterRadius = 0.0;
}

GalaxyGenerator::~GalaxyGenerator() {
    // Add your cleanup here.
}

double GalaxyGenerator::getBiggestStarSize(const unsigned int id) {
	double starSize = systemData[id].stars[0].size;
	for (unsigned int i = 1; i < systemData[id].stars.size(); i++) {
		if (system_data[id].stars[i].size > starSize) {
			starSize = system_data[id].stars[i].size;
		}
	}
	return starSize;

}
void GalaxyGenerator::setSystemData(Array _systemData, unsigned int _c_g_g, unsigned int _c_g) {
	systemData = _systemData;
}

void GalaxyGenerator::setGalaxyProperties(double difficulty) {
	galaxyDifficulty = difficulty;
}

void GalaxyGenerator::generateSpiralGalaxy() {
	const unsigned int systemNumber = systemData.size();
	const double thInit = randf_range(0.0, PI);
	const unsigned int nInit = generateSpiralGalaxyPart(0, 0.0, 0.0, true);
	const unsigned int nProgress = nInit;
	double r = systemNumber / 20.0;
	double th = thInit;
	while (nProgress < (systemNumber + nInit) / 2.0 {// Arm #1
		double progress = inverse_lerp(nInit, (systemNumber + nInit) / 2.0, nProgress);
		nProgress = generateSpiralGalaxyPart(nProgress, r, th);
		th += 0.4 - lerp(0.0, 0.33, progress);
		r += (1.0 - lerp(0.0, 0.8, progress)) * 1280 * lerp(1.3, 4.0, inverse_lerp(5000, 20000, N));
	}
	th = thInit + PI;
	r = N / 20.0;
	
}

unsigned int GalaxyGenerator::generateSpiralGalaxyPart(const unsigned int nInit, const double r, const double th, const bool center) {
	const unsigned int systemNumber = systemData.size();
    double circSize = pow(systemNumber * 1.5, 0.95);
    unsigned int nFin = min(nInit + lerp(100, 400, inverse_lerp(5000, 20000, N)), N);
    if (center) {
    	nFin += circSize / 20.0;
    }
    for (unsigned int i = nInit; i < nFin; i++) {
    	double biggestStarSize = getBiggestStarSize(i);
    	double radius = 320 * pow(biggestStarSize / 100.0, 0.35);
    	double r2 = randf_range(0, circSize);
    	double th2 = randf_range(0, 2 * PI);
    	Vector2 pos = Vector2.from_angle(th) * r + Vector2.from_angle(th2) * r2;
    	bool coll = false;
    	int attempts = 0;
    	bool cont = true;
    	do {
    		if (attempts > 10) {
				cont = false;
				starsFailed.append(i);
				break; 		
    		}
    		Array objShapes3 = objShapes + objShapes2;
    		for (unsigned int j = 0; j < objShapes3.size(); j++) {
    			Dictionary circ = objShapes3[j];
    			if (pos.distance_to(circ.pos) < circ.radius + radius) {
					coll = true;
					attempts++;
					r2 = randf_range(0.0, circ_size);
					th2 = randf_range(0.0, 2.0 * PI);
					pos = Vector2.from_angle(th) * r + Vector2.from_angle(th2) * r2;
					break;
    			}
    		}
    	} while (coll);
    	if (cont) {
    		if (pos.length() > maxOuterRadius) {
    			maxOuterRadius = pos.length();
    		}
    		bool startingSystem = c_g_g == 0 && i == 0;
    		Dictionary dict;
    		dict["pos"] = pos;
    		dict["radius"] = radius;
    		if (startingSystem) {
    			dict["pos"] = system_data[0].pos;
    		} else {
    			system_data[i].pos = pos;
    			system_data[i].diff = calculateSystemDifficulty(pos, system_data[i]);
    		}
   			objShapes2.append(dict);
    	}
    }
    Dictionary dict2;
    dict2["pos"] = Vector2.from_angle(th) * r;
    dict2["radius"] = circ_size;
    objShapes.append(dict2);
    objShapes2.clear();
    return nFin;
}

void GalaxyGenerator::calculateSystemDifficulty(Vector2 pos, Dictionary s_i) {
	Array stars = s_i.stars;
	double combined_star_mass = 0.0;
	for (unsigned int i = 0; i < stars.size(); i++) {
		combined_star_mass += stars[i].mass;
	}
	if (c_g_g == 0) {
		return (1.0 + pos.distance_to(system_data[0].pos) * pow(combined_star_mass, 0.5) / 5000) * galaxyDifficulty;
	}
	return galaxyDifficulty * pow(combined_star_mass, 0.4) * randf_range(120, 150) / max(100, pow(pos.length(), 0.5));
}
	
