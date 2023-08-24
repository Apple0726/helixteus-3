#include "galaxy_generator.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void GalaxyGenerator::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_system_data", "system_data"), &GalaxyGenerator::setSystemData);
    ClassDB::bind_method(D_METHOD("set_galaxy_properties", "c_g_g", "sys_n", "difficulty"), &GalaxyGenerator::setGalaxyProperties);
    ClassDB::bind_method(D_METHOD("generate_spiral_galaxy"), &GalaxyGenerator::generateSpiralGalaxy);
    ClassDB::bind_method(D_METHOD("generate_cluster_galaxy"), &GalaxyGenerator::generateClusterGalaxy);
    ClassDB::bind_method(D_METHOD("sortShapes"), &GalaxyGenerator::sortShapes);
}

GalaxyGenerator::GalaxyGenerator() {
    // Initialize any variables here.
    maxOuterRadius = 0.0;
    PI = 3.14159265358979323846264338327;
}

GalaxyGenerator::~GalaxyGenerator() {
    // Add your cleanup here.
}
void GalaxyGenerator::_ready() {
	
}

double GalaxyGenerator::getBiggestStarSize(const unsigned int id) {
	Array stars = systemData[id].get("stars");
	double starSize = stars[0].get("size");
	for (unsigned int i = 1; i < stars.size(); i++) {
		double currentStarSize = stars[i].get("size");
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

bool GalaxyGenerator::sortShapes (Dictionary a, Dictionary b) {
	if (a["outer_radius"] < b["outer_radius"]) return true;
	return false;
}

Array GalaxyGenerator::generateClusterGalaxy() {
	double minDistanceFromCenter = 0.0;
	int gcRemaining = int(UtilityFunctions::pow(sysN, 0.8) / 250.0);
	int gcStarsRemaining = 0;
	int gcOffset = 0;
	Vector2 gcCenter = Vector2(0, 0);
	double maxDistanceFromCenter = 0;
	Array gcCircles;
	for (unsigned int i = 0; i < sysN; i++) {
		bool startingSystem = c_g_g == 0 && i == 0;
		int N = objShapes.size();
		// Whether to move on to a new "ring" for collision detection
		if (N >= sysN / 8) {
			objShapes.sort_custom(Callable(this,"sortShapes"));
			objShapes = objShapes.slice(int((N - 1) * 0.9), N - 1);
			minDistanceFromCenter = objShapes[0].get("outer_radius");
			// 								V this condition makes sure globular clusters don't spawn near the center
			if (gcRemaining > 0 && gcOffset > 1 + int(UtilityFunctions::pow(sysN, 0.1))) {
				gcRemaining -= 1;
				gcStarsRemaining = int(UtilityFunctions::pow(sysN, 0.5) * UtilityFunctions::randf_range(1, 3));
				gcCenter = Vector2::from_angle(UtilityFunctions::randf_range(0, 2 * PI)) * minDistanceFromCenter;
				maxDistanceFromCenter = 100;
			}
			gcOffset += 1;
		}
		double biggestStarSize = getBiggestStarSize(i);
		// Collision detection
		double radius = 320 * UtilityFunctions::pow(biggestStarSize / 100.0, 0.35);
		Dictionary circle;
		Vector2 pos;
		bool colliding = true;
		if (gcStarsRemaining == 0) {
			gcCenter = Vector2(0, 0);
			if (minDistanceFromCenter == 0.0) {
				maxDistanceFromCenter = 3000;
			} else {
				maxDistanceFromCenter = minDistanceFromCenter * UtilityFunctions::pow(sysN, 0.04) * 1.1;
			}
		}
		double outer_radius;
		int radiusIncreaseCounter = 0;
		while (colliding) {
			colliding = false;
			double distanceFromCenter = UtilityFunctions::randf_range(0, maxDistanceFromCenter);
			if (gcStarsRemaining == 0) {
				distanceFromCenter = UtilityFunctions::randf_range(minDistanceFromCenter + radius, maxDistanceFromCenter);
			}
			outer_radius = radius + distanceFromCenter;
			pos = Vector2::from_angle(UtilityFunctions::randf_range(0, 2 * PI)) * distanceFromCenter + gcCenter;
			circle["pos"] = pos;
			circle["radius"] = radius;
			circle["outer_radius"] = outer_radius;
			for (unsigned int j = 0; j < objShapes.size(); j++) {
				Dictionary starShape = objShapes[j];
				if (pos.distance_to(starShape["pos"]) < radius + (double)starShape["radius"]) {
					colliding = true;
					radiusIncreaseCounter += 1;
					if (radiusIncreaseCounter > 5) {
						maxDistanceFromCenter *= 1.2;
						radiusIncreaseCounter = 0;
					}
					break;
				}
			}
			if (!colliding) {
				for (unsigned int j = 0; j < gcCircles.size(); j++) {
					Dictionary gc_circle = gcCircles[j];
					if (pos.distance_to(gc_circle["pos"]) < radius + (double)gc_circle["radius"]) {
						colliding = true;
						radiusIncreaseCounter += 1;
						if (radiusIncreaseCounter > 5) {
							maxDistanceFromCenter *= 1.2;
							radiusIncreaseCounter = 0;
						}
						break;
					}
				}
			}
		}
		maxOuterRadius = UtilityFunctions::max(outer_radius, maxOuterRadius);
		if (gcStarsRemaining > 0) {
			gcStarsRemaining -= 1;
			gcCircles.append(circle);
			if (gcStarsRemaining == 0) {
				// Convert globular cluster to a single huge circle for collision detection purposes
				gcCircles.sort_custom(Callable(this,"sortShapes"));
				double big_radius = gcCircles[gcCircles.size()-1].get("outer_radius");
				Dictionary shape;
				shape["pos"] = gcCenter;
				shape["radius"] = big_radius;
				shape["outer_radius"] = gcCenter.length() + big_radius;
				objShapes.clear();
				objShapes.append(shape);
				gcCircles.clear();
			}
		} else if (!startingSystem) {
			objShapes.append(circle);
		}
		Dictionary s_i = systemData[i];
		if (startingSystem) {
			radius = 320 * UtilityFunctions::pow(1 / 100.0, 0.3);
			Dictionary shape;
			Vector2 s_i_pos = s_i["pos"];
			shape["pos"] = s_i_pos;
			shape["radius"] = radius;
			shape["outer_radius"] = s_i_pos.length() + radius;
			newSystemPositions[i] = s_i_pos;
			objShapes.append(shape);
			newSystemDifficulties[i] = s_i["diff"];
		} else {
			newSystemPositions[i] = pos;
			newSystemDifficulties[i] = calculateSystemDifficulty(pos, s_i["stars"]);
		}
	}
	Array res;
	res.append(newSystemPositions);
	res.append(newSystemDifficulties);
	return res;
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
		bool coll = true;
		int attempts = 0;
		while (coll) {
			coll = false;
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
		}
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
    			dict["pos"] = systemData[0].get("pos");
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
		combinedStarMass += (double)stars[i].get("mass");
	}
	if (c_g_g == 0) {
		return (1.0 + pos.distance_to(systemData[0].get("pos")) * UtilityFunctions::pow(combinedStarMass, 0.5) / 5000) * galaxyDifficulty;
	}
	return galaxyDifficulty * UtilityFunctions::pow(combinedStarMass, 0.4) * UtilityFunctions::randf_range(120, 150) / UtilityFunctions::maxf(100.0, UtilityFunctions::pow(pos.length(), 0.5));
}
	
