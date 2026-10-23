import bpy
import os
import math

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_commando_player(output_path):
    clear_scene()
    
    # 1. Materials
    armor_mat = bpy.data.materials.new(name="CommandoArmor")
    b = next(n for n in armor_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (0.85, 0.55, 0.15, 1.0) # Commando Orange
    b.inputs["Roughness"].default_value = 0.4
    b.inputs["Metallic"].default_value = 0.3
    
    suit_mat = bpy.data.materials.new(name="CommandoSuit")
    b2 = next(n for n in suit_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b2.inputs["Base Color"].default_value = (0.12, 0.14, 0.18, 1.0) # Dark gray undersuit
    b2.inputs["Roughness"].default_value = 0.7
    
    visor_mat = bpy.data.materials.new(name="CommandoVisor")
    b3 = next(n for n in visor_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b3.inputs["Base Color"].default_value = (0.1, 0.8, 1.0, 1.0) # Cyan glowing visor
    b3.inputs["Emission Color"].default_value = (0.1, 0.85, 1.0, 1.0)
    b3.inputs["Emission Strength"].default_value = 4.0
    
    gun_mat = bpy.data.materials.new(name="CommandoGuns")
    b4 = next(n for n in gun_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b4.inputs["Base Color"].default_value = (0.2, 0.22, 0.25, 1.0)
    b4.inputs["Metallic"].default_value = 0.9
    b4.inputs["Roughness"].default_value = 0.25
    
    # Root container
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "CommandoModel"
    
    # Torso
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 1.15))
    torso = bpy.context.active_object
    torso.name = "Torso"
    torso.scale = (0.42, 0.28, 0.52)
    torso.data.materials.append(armor_mat)
    torso.parent = root
    
    # Helmet
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.22, location=(0, 0, 1.62))
    head = bpy.context.active_object
    head.name = "Helmet"
    head.scale = (1.0, 1.05, 1.1)
    head.data.materials.append(suit_mat)
    head.parent = root
    
    # Visor
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.16, 1.62))
    visor = bpy.context.active_object
    visor.name = "Visor"
    visor.scale = (0.24, 0.08, 0.12)
    visor.data.materials.append(visor_mat)
    visor.parent = root
    
    # Jetpack
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0.2, 1.25))
    jetpack = bpy.context.active_object
    jetpack.name = "Jetpack"
    jetpack.scale = (0.32, 0.16, 0.38)
    jetpack.data.materials.append(gun_mat)
    jetpack.parent = root
    
    # Thruster nozzles
    for side, x in [("L", -0.1), ("R", 0.1)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=0.18, location=(x, 0.22, 0.98))
        noz = bpy.context.active_object
        noz.name = f"Thruster_{side}"
        noz.data.materials.append(visor_mat)
        noz.parent = root
    
    # Arms and Dual Blasters
    for side, x in [("L", -0.32), ("R", 0.32)]:
        # Shoulder/Arm
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.48, location=(x, 0, 1.15))
        arm = bpy.context.active_object
        arm.name = f"Arm_{side}"
        arm.rotation_euler = (math.radians(-25), 0, 0)
        arm.data.materials.append(armor_mat)
        arm.parent = root
        
        # Blaster Pistol
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, -0.32, 0.95))
        gun = bpy.context.active_object
        gun.name = f"Blaster_{side}"
        gun.scale = (0.08, 0.35, 0.14)
        gun.data.materials.append(gun_mat)
        gun.parent = root
        
        # Gun Muzzle
        bpy.ops.mesh.primitive_cylinder_add(radius=0.03, depth=0.12, location=(x, -0.52, 0.97))
        muzzle = bpy.context.active_object
        muzzle.name = f"Muzzle_{side}"
        muzzle.rotation_euler = (math.radians(90), 0, 0)
        muzzle.data.materials.append(visor_mat)
        muzzle.parent = root
    
    # Legs
    for side, x in [("L", -0.16), ("R", 0.16)]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=0.75, location=(x, 0, 0.45))
        leg = bpy.context.active_object
        leg.name = f"Leg_{side}"
        leg.data.materials.append(suit_mat)
        leg.parent = root
        
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(x, -0.06, 0.1))
        boot = bpy.context.active_object
        boot.name = f"Boot_{side}"
        boot.scale = (0.14, 0.26, 0.16)
        boot.data.materials.append(gun_mat)
        boot.parent = root
    
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Commando player exported to {output_path}")

