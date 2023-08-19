#include "galaxy_generator.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void GalaxyGenerator::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_system_data", "system_data"), &GalaxyGenerator::setSystemData);
    ClassDB::bind_method(D_METHOD("set_galaxy_properties", "c_g_g", "sys_n", "difficulty"), &GalaxyGenerator::setGalaxyProperties);
    ClassDB::bind_method(D_METHOD("generate_spiral_galaxy"), &GalaxyGenerator::generateSpiralGalaxy);
}

GalaxyGenerator::GalaxyGenerator() {
    // Initialize any variables here.
    maxOuterRadius = 0.0;
    PI = 3.14159265358979323846264338327;
}

GalaxyGenerator::~GalaxyGenerator() {
    // Add your cleanup here.
}

double GalaxyGenerator::getBiggestStarSize(const unsigned int id) {
	Array stars = systemData[id].get("stars");
	double starSize = stars[0]["size"];
	for (unsigned int i = 1; i < stars.size(); i++) {
		double currentStarSize = stars[i]["size"];
		if (currentStarSize > starSize) {
			starSize = currentStarSize;
		}
	}
	return starSize;

}
void GalaxyGenerator::setSystemData(Array _systemData) {
	systemData = _systemData;
}

void GalaxyGenerator::setGalaxyProperties(unsigned int _c_g_g, int _sysN, double difficulty) {
	c_g_g = _c_g_g;
	sysN = _sysN;
	galaxyDifficulty = difficulty;
	newSystemPositions.resize(sysN);
	newSystemDifficulties.resize(sysN);
}

void GalaxyGenerator::generateClusterGalaxy() {
	
}

Array GalaxyGenerator::generateSpiralGalaxy() {
	const double thInit = UtilityFunctions::randf_range(0.0, PI);
	const unsigned int nInit = generateSpiralGalaxyPart(0, 0.0, 0.0, true);
	unsigned int nProgress = nInit;
	double r = sysN / 20.0;
	double th = thInit;
	while (nProgress < (sysN + nInit) / 2.0) {// Arm #1
		double progress = UtilityFunctions::inverse_lerp(nInit, (sysN + nInit) / 2.0, nProgress);
		nProgress = generateSpiralGalaxyPart(nProgress, r, th);
		th += 0.4 - UtilityFunctions::lerpf(0.0, 0.33, progress);
		r += (1.0 - UtilityFunctions::lerpf(0.0, 0.8, progress)) * 1280 * UtilityFunctions::lerpf(1.3, 4.0, UtilityFunctions::inverse_lerp(5000, 20000, sysN));
	}
	th = thInit + PI;
	r = sysN / 20.0;
	while (nProgress < sysN) {
		double progress = UtilityFunctions::inverse_lerp((sysN + nInit) / 2.0, sysN, nProgress);
		nProgress = generateSpiralGalaxyPart(nProgress, r, th);
		th += 0.4 - UtilityFunctions::lerpf(0.0, 0.33, progress);
		r += (1.0 - UtilityFunctions::lerpf(0.0, 0.8, progress)) * 1200 * UtilityFunctions::lerpf(1.3, 4.0, UtilityFunctions::inverse_lerp(5000, 20000, sysN));
	}
	for (unsigned int i = 0; i < starsFailed.size(); i++) {
		Dictionary s_i = systemData[starsFailed[i]];
		double biggestStarSize = getBiggestStarSize(starsFailed[i]);
		double radius = 320 * UtilityFunctions::pow(biggestStarSize / 100.0, 0.35);
		r = UtilityFunctions::randf_range(0, maxOuterRadius);
		th = UtilityFunctions::randf_range(0, 2 * PI);
		Vector2 pos = Vector2::from_angle(th) * r;
		bool coll = false;
		int attempts = 0;
		do {
			Array objShapes3 = objShapes + objShapes2;
    		for (unsigned int j = 0; j < objShapes3.size(); j++) {
    			Dictionary circ = objShapes3[j];
    			if (pos.distance_to(circ["pos"]) < (double)circ["radius"] + radius) {
    				coll = true;
    				r = UtilityFunctions::randf_range(0, maxOuterRadius);
    				th = UtilityFunctions::randf_range(0, 2 * PI);
    				pos = Vector2::from_angle(th) * r;
    				break;
    			}
    		}
    		attempts++;
    		if (attempts > 20) {
    			maxOuterRadius *= 1.1;
    			attempts = 0;
    		}
		} while (coll);
		s_i["pos"] = pos;
		s_i["diff"] = calculateSystemDifficulty(pos, s_i["stars"]);
		Dictionary dict;
		dict["pos"] = pos;
		dict["radius"] = radius;
		objShapes2.append(dict);
	}
	Array res;
	res.append(newSystemPositions);
	res.append(newSystemDifficulties);
	return res;
}

unsigned int GalaxyGenerator::generateSpiralGalaxyPart(const unsigned int nInit, const double r, const double th, const bool center) {
	const unsigned int systemNumber = systemData.size();
    double circSize = UtilityFunctions::pow(systemNumber * 1.5, 0.95);
    unsigned int nFin = UtilityFunctions::min((double)nInit + UtilityFunctions::lerpf(100.0, 400.0, UtilityFunctions::inverse_lerp(5000.0, 20000.0, sysN)), sysN);
    if (center) {
    	nFin += circSize / 20.0;
    }
    for (unsigned int i = nInit; i < nFin; i++) {
    	double biggestStarSize = getBiggestStarSize(i);
    	double radius = 320 * UtilityFunctions::pow(biggestStarSize / 100.0, 0.35);
    	double r2 = UtilityFunctions::randf_range(0, circSize);
    	double th2 = UtilityFunctions::randf_range(0, 2 * PI);
    	Vector2 pos = Vector2::from_angle(th) * r + Vector2::from_angle(th2) * r2;
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
    			if (pos.distance_to(circ["pos"]) < (double)circ["radius"] + radius) {
					coll = true;
					attempts++;
					r2 = UtilityFunctions::randf_range(0.0, circSize);
					th2 = UtilityFunctions::randf_range(0.0, 2.0 * PI);
					pos = Vector2::from_angle(th) * r + Vector2::from_angle(th2) * r2;
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
    			dict["pos"] = systemData[0]["pos"];
    		} else {
    			newSystemPositions[i] = pos;
    			Dictionary s_i = systemData[i];
    			newSystemDifficulties[i] = calculateSystemDifficulty(pos, s_i["stars"]);
    		}
   			objShapes2.append(dict);
    	}
    }
    Dictionary dict2;
    dict2["pos"] = Vector2::from_angle(th) * r;
    dict2["radius"] = circSize;
    objShapes.append(dict2);
    objShapes2.clear();
    return nFin;
}

double GalaxyGenerator::calculateSystemDifficulty(Vector2 pos, Array stars) {
	double combinedStarMass = 0.0;
	for (unsigned int i = 0; i < stars.size(); i++) {
		combinedStarMass += stars[i]["mass"];
	}
	if (c_g_g == 0) {
		return (1.0 + pos.distance_to(systemData[0].get("pos")) * UtilityFunctions::pow(combinedStarMass, 0.5) / 5000) * galaxyDifficulty;
	}
	return galaxyDifficulty * UtilityFunctions::pow(combinedStarMass, 0.4) * UtilityFunctions::randf_range(120, 150) / UtilityFunctions::maxf(100.0, UtilityFunctions::pow(pos.length(), 0.5));
}
	
