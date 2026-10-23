import bpy
import os
import math

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, base_color, metallic=0.0, roughness=0.5, emission=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = base_color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        # Blender 4+ Principled BSDF emission inputs
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission
            bsdf.inputs["Emission Strength"].default_value = emission_strength
        elif "Emission" in bsdf.inputs:
            bsdf.inputs["Emission"].default_value = emission
    return mat

def create_commando_model(output_path):
    clear_scene()
    
    # Materials - Titanium White/Blue, Dark Matte Joints, Cyan Neon Visor, Plasma Gun
    armor_mat = create_pbr_material("CommandoArmor", (0.76, 0.83, 0.92, 1.0), metallic=0.45, roughness=0.35)
    undersuit_mat = create_pbr_material("CommandoUndersuit", (0.15, 0.17, 0.22, 1.0), metallic=0.1, roughness=0.7)
    neon_mat = create_pbr_material("CommandoNeon", (0.1, 0.85, 1.0, 1.0), emission=(0.1, 0.88, 1.0, 1.0), emission_strength=5.0)
    gun_mat = create_pbr_material("CommandoGun", (0.22, 0.24, 0.28, 1.0), metallic=0.85, roughness=0.25)
    reactor_mat = create_pbr_material("CommandoReactor", (1.0, 0.6, 0.1, 1.0), emission=(1.0, 0.6, 0.1, 1.0), emission_strength=4.0)
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "CommandoModel"
    
    # 1. Torso & Armor Plates
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.15))
    torso = bpy.context.active_object
    torso.name = "Torso"
    torso.scale = (0.44, 0.3, 0.52)
    torso.data.materials.append(armor_mat)
    torso.parent = root
    
    # Chestplate
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.16, 1.22))
    chestplate = bpy.context.active_object
    chestplate.name = "ChestPlate"
    chestplate.scale = (0.38, 0.08, 0.32)
    chestplate.data.materials.append(armor_mat)
    chestplate.parent = root
    
    # Central Reactor Core
    bpy.ops.mesh.primitive_cylinder_add(radius=0.07, depth=0.08, location=(0, -0.21, 1.22))
    reactor = bpy.context.active_object
    reactor.name = "ReactorCore"
    reactor.rotation_euler = (math.radians(90), 0, 0)
    reactor.data.materials.append(reactor_mat)
    reactor.parent = root
    
    # 2. Helmet & Visor
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.22, location=(0, -0.02, 1.62))
    head = bpy.context.active_object
    head.name = "Helmet"
    head.scale = (1.0, 1.1, 1.05)
    head.data.materials.append(armor_mat)
    head.parent = root
    
    # Angled Visor
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.18, 1.62))
    visor = bpy.context.active_object
    visor.name = "Visor"
    visor.scale = (0.28, 0.09, 0.12)
    visor.data.materials.append(neon_mat)
    visor.parent = root
    
    # 3. Jetpack with Dual Thrusters
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.22, 1.25))
    jetpack = bpy.context.active_object
    jetpack.name = "Jetpack"
    jetpack.scale = (0.34, 0.16, 0.42)
    jetpack.data.materials.append(gun_mat)
    jetpack.parent = root
    
    for side, x in [("L", -0.11), ("R", 0.11)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.065, depth=0.22, location=(x, 0.25, 0.98))
        noz = bpy.context.active_object
        noz.name = f"Thruster_{side}"
        noz.data.materials.append(neon_mat)
        noz.parent = root
    
    # 4. Pauldrons (Shoulder pads)
    for side, x in [("L", -0.32), ("R", 0.32)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 0, 1.38))
        pad = bpy.context.active_object
        pad.name = f"Pauldron_{side}"
        pad.scale = (0.16, 0.22, 0.14)
        pad.rotation_euler = (0, math.radians(-15 if side == "L" else 15), 0)
        pad.data.materials.append(armor_mat)
        pad.parent = root
    
    # 5. Arms and Plasma Rifle
    for side, x in [("L", -0.34), ("R", 0.34)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.075, depth=0.46, location=(x, -0.06, 1.15))
        arm = bpy.context.active_object
        arm.name = f"Arm_{side}"
        arm.rotation_euler = (math.radians(-25), 0, 0)
        arm.data.materials.append(undersuit_mat)
        arm.parent = root
        
        # Forearm armor
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, -0.18, 0.96))
        forearm = bpy.context.active_object
        forearm.name = f"Forearm_{side}"
        forearm.scale = (0.12, 0.22, 0.12)
        forearm.data.materials.append(armor_mat)
        forearm.parent = root
    
    # Main Assault Plasma Rifle (held in right/forward hands)
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.28, -0.42, 0.98))
    rifle = bpy.context.active_object
    rifle.name = "PlasmaRifle"
    rifle.scale = (0.09, 0.65, 0.18)
    rifle.data.materials.append(gun_mat)
    rifle.parent = root
    
    # Rifle Barrel with neon glow
    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.45, location=(0.28, -0.78, 1.02))
    barrel = bpy.context.active_object
    barrel.name = "RifleBarrel"
    barrel.rotation_euler = (math.radians(90), 0, 0)
    barrel.data.materials.append(neon_mat)
    barrel.parent = root
    
    # Secondary Left Blaster
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.28, -0.35, 0.95))
    lblaster = bpy.context.active_object
    lblaster.name = "LeftBlaster"
    lblaster.scale = (0.08, 0.38, 0.14)
    lblaster.data.materials.append(gun_mat)
    lblaster.parent = root
    
    # 6. Legs, Thigh Armor, Shins & Boots
    for side, x in [("L", -0.16), ("R", 0.16)]:
        # Thigh
        bpy.ops.mesh.primitive_cylinder_add(radius=0.09, depth=0.45, location=(x, 0, 0.68))
        thigh = bpy.context.active_object
        thigh.name = f"Thigh_{side}"
        thigh.data.materials.append(undersuit_mat)
        thigh.parent = root
        
        # Knee pad
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, -0.11, 0.48))
        knee = bpy.context.active_object
        knee.name = f"Knee_{side}"
        knee.scale = (0.13, 0.08, 0.12)
        knee.data.materials.append(armor_mat)
        knee.parent = root
        
        # Shin
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.42, location=(x, 0, 0.28))
        shin = bpy.context.active_object
        shin.name = f"Shin_{side}"
        shin.data.materials.append(armor_mat)
        shin.parent = root
        
        # Boot
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, -0.06, 0.08))
        boot = bpy.context.active_object
        boot.name = f"Boot_{side}"
        boot.scale = (0.15, 0.28, 0.15)
        boot.data.materials.append(gun_mat)
        boot.parent = root
        
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Commando model exported to {output_path}")