def create_beetle_monster(output_path):
    clear_scene()
    
    shell_mat = bpy.data.materials.new(name="BeetleShell")
    b = next(n for n in shell_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (0.28, 0.12, 0.38, 1.0) # Alien purple carapace
    b.inputs["Roughness"].default_value = 0.35
    
    flesh_mat = bpy.data.materials.new(name="BeetleFlesh")
    b2 = next(n for n in flesh_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b2.inputs["Base Color"].default_value = (0.7, 0.25, 0.15, 1.0) # Fleshy orange underside
    b2.inputs["Roughness"].default_value = 0.8
    
    glow_mat = bpy.data.materials.new(name="BeetleGlow")
    b3 = next(n for n in glow_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b3.inputs["Base Color"].default_value = (0.9, 0.9, 0.1, 1.0)
    b3.inputs["Emission Color"].default_value = (0.95, 0.85, 0.1, 1.0)
    b3.inputs["Emission Strength"].default_value = 4.0
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "BeetleModel"
    
    # Carapace (Main body shell)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.65, location=(0, 0, 0.65))
    shell = bpy.context.active_object
    shell.name = "Carapace"
    shell.scale = (1.1, 1.4, 0.7)
    shell.data.materials.append(shell_mat)
    shell.parent = root
    
    # Head
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.85, 0.5))
    head = bpy.context.active_object
    head.name = "Head"
    head.scale = (0.6, 0.5, 0.4)
    head.data.materials.append(flesh_mat)
    head.parent = root
    
    # Mandibles
    for side, x in [("L", -0.28), ("R", 0.28)]:
        rot = math.radians(25) if side == "L" else math.radians(-25)
        bpy.ops.mesh.primitive_cone_add(radius1=0.1, depth=0.5, location=(x, -1.2, 0.45))
        mandible = bpy.context.active_object
        mandible.name = f"Mandible_{side}"
        mandible.rotation_euler = (math.radians(-80), 0, rot)
        mandible.data.materials.append(shell_mat)
        mandible.parent = root
    
    # Eyes
    for side, x in [("L", -0.22), ("R", 0.22)]:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.08, location=(x, -0.95, 0.65))
        eye = bpy.context.active_object
        eye.name = f"Eye_{side}"
        eye.data.materials.append(glow_mat)
        eye.parent = root
        
    # Legs (4 legs)
    leg_coords = [
        ("FL", -0.65, -0.3, math.radians(-30)),
        ("FR", 0.65, -0.3, math.radians(30)),
        ("BL", -0.65, 0.4, math.radians(-50)),
        ("BR", 0.65, 0.4, math.radians(50))
    ]
    for name, x, y, rot_z in leg_coords:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.09, depth=0.8, location=(x, y, 0.35))
        leg = bpy.context.active_object
        leg.name = f"Leg_{name}"
        leg.rotation_euler = (0, math.radians(35) if x > 0 else math.radians(-35), rot_z)
        leg.data.materials.append(shell_mat)
        leg.parent = root
        
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Beetle monster exported to {output_path}")

def create_wisp_monster(output_path):
    clear_scene()
    
    mask_mat = bpy.data.materials.new(name="WispMask")
    b = next(n for n in mask_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (0.2, 0.2, 0.25, 1.0) # Stone mask
    b.inputs["Roughness"].default_value = 0.85
    
    fire_mat = bpy.data.materials.new(name="WispFire")
    b2 = next(n for n in fire_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b2.inputs["Base Color"].default_value = (1.0, 0.4, 0.05, 1.0)
    b2.inputs["Emission Color"].default_value = (1.0, 0.35, 0.05, 1.0)
    b2.inputs["Emission Strength"].default_value = 6.0
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "WispModel"
    
    # Burning Core
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, location=(0, 0, 0.5))
    core = bpy.context.active_object
    core.name = "FireCore"
    core.data.materials.append(fire_mat)
    core.parent = root
    
    # Mask Shell
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(0, -0.15, 0.55))
    mask = bpy.context.active_object
    mask.name = "Mask"
    mask.scale = (0.8, 0.5, 0.9)
    mask.data.materials.append(mask_mat)
    mask.parent = root
    
    # Horns
    for side, x in [("L", -0.35), ("R", 0.35)]:
        rot_y = math.radians(-25) if side == "L" else math.radians(25)
        bpy.ops.mesh.primitive_cone_add(radius1=0.12, depth=0.7, location=(x, -0.1, 1.05))
        horn = bpy.context.active_object
        horn.name = f"Horn_{side}"
        horn.rotation_euler = (math.radians(-15), rot_y, 0)
        horn.data.materials.append(mask_mat)
        horn.parent = root
        
    # Orbiting flame wisps
    wisp_sparks = [
        ("Spark1", 0.45, 0.2, 0.3),
        ("Spark2", -0.4, 0.3, 0.7),
        ("Spark3", 0.0, 0.5, 0.2)
    ]
    for name, x, y, z in wisp_sparks:
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.12, location=(x, y, z))
        sp = bpy.context.active_object
        sp.name = name
        sp.data.materials.append(fire_mat)
        sp.parent = root
        
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Wisp monster exported to {output_path}")

