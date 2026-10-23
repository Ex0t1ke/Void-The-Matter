"""
VOID THE MATTER - Environment Asset Pack Generator (First Stage: Planetary Protocol)
Runs inside Blender to generate and export modular environment kit to GLTF/GLB.
"""
import bpy
import bmesh
import math
from mathutils import Vector, Matrix, Euler

def build_environment_pack(export_path="C:/Users/ilyap/program/assets/models/environment/first_stage_pack.glb"):
    col_name = "VTM_Environment_Pack"
    if col_name not in bpy.data.collections:
        col = bpy.data.collections.new(col_name)
        bpy.context.scene.collection.children.link(col)
    else:
        col = bpy.data.collections[col_name]

    for obj in list(col.objects):
        bpy.data.objects.remove(obj, do_unlink=True)

    def get_or_create_material(name, base_color, roughness=0.5, emission_color=None, emission_strength=0.0):
        mat = bpy.data.materials.get(name)
        if not mat:
            mat = bpy.data.materials.new(name=name)
        mat.use_nodes = True
        tree = mat.node_tree
        bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Roughness"].default_value = roughness
        mat.diffuse_color = base_color
        if emission_color and emission_strength > 0:
            bsdf.inputs["Emission Color"].default_value = emission_color
            bsdf.inputs["Emission Strength"].default_value = emission_strength
        else:
            bsdf.inputs["Emission Strength"].default_value = 0.0
        return mat

    mat_rock = get_or_create_material("M_Rock", (0.13, 0.11, 0.18, 1.0), roughness=0.9)
    mat_cyan = get_or_create_material("M_Neon_Cyan", (0.0, 0.94, 1.0, 1.0), roughness=0.2, emission_color=(0.0, 0.94, 1.0, 1.0), emission_strength=4.0)
    mat_orange = get_or_create_material("M_Neon_Orange", (1.0, 0.67, 0.0, 1.0), roughness=0.2, emission_color=(1.0, 0.67, 0.0, 1.0), emission_strength=4.0)
    mat_emission = get_or_create_material("M_Emission", (0.0, 0.94, 1.0, 1.0), roughness=0.2, emission_color=(0.0, 0.94, 1.0, 1.0), emission_strength=4.0)

    def finalize_mesh(obj_name, bm, materials, location):
        me = bpy.data.meshes.new(obj_name + "_Mesh")
        bm.to_mesh(me)
        bm.free()
        for mat in materials:
            me.materials.append(mat)
        for poly in me.polygons:
            poly.use_smooth = False
        obj = bpy.data.objects.new(obj_name, me)
        col.objects.link(obj)
        verts = [v.co for v in me.vertices]
        if verts:
            min_x = min(v.x for v in verts)
            max_x = max(v.x for v in verts)
            min_y = min(v.y for v in verts)
            max_y = max(v.y for v in verts)
            min_z = min(v.z for v in verts)
            shift = Vector((-(min_x + max_x) * 0.5, -(min_y + max_y) * 0.5, -min_z))
            for v in me.vertices:
                v.co += shift
            me.update()
        obj.location = Vector((location[0], location[1], 0.0))
        return obj

    offsets_large = [
        [1.0, 1.15, 0.9, 1.2, 0.95, 1.1, 0.85, 1.05],
        [1.1, 0.95, 1.25, 0.9, 1.15, 1.0, 1.2, 0.9],
        [0.95, 1.05, 0.9, 1.1, 1.0, 0.9, 1.05, 1.0],
        [1.0, 1.05, 0.95, 1.0, 1.05, 0.95, 1.0, 1.05]
    ]
    offsets_med = [
        [0.9, 1.1, 0.95, 1.05, 1.15, 0.85, 1.0],
        [1.15, 0.9, 1.1, 0.95, 1.05, 1.1, 0.9],
        [0.95, 1.05, 0.9, 1.1, 0.95, 1.0, 1.05],
        [1.0, 0.95, 1.05, 1.0, 0.95, 1.05, 1.0]
    ]
    offsets_spire = [
        [1.1, 0.9, 1.15, 0.85, 1.05, 0.95],
        [0.95, 1.1, 0.9, 1.15, 0.95, 1.05],
        [1.05, 0.95, 1.0, 0.9, 1.05, 0.95],
        [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    ]

    def create_rock_monolith(name, base_r, mid_r, top_r, height, num_sides, offsets, loc):
        bm = bmesh.new()
        bot_verts = [bm.verts.new((base_r * offsets[0][i % len(offsets[0])] * math.cos(i * 2 * math.pi / num_sides),
                                  base_r * offsets[0][i % len(offsets[0])] * math.sin(i * 2 * math.pi / num_sides), 0.0)) for i in range(num_sides)]
        mid_verts = [bm.verts.new((mid_r * offsets[1][i % len(offsets[1])] * math.cos((i + 0.5) * 2 * math.pi / num_sides),
                                  mid_r * offsets[1][i % len(offsets[1])] * math.sin((i + 0.5) * 2 * math.pi / num_sides), height * 0.45)) for i in range(num_sides)]
        upper_verts = [bm.verts.new((mid_r * 0.9 * offsets[2][i % len(offsets[2])] * math.cos(i * 2 * math.pi / num_sides),
                                    mid_r * 0.9 * offsets[2][i % len(offsets[2])] * math.sin(i * 2 * math.pi / num_sides), height * 0.8)) for i in range(num_sides)]
        top_verts = [bm.verts.new((top_r * offsets[3][i % len(offsets[3])] * math.cos((i + 0.25) * 2 * math.pi / num_sides),
                                  top_r * offsets[3][i % len(offsets[3])] * math.sin((i + 0.25) * 2 * math.pi / num_sides), height)) for i in range(num_sides)]
        bm.verts.ensure_lookup_table()
        bm.faces.new(reversed(bot_verts))
        for i in range(num_sides):
            nxt = (i + 1) % num_sides
            bm.faces.new([bot_verts[i], bot_verts[nxt], mid_verts[nxt], mid_verts[i]])
            bm.faces.new([mid_verts[i], mid_verts[nxt], upper_verts[nxt], upper_verts[i]])
            bm.faces.new([upper_verts[i], upper_verts[nxt], top_verts[nxt], top_verts[i]])
        bm.faces.new(top_verts)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return finalize_mesh(name, bm, [mat_rock], loc)

    create_rock_monolith("Rock_Monolith_Large", 2.6, 2.9, 2.0, 3.4, 8, offsets_large, (-9, -4))
    create_rock_monolith("Rock_Monolith_Medium", 1.8, 2.1, 1.4, 2.2, 7, offsets_med, (-3, -4))
    create_rock_monolith("Rock_Monolith_Spire", 1.3, 1.2, 0.9, 4.8, 6, offsets_spire, (3, -4))

    def create_intact_pillar(loc):
        bm = bmesh.new()
        sides = 8
        rings_def = [(0.0, 1.25), (0.5, 1.25), (0.8, 0.85), (1.9, 0.85), (2.0, 0.78), (2.15, 0.78), (2.25, 0.85), (3.8, 0.85), (5.2, 0.85), (5.5, 1.20), (6.0, 1.10)]
        ring_verts = []
        for z, r in rings_def:
            rv = []
            for i in range(sides):
                ang = i * 2 * math.pi / sides
                rv.append(bm.verts.new((r * math.cos(ang), r * math.sin(ang), z)))
            ring_verts.append(rv)
        bm.verts.ensure_lookup_table()
        f_bot = bm.faces.new(reversed(ring_verts[0]))
        f_bot.material_index = 0
        f_top = bm.faces.new(ring_verts[-1])
        f_top.material_index = 0
        for r_idx in range(len(rings_def) - 1):
            r1, r2 = ring_verts[r_idx], ring_verts[r_idx + 1]
            is_neon_band = (r_idx == 4)
            for i in range(sides):
                nxt = (i + 1) % sides
                face = bm.faces.new([r1[i], r1[nxt], r2[nxt], r2[i]])
                if is_neon_band:
                    face.material_index = 1
                elif r_idx in (2, 3, 6, 7) and (i % 2 == 1):
                    face.material_index = 1
                else:
                    face.material_index = 0
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return finalize_mesh("Ancient_Pillar_Intact", bm, [mat_rock, mat_cyan], loc)

    create_intact_pillar((-9, 4))

    def create_broken_pillar(loc):
        bm = bmesh.new()
        sides = 8
        rings_def = [(0.0, 1.25), (0.5, 1.25), (0.8, 0.85), (1.5, 0.85), (2.2, 0.85)]
        ring_verts = []
        for z, r in rings_def:
            rv = []
            for i in range(sides):
                ang = i * 2 * math.pi / sides
                rv.append(bm.verts.new((r * math.cos(ang), r * math.sin(ang), z)))
            ring_verts.append(rv)
        jagged_z = [2.4, 3.1, 3.5, 2.8, 2.3, 2.5, 2.9, 3.2]
        fracture_verts = []
        for i in range(sides):
            ang = i * 2 * math.pi / sides
            r = 0.80 * (0.85 + 0.3 * (i % 3 == 0))
            fracture_verts.append(bm.verts.new((r * math.cos(ang), r * math.sin(ang), jagged_z[i])))
        core_vert = bm.verts.new((0.1, 0.05, 3.3))
        bm.verts.ensure_lookup_table()
        f_bot = bm.faces.new(reversed(ring_verts[0]))
        f_bot.material_index = 0
        for r_idx in range(len(rings_def) - 1):
            r1, r2 = ring_verts[r_idx], ring_verts[r_idx + 1]
            for i in range(sides):
                nxt = (i + 1) % sides
                face = bm.faces.new([r1[i], r1[nxt], r2[nxt], r2[i]])
                if r_idx >= 2 and (i % 2 == 1):
                    face.material_index = 1
                else:
                    face.material_index = 0
        r_last = ring_verts[-1]
        for i in range(sides):
            nxt = (i + 1) % sides
            face = bm.faces.new([r_last[i], r_last[nxt], fracture_verts[nxt], fracture_verts[i]])
            face.material_index = 0
        for i in range(sides):
            nxt = (i + 1) % sides
            f_crack = bm.faces.new([fracture_verts[i], fracture_verts[nxt], core_vert])
            f_crack.material_index = 2 if i % 2 == 0 else 0
        chunk_verts = [bm.verts.new((1.1 + 0.4*x, 0.4 + 0.4*y, 0.2 + 0.3*z)) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
        bm.verts.ensure_lookup_table()
        cf = [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]
        for f_idx in cf:
            f = bm.faces.new([chunk_verts[i] for i in f_idx])
            f.material_index = 0
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return finalize_mesh("Ancient_Pillar_Broken", bm, [mat_rock, mat_cyan, mat_orange], loc)

    create_broken_pillar((-3, 4))

    def create_crystal_cluster(loc):
        bm = bmesh.new()
        sides, base_r = 8, 1.6
        mound_bot = [bm.verts.new((base_r * math.cos(i * 2 * math.pi / sides) * (0.9 + 0.2*(i%2)), base_r * math.sin(i * 2 * math.pi / sides) * (0.9 + 0.2*(i%2)), 0.0)) for i in range(sides)]
        mound_top = [bm.verts.new((base_r * 0.7 * math.cos((i + 0.5) * 2 * math.pi / sides), base_r * 0.7 * math.sin((i + 0.5) * 2 * math.pi / sides), 0.35)) for i in range(sides)]
        bm.verts.ensure_lookup_table()
        bm.faces.new(reversed(mound_bot)).material_index = 0
        for i in range(sides):
            nxt = (i + 1) % sides
            bm.faces.new([mound_bot[i], mound_bot[nxt], mound_top[nxt], mound_top[i]]).material_index = 0
        bm.faces.new(mound_top).material_index = 0
        c_specs = [
            (0.0, 0.0, 0.3, 0.32, 2.4, Euler((0.05, -0.05, 0.2))),
            (-0.5, 0.4, 0.25, 0.26, 1.8, Euler((0.3, 0.15, 0.8))),
            (0.55, 0.35, 0.25, 0.22, 1.5, Euler((-0.2, -0.35, -0.5))),
            (-0.45, -0.45, 0.2, 0.18, 1.3, Euler((-0.35, 0.1, 1.2))),
            (0.45, -0.4, 0.2, 0.16, 1.1, Euler((0.2, 0.4, -1.0)))
        ]
        for cx, cy, cz, cr, ch, crot in c_specs:
            c_sides = 6
            tf = Matrix.Translation(Vector((cx, cy, cz))) @ crot.to_matrix().to_4x4()
            c_bot, c_mid = [], []
            for i in range(c_sides):
                ang = i * 2 * math.pi / c_sides
                c_bot.append(bm.verts.new(tf @ Vector((cr * math.cos(ang), cr * math.sin(ang), 0.0))))
                c_mid.append(bm.verts.new(tf @ Vector((cr * 0.85 * math.cos(ang), cr * 0.85 * math.sin(ang), ch * 0.75))))
            tip_v = bm.verts.new(tf @ Vector((0.0, 0.0, ch)))
            bm.verts.ensure_lookup_table()
            for i in range(c_sides):
                nxt = (i + 1) % c_sides
                bm.faces.new([c_bot[i], c_bot[nxt], c_mid[nxt], c_mid[i]]).material_index = 1
                bm.faces.new([c_mid[i], c_mid[nxt], tip_v]).material_index = 1
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return finalize_mesh("Alien_Crystal_Cluster", bm, [mat_rock, mat_cyan, mat_emission], loc)

    create_crystal_cluster((3, 4))

    def create_mushroom_spore(loc):
        bm = bmesh.new()
        sides = 8
        stalk_levels = [(0.0, 0.55, 0.0, 0.0), (0.6, 0.42, 0.05, 0.02), (1.4, 0.35, 0.12, 0.05), (2.1, 0.32, 0.18, 0.06), (2.6, 0.45, 0.20, 0.06)]
        stalk_rings = []
        for z, r, ox, oy in stalk_levels:
            rv = []
            for i in range(sides):
                ang = i * 2 * math.pi / sides
                rv.append(bm.verts.new((ox + r * math.cos(ang), oy + r * math.sin(ang), z)))
            stalk_rings.append(rv)
        bm.verts.ensure_lookup_table()
        bm.faces.new(reversed(stalk_rings[0])).material_index = 0
        for r_idx in range(len(stalk_levels) - 1):
            r1, r2 = stalk_rings[r_idx], stalk_rings[r_idx + 1]
            for i in range(sides):
                nxt = (i + 1) % sides
                bm.faces.new([r1[i], r1[nxt], r2[nxt], r2[i]]).material_index = 0
        cap_sides, cap_ox, cap_oy, z_stalk_top = 10, 0.20, 0.06, 2.6
        und_inner = [bm.verts.new((cap_ox + 0.42 * math.cos(i * 2 * math.pi / cap_sides), cap_oy + 0.42 * math.sin(i * 2 * math.pi / cap_sides), z_stalk_top)) for i in range(cap_sides)]
        cap_rim = [bm.verts.new((cap_ox + 1.7 * (0.95 + 0.1 * math.sin(i * 2 * math.pi / cap_sides * 3)) * math.cos(i * 2 * math.pi / cap_sides), cap_oy + 1.7 * (0.95 + 0.1 * math.sin(i * 2 * math.pi / cap_sides * 3)) * math.sin(i * 2 * math.pi / cap_sides), 2.65 + 0.08 * math.cos(i * 2 * math.pi / cap_sides * 2))) for i in range(cap_sides)]
        cap_mid = [bm.verts.new((cap_ox + 1.2 * math.cos(i * 2 * math.pi / cap_sides), cap_oy + 1.2 * math.sin(i * 2 * math.pi / cap_sides), 3.15)) for i in range(cap_sides)]
        tip_v = bm.verts.new((cap_ox, cap_oy, 3.45))
        bm.verts.ensure_lookup_table()
        for i in range(cap_sides):
            nxt = (i + 1) % cap_sides
            bm.faces.new([und_inner[i], cap_rim[i], cap_rim[nxt], und_inner[nxt]]).material_index = 2
            bm.faces.new([cap_rim[i], cap_rim[nxt], cap_mid[nxt], cap_mid[i]]).material_index = 0
            bm.faces.new([cap_mid[i], cap_mid[nxt], tip_v]).material_index = 0
        b_ox, b_oy = -0.7, -0.5
        b_stalk_bot = [bm.verts.new((b_ox + 0.18 * math.cos(i * 2 * math.pi / 6), b_oy + 0.18 * math.sin(i * 2 * math.pi / 6), 0.0)) for i in range(6)]
        b_stalk_top = [bm.verts.new((b_ox - 0.05 + 0.12 * math.cos(i * 2 * math.pi / 6), b_oy - 0.05 + 0.12 * math.sin(i * 2 * math.pi / 6), 0.8)) for i in range(6)]
        bm.verts.ensure_lookup_table()
        bm.faces.new(reversed(b_stalk_bot)).material_index = 0
        for i in range(6):
            nxt = (i + 1) % 6
            bm.faces.new([b_stalk_bot[i], b_stalk_bot[nxt], b_stalk_top[nxt], b_stalk_top[i]]).material_index = 0
        b_rim = [bm.verts.new((b_ox - 0.05 + 0.55 * math.cos(i * 2 * math.pi / 6), b_oy - 0.05 + 0.55 * math.sin(i * 2 * math.pi / 6), 0.75)) for i in range(6)]
        b_tip = bm.verts.new((b_ox - 0.05, b_oy - 0.05, 1.05))
        bm.verts.ensure_lookup_table()
        for i in range(6):
            nxt = (i + 1) % 6
            bm.faces.new([b_stalk_top[i], b_rim[i], b_rim[nxt], b_stalk_top[nxt]]).material_index = 2
            bm.faces.new([b_rim[i], b_rim[nxt], b_tip]).material_index = 0
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return finalize_mesh("Alien_Mushroom_Spore", bm, [mat_rock, mat_cyan, mat_orange, mat_emission], loc)

    create_mushroom_spore((9, 4))

    def create_teleporter_platform(loc):
        bm = bmesh.new()
        oct_sides = 8
        r_bot = [bm.verts.new((4.2 * math.cos(i * 2 * math.pi / oct_sides), 4.2 * math.sin(i * 2 * math.pi / oct_sides), 0.0)) for i in range(oct_sides)]
        r_cham = [bm.verts.new((4.35 * math.cos(i * 2 * math.pi / oct_sides), 4.35 * math.sin(i * 2 * math.pi / oct_sides), 0.25)) for i in range(oct_sides)]
        r_top_outer = [bm.verts.new((4.0 * math.cos(i * 2 * math.pi / oct_sides), 4.0 * math.sin(i * 2 * math.pi / oct_sides), 0.50)) for i in range(oct_sides)]
        bm.verts.ensure_lookup_table()
        bm.faces.new(reversed(r_bot)).material_index = 0
        for i in range(oct_sides):
            nxt = (i + 1) % oct_sides
            bm.faces.new([r_bot[i], r_bot[nxt], r_cham[nxt], r_cham[i]]).material_index = 0
            bm.faces.new([r_cham[i], r_cham[nxt], r_top_outer[nxt], r_top_outer[i]]).material_index = 0
        circ_sides = 16
        r_outer_rim, r_groove_out, r_groove_in, r_inner_rim, z_deck, z_groove = 3.1, 3.0, 2.6, 2.5, 0.50, 0.40
        v_deck_outer = [bm.verts.new((r_outer_rim * math.cos(i * 2 * math.pi / circ_sides), r_outer_rim * math.sin(i * 2 * math.pi / circ_sides), z_deck)) for i in range(circ_sides)]
        v_grv_out = [bm.verts.new((r_groove_out * math.cos(i * 2 * math.pi / circ_sides), r_groove_out * math.sin(i * 2 * math.pi / circ_sides), z_groove)) for i in range(circ_sides)]
        v_grv_in = [bm.verts.new((r_groove_in * math.cos(i * 2 * math.pi / circ_sides), r_groove_in * math.sin(i * 2 * math.pi / circ_sides), z_groove)) for i in range(circ_sides)]
        v_deck_inner = [bm.verts.new((r_inner_rim * math.cos(i * 2 * math.pi / circ_sides), r_inner_rim * math.sin(i * 2 * math.pi / circ_sides), z_deck)) for i in range(circ_sides)]
        v_center = bm.verts.new((0.0, 0.0, 0.54))
        bm.verts.ensure_lookup_table()
        for i in range(oct_sides):
            o1, o2 = r_top_outer[i], r_top_outer[(i + 1) % oct_sides]
            c1, c2, c3 = v_deck_outer[2 * i], v_deck_outer[(2 * i + 1) % circ_sides], v_deck_outer[(2 * i + 2) % circ_sides]
            bm.faces.new([o1, o2, c3]).material_index = 0
            bm.faces.new([o1, c3, c2, c1]).material_index = 0
        for i in range(circ_sides):
            nxt = (i + 1) % circ_sides
            bm.faces.new([v_deck_outer[i], v_deck_outer[nxt], v_grv_out[nxt], v_grv_out[i]]).material_index = 1
            bm.faces.new([v_grv_out[i], v_grv_out[nxt], v_grv_in[nxt], v_grv_in[i]]).material_index = 1
            bm.faces.new([v_grv_in[i], v_grv_in[nxt], v_deck_inner[nxt], v_deck_inner[i]]).material_index = 1
            bm.faces.new([v_deck_inner[i], v_deck_inner[nxt], v_center]).material_index = 0
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return finalize_mesh("Teleporter_Platform", bm, [mat_rock, mat_cyan], loc)

    create_teleporter_platform((9, -4))

    # Export
    for obj in bpy.context.scene.objects:
        obj.select_set(obj.name in col.objects)
    bpy.ops.export_scene.gltf(
        filepath=export_path,
        export_format='GLB',
        use_selection=True,
        export_materials='EXPORT',
        export_apply=False
    )
    print("Export complete:", export_path)

if __name__ == "__main__":
    build_environment_pack()