def create_beetle_model(output_path):
    clear_scene()
    
    chitin_mat = create_pbr_material("BeetleChitin", (0.32, 0.16, 0.42, 1.0), metallic=0.25, roughness=0.4)
    belly_mat = create_pbr_material("BeetleBelly", (0.55, 0.28, 0.18, 1.0), metallic=0.0, roughness=0.7)
    eye_mat = create_pbr_material("BeetleEyes", (1.0, 0.85, 0.1, 1.0), emission=(1.0, 0.85, 0.1, 1.0), emission_strength=4.5)
    vein_mat = create_pbr_material("BeetleVeins", (0.2, 0.95, 0.4, 1.0), emission=(0.2, 0.95, 0.4, 1.0), emission_strength=4.0)
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "BeetleModel"
    
    # 3-segment chitin carapace
    for i, (z, y, r, scale_z) in enumerate([(0.62, 0.15, 0.65, 0.85), (0.72, -0.15, 0.58, 0.9), (0.78, -0.45, 0.45, 0.75)]):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=(0, y, z))
        seg = bpy.context.active_object
        seg.name = f"CarapaceSeg_{i}"
        seg.scale = (1.1, 0.95, scale_z)
        seg.data.materials.append(chitin_mat)
        seg.parent = root
        
    # Glowing bioluminescent spine vein
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.1, 0.95))
    vein = bpy.context.active_object
    vein.name = "BiolumVein"
    vein.scale = (0.08, 0.85, 0.12)
    vein.data.materials.append(vein_mat)
    vein.parent = root
    
    # Head and Mandibles
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.35, location=(0, -0.75, 0.52))
    head = bpy.context.active_object
    head.name = "Head"
    head.scale = (1.0, 1.15, 0.85)
    head.data.materials.append(chitin_mat)
    head.parent = root
    
    # 4 Glowing Eyes
    for x, y, z in [(-0.16, -0.92, 0.62), (0.16, -0.92, 0.62), (-0.24, -0.85, 0.52), (0.24, -0.85, 0.52)]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.065, location=(x, y, z))
        eye = bpy.context.active_object
        eye.data.materials.append(eye_mat)
        eye.parent = root
        
    # Curved Mandibles (pincers)
    for side, x in [("L", -0.22), ("R", 0.22)]:
        bpy.ops.mesh.primitive_cone_add(radius1=0.08, depth=0.45, location=(x, -1.05, 0.42))
        mandible = bpy.context.active_object
        mandible.name = f"Mandible_{side}"
        mandible.rotation_euler = (math.radians(-75), math.radians(-25 if side == "L" else 25), 0)
        mandible.data.materials.append(chitin_mat)
        mandible.parent = root
        
    # 6 Jointed Insect Legs
    for side, x_mult in [("L", -1), ("R", 1)]:
        for i, (y, yaw) in enumerate([(-0.35, 35), (0.05, 0), (0.45, -35)]):
            bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.55, location=(x_mult * 0.65, y, 0.48))
            femur = bpy.context.active_object
            femur.name = f"LegFemur_{side}_{i}"
            femur.rotation_euler = (0, math.radians(x_mult * 45), math.radians(yaw))
            femur.data.materials.append(chitin_mat)
            femur.parent = root
            
            bpy.ops.mesh.primitive_cylinder_add(radius=0.045, depth=0.6, location=(x_mult * 0.95, y, 0.2))
            tibia = bpy.context.active_object
            tibia.name = f"LegTibia_{side}_{i}"
            tibia.rotation_euler = (0, math.radians(x_mult * -35), math.radians(yaw))
            tibia.data.materials.append(belly_mat)
            tibia.parent = root

    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Beetle model exported to {output_path}")