def create_stone_titan(output_path):
    clear_scene()
    
    stone_mat = bpy.data.materials.new(name="StoneMaterial")
    bsdf = next(n for n in stone_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (0.28, 0.26, 0.32, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.92
    
    moss_mat = bpy.data.materials.new(name="TitanPlateMaterial")
    b2 = next(n for n in moss_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b2.inputs["Base Color"].default_value = (0.18, 0.16, 0.22, 1.0)
    b2.inputs["Roughness"].default_value = 0.85
    
    eye_mat = bpy.data.materials.new(name="TitanEyeMaterial")
    eye_bsdf = next(n for n in eye_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    eye_bsdf.inputs["Base Color"].default_value = (1.0, 0.2, 0.05, 1.0)
    eye_bsdf.inputs["Emission Color"].default_value = (1.0, 0.15, 0.05, 1.0)
    eye_bsdf.inputs["Emission Strength"].default_value = 7.0
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "StoneTitanModel"
    
    # 2. Торс - массивный монолит
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 3.2))
    torso = bpy.context.active_object
    torso.name = "Torso"
    torso.scale = (2.6, 2.2, 4.2)
    torso.data.materials.append(stone_mat)
    torso.parent = root
    
    # Нагрудные плиты
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -1.05, 3.5))
    chest_plate = bpy.context.active_object
    chest_plate.name = "ChestPlate"
    chest_plate.scale = (2.2, 0.4, 2.4)
    chest_plate.data.materials.append(moss_mat)
    chest_plate.parent = root
    
    # Плечи
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-1.9, 0, 4.6))
    shoulder_l = bpy.context.active_object
    shoulder_l.name = "Shoulder_L"
    shoulder_l.scale = (1.5, 1.7, 1.5)
    shoulder_l.data.materials.append(moss_mat)
    shoulder_l.parent = root
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(1.9, 0, 4.6))
    shoulder_r = bpy.context.active_object
    shoulder_r.name = "Shoulder_R"
    shoulder_r.scale = (1.5, 1.7, 1.5)
    shoulder_r.data.materials.append(moss_mat)
    shoulder_r.parent = root
    
    # Руки
    bpy.ops.mesh.primitive_cylinder_add(radius=0.65, depth=4.0, location=(-2.3, 0, 2.3))
    arm_l = bpy.context.active_object
    arm_l.name = "Arm_L"
    arm_l.data.materials.append(stone_mat)
    arm_l.parent = root
    
    bpy.ops.mesh.primitive_cylinder_add(radius=0.65, depth=4.0, location=(2.3, 0, 2.3))
    arm_r = bpy.context.active_object
    arm_r.name = "Arm_R"
    arm_r.data.materials.append(stone_mat)
    arm_r.parent = root
    
    # Кулаки
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-2.3, 0, 0.3))
    fist_l = bpy.context.active_object
    fist_l.name = "Fist_L"
    fist_l.scale = (1.2, 1.4, 1.2)
    fist_l.data.materials.append(moss_mat)
    fist_l.parent = root
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(2.3, 0, 0.3))
    fist_r = bpy.context.active_object
    fist_r.name = "Fist_R"
    fist_r.scale = (1.2, 1.4, 1.2)
    fist_r.data.materials.append(moss_mat)
    fist_r.parent = root
    
    # Голова и лазерный глаз
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.7, 4.3))
    head = bpy.context.active_object
    head.name = "Head"
    head.scale = (1.5, 1.3, 1.3)
    head.data.materials.append(stone_mat)
    head.parent = root
    
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.48, location=(0, -1.35, 4.3))
    eye = bpy.context.active_object
    eye.name = "LaserEye"
    eye.data.materials.append(eye_mat)
    eye.parent = root
    
    # Ноги / опора
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.95, 0, 0.75))
    leg_l = bpy.context.active_object
    leg_l.name = "Leg_L"
    leg_l.scale = (1.1, 1.3, 1.5)
    leg_l.data.materials.append(stone_mat)
    leg_l.parent = root
    
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.95, 0, 0.75))
    leg_r = bpy.context.active_object
    leg_r.name = "Leg_R"
    leg_r.scale = (1.1, 1.3, 1.5)
    leg_r.data.materials.append(stone_mat)
    leg_r.parent = root
    
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Titan exported to {output_path}")

