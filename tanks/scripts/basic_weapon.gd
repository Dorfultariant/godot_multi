extends Node3D

# This is basic weapon Node3D with with a weapon resource attached to it
# Add only meshes, animations for meshes and Marker3D (AmmoSpawn location) to this node.
# Weapon Manager handles the weapon shooting and animation for different actions
# such as firing, reloading, activation and deactivation (e.g. TOW opens, closes) for weapon switching.

# If special weapon reloading times etc. needs to be added, adjust the Weapon Resource for the weapon
@export var weapon_resource : Weapon_Resource