def create_wisp_model(output_path):
    clear_scene()
    
    mask_mat = create_pbr_material("WispMask", (0.28, 0.26, 0.32, 1.0), metallic=0.7, roughness=0.35)
    rune_mat = create_pbr_material("WispRunes", (1.0, 0.55, 0.1, 1.0), emission=(1.0, 0.5, 0.08, 1.0), emission_strength=5.0)
    flame_mat = create_pbr_material("WispFlame", (1.0, 0.4, 0.05, 1.0), emission=(1.0, 0.35, 0.05, 1.0), emission_strength=6.0)
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "WispModel"
    
    # 1. Central Fiery Flame Core
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, location=(0, 0, 0))
    core = bpy.context.active_object
    core.name = "FireCore"
    core.scale = (1.0, 1.0, 1.25)
    core.data.materials.append(flame_mat)
    core.parent = root
    
    # 2. Ancient Carved Stone Mask
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.35, 0.05))
    mask = bpy.context.active_object
    mask.name = "Mask"
    mask.scale = (0.55, 0.12, 0.65)
    mask.data.materials.append(mask_mat)
    mask.parent = root
    
    # Horns on Mask
    for side, x in [("L", -0.22), ("R", 0.22)]:
        bpy.ops.mesh.primitive_cone_add(radius1=0.09, depth=0.55, location=(x, -0.32, 0.45))
        horn = bpy.context.active_object
        horn.name = f"MaskHorn_{side}"
        horn.rotation_euler = (math.radians(-25), math.radians(-30 if side == "L" else 30), 0)
        horn.data.materials.append(mask_mat)
        horn.parent = root
        
    # Mask Eye Slits
    for x in [-0.14, 0.14]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, -0.42, 0.1))
        slit = bpy.context.active_object
        slit.scale = (0.1, 0.06, 0.06)
        slit.data.materials.append(rune_mat)
        slit.parent = root
        
    # 3. Two Orbital Rune Rings
    bpy.ops.mesh.primitive_torus_add(major_radius=0.85, minor_radius=0.035, location=(0, 0, 0))
    ring1 = bpy.context.active_object
    ring1.name = "RuneRing_Horizontal"
    ring1.data.materials.append(rune_mat)
    ring1.parent = root
    
    bpy.ops.mesh.primitive_torus_add(major_radius=0.92, minor_radius=0.035, location=(0, 0, 0))
    ring2 = bpy.context.active_object
    ring2.name = "RuneRing_Vertical"
    ring2.rotation_euler = (math.radians(65), math.radians(25), 0)
    ring2.data.materials.append(rune_mat)
    ring2.parent = root

    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Wisp model exported to {output_path}")