def create_scifi_chest(output_path):
    clear_scene()
    
    metal_mat = bpy.data.materials.new(name="ChestMetal")
    b = next(n for n in metal_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (0.78, 0.42, 0.1, 1.0)
    b.inputs["Metallic"].default_value = 0.85
    b.inputs["Roughness"].default_value = 0.35
    
    dark_mat = bpy.data.materials.new(name="ChestDark")
    b2 = next(n for n in dark_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b2.inputs["Base Color"].default_value = (0.12, 0.12, 0.16, 1.0)
    b2.inputs["Metallic"].default_value = 0.9
    
    glow_mat = bpy.data.materials.new(name="ChestGlow")
    b3 = next(n for n in glow_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b3.inputs["Base Color"].default_value = (1.0, 0.8, 0.2, 1.0)
    b3.inputs["Emission Color"].default_value = (1.0, 0.8, 0.2, 1.0)
    b3.inputs["Emission Strength"].default_value = 4.0
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "ChestModel"
    
    # Основа сундука
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.35))
    base = bpy.context.active_object
    base.name = "ChestBase"
    base.scale = (1.4, 0.9, 0.7)
    base.data.materials.append(metal_mat)
    base.parent = root
    
    # Крышка
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.82))
    lid = bpy.context.active_object
    lid.name = "ChestLid"
    lid.scale = (1.46, 0.96, 0.26)
    lid.data.materials.append(dark_mat)
    lid.parent = root
    
    # Неоновый замок
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.49, 0.65))
    lock = bpy.context.active_object
    lock.name = "ChestLock"
    lock.scale = (0.35, 0.08, 0.2)
    lock.data.materials.append(glow_mat)
    lock.parent = root
    
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Chest exported to {output_path}")

def create_teleporter_model(output_path):
    clear_scene()
    
    stone_mat = bpy.data.materials.new(name="TeleporterStone")
    b = next(n for n in stone_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (0.16, 0.15, 0.2, 1.0)
    b.inputs["Roughness"].default_value = 0.88
    
    rune_mat = bpy.data.materials.new(name="TeleporterRunes")
    b2 = next(n for n in rune_mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b2.inputs["Base Color"].default_value = (1.0, 0.45, 0.1, 1.0)
    b2.inputs["Emission Color"].default_value = (1.0, 0.45, 0.1, 1.0)
    b2.inputs["Emission Strength"].default_value = 5.0
    
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "TeleporterModel"
    
    # Платформа
    bpy.ops.mesh.primitive_cylinder_add(radius=2.8, depth=0.4, location=(0, 0, 0.2))
    pad = bpy.context.active_object
    pad.name = "Pad"
    pad.data.materials.append(stone_mat)
    pad.parent = root
    
    # Рунические кольца
    bpy.ops.mesh.primitive_cylinder_add(radius=2.2, depth=0.44, location=(0, 0, 0.22))
    ring = bpy.context.active_object
    ring.name = "RuneRing"
    ring.scale = (1.0, 1.0, 0.2)
    ring.data.materials.append(rune_mat)
    ring.parent = root
    
    # Левый рог
    bpy.ops.mesh.primitive_cone_add(radius1=0.75, depth=6.2, location=(-1.9, 0, 3.1))
    horn_l = bpy.context.active_object
    horn_l.name = "Horn_L"
    horn_l.rotation_euler = (0, math.radians(-12), 0)
    horn_l.data.materials.append(stone_mat)
    horn_l.parent = root
    
    # Правый рог
    bpy.ops.mesh.primitive_cone_add(radius1=0.75, depth=6.2, location=(1.9, 0, 3.1))
    horn_r = bpy.context.active_object
    horn_r.name = "Horn_R"
    horn_r.rotation_euler = (0, math.radians(12), 0)
    horn_r.data.materials.append(stone_mat)
    horn_r.parent = root
    
    # Центральный кристалл
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(0, 0, 3.3))
    crystal = bpy.context.active_object
    crystal.name = "RiftCrystal"
    crystal.data.materials.append(rune_mat)
    crystal.parent = root
    
    bpy.ops.export_scene.gltf(filepath=output_path, export_format='GLB')
    print(f"Teleporter exported to {output_path}")

out_dir = r"c:\Users\ilyap\program\assets\models"
os.makedirs(out_dir, exist_ok=True)
create_commando_player(os.path.join(out_dir, "commando.glb"))
create_beetle_monster(os.path.join(out_dir, "beetle.glb"))
create_wisp_monster(os.path.join(out_dir, "wisp.glb"))
create_stone_titan(os.path.join(out_dir, "stone_titan.glb"))
create_scifi_chest(os.path.join(out_dir, "scifi_chest.glb"))
create_teleporter_model(os.path.join(out_dir, "teleporter.glb"))
print("ALL 6 Blender 3D models generated successfully!")