def create_stone_titan_model(output_path):
    clear_scene()
    
    stone_mat = create_pbr_material("TitanStone", (0.35, 0.32, 0.38, 1.0), metallic=0.15, roughness=0.85)
    plate_mat = create_pbr_material("TitanPlates", (0.24, 0.22, 0.26, 1.0), metallic=0.35, roughness=0.6)
    rune_mat = create_pbr_material("TitanRuneCracks", (1.0, 0.35, 0.1, 1.0), emission=(1.0, 0.3, 0.08, 1.0), emission_strength=5.5)
    eye_mat = create_pbr_material("TitanEyeLaser", (1.0, 0.15, 0.05, 1.0), emission=(1.0, 0.15, 0.05, 1.0), emission_strength=7.0)
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "TitanModel"
    
    # 1. Colossal Column Legs
    for side, x in [("L", -1.2), ("R", 1.2)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.75, depth=3.2, location=(x, 0, 1.6))
        leg = bpy.context.active_object
        leg.name = f"PillarLeg_{side}"
        leg.data.materials.append(stone_mat)
        leg.parent = root
        
        # Heavy stone foot
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, -0.4, 0.45))
        foot = bpy.context.active_object
        foot.name = f"Foot_{side}"
        foot.scale = (1.5, 2.2, 0.9)
        foot.data.materials.append(stone_mat)
        foot.parent = root
        
    # 2. Torso made of giant stone slabs
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 4.3))
    torso = bpy.context.active_object
    torso.name = "TorsoSlab"
    torso.scale = (3.4, 2.4, 2.6)
    torso.data.materials.append(stone_mat)
    torso.parent = root
    
    # Front Rune Chest Plate
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.3, 4.5))
    cplate = bpy.context.active_object
    cplate.name = "ChestPlate"
    cplate.scale = (2.6, 0.45, 1.8)
    cplate.data.materials.append(plate_mat)
    cplate.parent = root
    
    # Glowing Rune Core on Chest
    bpy.ops.mesh.primitive_cylinder_add(radius=0.45, depth=0.3, location=(0, -1.5, 4.5))
    rcore = bpy.context.active_object
    rcore.name = "RuneCore"
    rcore.rotation_euler = (math.radians(90), 0, 0)
    rcore.data.materials.append(rune_mat)
    rcore.parent = root
    
    # 3. Floating Monolithic Shoulder Stones (detached floating in air)
    for side, x in [("L", -2.8), ("R", 2.8)]:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, 0, 5.4))
        p = bpy.context.active_object
        p.name = f"FloatingMonolith_{side}"
        p.scale = (1.4, 1.5, 1.8)
        p.rotation_euler = (0, 0, math.radians(-18 if side == "L" else 18))
        p.data.materials.append(plate_mat)
        p.parent = root
        
        # Massive arm
        bpy.ops.mesh.primitive_cylinder_add(radius=0.65, depth=3.2, location=(x * 0.9, 0, 3.2))
        arm = bpy.context.active_object
        arm.name = f"Arm_{side}"
        arm.data.materials.append(stone_mat)
        arm.parent = root
        
        # Giant Stone Fist
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x * 0.9, -0.2, 1.4))
        fist = bpy.context.active_object
        fist.name = f"Fist_{side}"
        fist.scale = (1.4, 1.6, 1.5)
        fist.data.materials.append(stone_mat)
        fist.parent = root
        
    # 4. Head and Glowing Laser Eye
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.4, 6.1))
    head = bpy.context.active_object
    head.name = "Head"
    head.scale = (1.8, 1.6, 1.3)
    head.data.materials.append(stone_mat)
    head.parent = root
    
    # Bright Laser Eye
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(0, -1.25, 6.1))
    eye = bpy.context.active_object
    eye.name = "LaserEye"
    eye.scale = (1.0, 0.45, 1.0)
    eye.data.materials.append(eye_mat)
    eye.parent = root

    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Stone Titan model exported to {output_path}")

def create_chest_model(output_path):
    clear_scene()
    
    metal_mat = create_pbr_material("ChestMetal", (0.85, 0.45, 0.12, 1.0), metallic=0.7, roughness=0.35)
    dark_mat = create_pbr_material("ChestDark", (0.16, 0.18, 0.22, 1.0), metallic=0.85, roughness=0.25)
    glow_mat = create_pbr_material("ChestGlow", (0.2, 0.9, 1.0, 1.0), emission=(0.2, 0.9, 1.0, 1.0), emission_strength=5.0)
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "SciFiChestModel"
    
    # Base Box
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.35))
    base = bpy.context.active_object
    base.name = "ChestBase"
    base.scale = (1.4, 0.9, 0.65)
    base.data.materials.append(metal_mat)
    base.parent = root
    
    # Ribbed Reinforced Trim
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.35))
    trim = bpy.context.active_object
    trim.name = "ChestTrim"
    trim.scale = (1.46, 0.96, 0.45)
    trim.data.materials.append(dark_mat)
    trim.parent = root
    
    # Hinged Lid
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.8))
    lid = bpy.context.active_object
    lid.name = "ChestLid"
    lid.scale = (1.44, 0.94, 0.35)
    lid.data.materials.append(dark_mat)
    lid.parent = root
    
    # Front Neon Lock / Price Indicator
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.48, 0.55))
    lock = bpy.context.active_object
    lock.name = "ChestLock"
    lock.scale = (0.42, 0.08, 0.24)
    lock.data.materials.append(glow_mat)
    lock.parent = root

    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Chest model exported to {output_path}")

def create_teleporter_model(output_path):
    clear_scene()
    
    stone_mat = create_pbr_material("TeleporterStone", (0.26, 0.25, 0.3, 1.0), metallic=0.2, roughness=0.85)
    rune_mat = create_pbr_material("TeleporterRunes", (1.0, 0.55, 0.15, 1.0), emission=(1.0, 0.5, 0.1, 1.0), emission_strength=5.0)
    crystal_mat = create_pbr_material("TeleporterCrystal", (0.2, 0.95, 1.0, 1.0), emission=(0.2, 0.95, 1.0, 1.0), emission_strength=6.0)
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "TeleporterModel"
    
    # Stepped Circular Stone Platform
    bpy.ops.mesh.primitive_cylinder_add(radius=4.5, depth=0.4, location=(0, 0, 0.2))
    base = bpy.context.active_object
    base.name = "StepBase"
    base.data.materials.append(stone_mat)
    base.parent = root
    
    bpy.ops.mesh.primitive_cylinder_add(radius=3.4, depth=0.4, location=(0, 0, 0.5))
    mid = bpy.context.active_object
    mid.name = "StepMid"
    mid.data.materials.append(stone_mat)
    mid.parent = root
    
    # Inlaid Circular Rune Track
    bpy.ops.mesh.primitive_torus_add(major_radius=2.8, minor_radius=0.08, location=(0, 0, 0.72))
    track = bpy.context.active_object
    track.name = "RuneTrack"
    track.data.materials.append(rune_mat)
    track.parent = root
    
    # 4 Curved Obelisks / Horns
    for i in range(4):
        angle = i * (math.pi / 2.0) + (math.pi / 4.0)
        x = math.cos(angle) * 3.2
        y = math.sin(angle) * 3.2
        bpy.ops.mesh.primitive_cone_add(radius1=0.45, depth=4.8, location=(x, y, 2.6))
        obelisk = bpy.context.active_object
        obelisk.name = f"Obelisk_{i}"
        obelisk.rotation_euler = (math.sin(angle) * 0.18, -math.cos(angle) * 0.18, 0)
        obelisk.data.materials.append(stone_mat)
        obelisk.parent = root
        
    # Central Floating Rift Crystal
    bpy.ops.mesh.primitive_octahedron_add(radius=0.75, location=(0, 0, 2.8))
    crystal = bpy.context.active_object
    crystal.name = "RiftCrystal"
    crystal.data.materials.append(crystal_mat)
    crystal.parent = root
    
    # Vertical Sky Beam Spire
    bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=50.0, location=(0, 0, 25.0))
    beam = bpy.context.active_object
    beam.name = "SkyBeamSpire"
    beam.data.materials.append(rune_mat)
    beam.parent = root

    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Teleporter model exported to {output_path}")

def generate_all(models_dir):
    os.makedirs(models_dir, exist_ok=True)
    create_commando_model(os.path.join(models_dir, "commando.glb"))
    create_beetle_model(os.path.join(models_dir, "beetle.glb"))
    create_wisp_model(os.path.join(models_dir, "wisp.glb"))
    create_stone_titan_model(os.path.join(models_dir, "stone_titan.glb"))
    create_chest_model(os.path.join(models_dir, "scifi_chest.glb"))
    create_teleporter_model(os.path.join(models_dir, "teleporter.glb"))
    print("All models generated successfully via Blender!")

if __name__ == "__main__":
    generate_all(r"c:/Users/ilyap/program/assets/models")
