"""Bloco 72 — MAQUETE no Blender (estrutura, sem arte final): a mina como a referência, vista pela câmera
do jogo (ortográfica, 30° de cima). Cada andar é uma FAIXA de caverna: chão largo e raso na frente,
parede alta atrás, a rocha do andar de cima por cima; os andares descem UM EMBAIXO DO OUTRO (cada um um
pouco mais à frente, como a pedreira descendo), com o poço do elevador e a escada em espiral à direita.

  blender -b -P coluna_maquete.py -- <saida.png> [largura_px] [x_centro altura_centro largura_unid]

Unidade: 1 = 32 px da arte do jogo na horizontal. X = direita da tela, Y = pra dentro, Z = pra cima.
"""
import bpy, bmesh, math, random, sys
from mathutils import Vector, noise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SAIDA = argv[0] if argv else "//coluna_maquete.png"
LARG_PX = int(argv[1]) if len(argv) > 1 else 1400

POCO_X = 38.0                 # o poço do elevador
ESP_X, ESP_R = 51.0, 7.0      # a espiral (centro e raio)
FUNDO_Y = 44.0                # o fundo da rocha
XE, XD = -52.0, 62.0          # a largura da rocha
# nome, x0, x1 da sala, altura, profundidade do chão, recuo, cor da rocha, tipo
ANDARES = [
    ("galerias", -44, 34, 8.0, 12.0, 0.0, (0.30, 0.26, 0.22), None),
    ("S2", -46, 35, 17.0, 26.0, 13.0, (0.20, 0.25, 0.15), "acido"),
    ("S3", -40, 35, 18.0, 26.0, 13.0, (0.28, 0.13, 0.09), "lava"),
    ("S4", -47, 35, 17.0, 26.0, 13.0, (0.18, 0.17, 0.20), "cachoeira"),
    ("S5", -38, 35, 18.0, 26.0, 13.0, (0.14, 0.17, 0.22), "lago"),
]
LAJE = 3.5
rnd = random.Random(72)

bpy.ops.wm.read_factory_settings(use_empty=True)
cena = bpy.context.scene


# ---------------------------------------------------------------- materiais
def mat(nome, cor, emite=0.0, rugoso=0.9, ruido=0.0, escala=0.35):
    m = bpy.data.materials.new(nome)
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rugoso
    if ruido > 0:  # manchas na cor
        tx = nt.nodes.new("ShaderNodeTexNoise")
        tx.inputs["Scale"].default_value = escala
        tx.inputs["Detail"].default_value = 10.0
        rp = nt.nodes.new("ShaderNodeValToRGB")
        rp.color_ramp.elements[0].color = tuple(c * (1 - ruido) for c in cor) + (1,)
        rp.color_ramp.elements[1].color = tuple(min(1, c * (1 + ruido)) for c in cor) + (1,)
        nt.links.new(tx.outputs["Fac"], rp.inputs["Fac"])
        nt.links.new(rp.outputs["Color"], b.inputs["Base Color"])
    else:
        b.inputs["Base Color"].default_value = cor + (1,)
    if emite > 0:
        b.inputs["Emission Color"].default_value = cor + (1,)
        b.inputs["Emission Strength"].default_value = emite
    return m


M_ROCHA = mat("rocha", (0.20, 0.17, 0.15), ruido=0.5)
M_TERRA = mat("terra", (0.34, 0.25, 0.16), ruido=0.45)
M_GRAMA = mat("grama", (0.22, 0.38, 0.13), ruido=0.35, escala=1.0)
M_MADEIRA = mat("madeira", (0.34, 0.21, 0.10), ruido=0.25, escala=2.0)
M_LAVA = mat("lava", (1.0, 0.28, 0.02), emite=4.0)
M_ACIDO = mat("acido", (0.42, 0.85, 0.08), emite=1.6)
M_AGUA = mat("agua", (0.12, 0.40, 0.75), emite=0.5, rugoso=0.15)
M_LUZ = mat("lampiao", (1.0, 0.62, 0.22), emite=8.0)
M_CRISTAL = mat("cristal", (0.55, 0.22, 0.85), emite=2.5)
M_CRISTAL_V = mat("cristal_v", (0.25, 0.85, 0.35), emite=2.0)
M_TELHA = mat("telhado", (0.42, 0.17, 0.11), ruido=0.2)
M_PAREDE = mat("parede", (0.55, 0.47, 0.35), ruido=0.15)
M_FOLHA = mat("folha", (0.10, 0.26, 0.09), ruido=0.4, escala=1.5)
M_FOLHA2 = mat("folha2", (0.17, 0.33, 0.11), ruido=0.4, escala=1.5)


def objeto(nome, bm, m):
    me = bpy.data.meshes.new(nome)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nome, me)
    cena.collection.objects.link(ob)
    ob.data.materials.append(m)
    return ob


def caixa(nome, x0, y0, z0, x1, y1, z1, m, cortes=0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector(((v.co.x + 0.5) * (x1 - x0) + x0, (v.co.y + 0.5) * (y1 - y0) + y0, (v.co.z + 0.5) * (z1 - z0) + z0))
    if cortes:
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cortes, use_grid_fill=True)
    return objeto(nome, bm, m)


def prisma(nome, perfil, y0, y1, m, eixo="y"):
    """Um polígono (x, z) puxado de y0 até y1 (eixo y) — ou (x, y) puxado em z (eixo z)."""
    bm = bmesh.new()
    a = []
    b = []
    for (p, q) in perfil:
        if eixo == "y":
            a.append(bm.verts.new((p, y0, q)))
            b.append(bm.verts.new((p, y1, q)))
        elif eixo == "x":
            a.append(bm.verts.new((y0, p, q)))
            b.append(bm.verts.new((y1, p, q)))
        else:
            a.append(bm.verts.new((p, q, y0)))
            b.append(bm.verts.new((p, q, y1)))
    n = len(perfil)
    bm.faces.new(a[::-1])
    bm.faces.new(b)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return objeto(nome, bm, m)


def aplica(ob):
    bpy.context.view_layer.objects.active = ob
    for md in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=md.name)


def irregular(ob, forca, escala=6.0, semente=0, sub=0):
    if sub:
        md = ob.modifiers.new("r", "REMESH")
        md.mode = "VOXEL"
        md.voxel_size = sub
    tx = bpy.data.textures.new("ruido%d" % semente, "CLOUDS")
    tx.noise_scale = escala
    tx.noise_depth = 3
    tx.noise_basis = "BLENDER_ORIGINAL"
    md = ob.modifiers.new("d", "DISPLACE")
    md.texture = tx
    md.strength = forca
    md.mid_level = 0.5
    md.texture_coords = "GLOBAL"
    aplica(ob)


def menos(ob, cortador, apaga=True):
    md = ob.modifiers.new("b", "BOOLEAN")
    md.operation = "DIFFERENCE"
    md.object = cortador
    md.solver = "MANIFOLD" if hasattr(md, "solver") and "MANIFOLD" in [e.identifier for e in md.bl_rna.properties["solver"].enum_items] else "EXACT"
    aplica(ob)
    if apaga:
        bpy.data.objects.remove(cortador)


def cone(x, y, z, r, h, m, lados=8, vira=False):
    bpy.ops.mesh.primitive_cone_add(vertices=lados, radius1=r, depth=h, location=(x, y, z - h / 2 if vira else z + h / 2))
    o = bpy.context.object
    if vira:
        o.rotation_euler.x = math.pi
    o.data.materials.append(m)
    return o


def esfera(x, y, z, r, m, sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=(x, y, z))
    o = bpy.context.object
    o.data.materials.append(m)
    return o


def luz(x, y, z, energia, cor, raio=1.0):
    L = bpy.data.lights.new("l", "POINT")
    L.energy, L.color, L.shadow_soft_size = energia, cor, raio
    L.use_shadow = energia > 1000
    lo = bpy.data.objects.new("l", L)
    lo.location = (x, y, z)
    cena.collection.objects.link(lo)


def ondula(x, s, a=1.0, f=0.18):
    return a * (math.sin(x * f + s) * 0.6 + math.sin(x * f * 2.7 + s * 1.7) * 0.3 + math.sin(x * f * 6.1 + s * 0.3) * 0.15)


def perfil_caverna(x0, x1, chao, alt, s):
    """O corte de frente de uma sala de caverna: chão reto (andável), lados curvos, teto em arco irregular."""
    pts = []
    n = 60
    for i in range(n + 1):  # o teto, da esquerda pra direita
        t = i / n
        x = x0 + (x1 - x0) * t
        arco = math.sin(math.pi * t) ** 0.35
        z = chao + 1.5 + (alt - 1.5) * arco + ondula(x, s, 1.6)
        pts.append((x, z))
    pts.append((x1 - 0.5, chao - 0.6))
    pts.append((x0 + 0.5, chao - 0.6))
    return pts


# ---------------------------------------------------------------- a coluna, andar por andar
topo = 0.0
frente = 0.0
salas = []
for n, (nome, x0, x1, alt, prof, recuo, cor, tipo) in enumerate(ANDARES):
    frente -= recuo
    chao = topo - alt
    base = chao - LAJE
    m_r = mat("rocha_" + nome, cor, ruido=0.55)
    # a rocha deste andar: a frente ondulada (a beira da laje), os lados irregulares
    fr_pts = [(XE, FUNDO_Y)]
    for i in range(41):  # a rocha dos andares vai até o poço; à direita é a casca da espiral
        x = XE + (POCO_X + 4 - XE) * i / 40
        fr_pts.append((x, frente + ondula(x, n * 3.1, 1.2, 0.3) - 0.4))
    fr_pts.append((POCO_X + 4, FUNDO_Y))
    bloco = prisma("bloco_" + nome, [(p[0], p[1]) for p in fr_pts], base, topo, m_r, eixo="z")
    irregular(bloco, 2.2, 4.0, n, sub=0.9)
    sala = prisma("sala_" + nome, perfil_caverna(x0, x1, chao, alt + 1.5, n * 1.7), frente - 30, frente + prof, m_r)
    irregular(sala, 2.6, 5.0, 10 + n, sub=0.9)
    menos(bloco, sala)
    poco = caixa("poco_" + nome, POCO_X - 3.2, frente - 30, base - 2, POCO_X + 3.2, frente + 7, topo + 2, m_r)
    menos(bloco, poco)
    # o chão andável: plano, com a beira da frente ondulada
    cp = []
    for i in range(41):
        x = x0 + 1.2 + (x1 - x0 - 2.4) * i / 40
        cp.append((x, frente - 0.3 + ondula(x, n * 3.1, 1.2, 0.3)))
    cp += [(x1 - 2.0, frente + prof - 3), (x0 + 2.0, frente + prof - 3)]
    prisma("chao_" + nome, cp, chao - 1.5, chao, m_r, eixo="z")
    salas.append((nome, x0, x1, chao, frente, prof, alt, tipo))
    topo = base

# o fundo da mina (arredondado, como a referência), com o lago saindo
Z_BASE = topo
perfil = [(XE, Z_BASE)]
for i in range(41):
    x = XE + (XD - XE) * i / 40
    u = (x - (XE + XD) / 2) / ((XD - XE) / 2)
    perfil.append((x, Z_BASE - 18 * max(0.0, 1 - u * u) ** 0.8 - 1.0 + ondula(x, 5.0, 1.0)))
perfil.append((XD, Z_BASE))
fundo = prisma("fundo", perfil[::-1], frente - 0.5, FUNDO_Y, M_ROCHA)
irregular(fundo, 2.0, 4.0, 99, sub=0.9)
Z_FUNDO = Z_BASE - 19

# ---------------------------------------------------------------- a superfície (floresta | vila e pedreira)
sup = []
for i in range(41):
    x = XE + (XD - XE) * i / 40
    sup.append((x, ondula(x, 9.0, 1.0, 0.3)))
sup += [(XD, FUNDO_Y), (XE, FUNDO_Y)]
terra = prisma("sup", sup, -0.2, 1.4, M_TERRA, eixo="z")
irregular(terra, 0.8, 3.0, 50, sub=0.7)
grama = prisma("grama", [(XE, 0.5), (-4, 0.6), (-1, FUNDO_Y), (XE, FUNDO_Y)], 1.2, 1.7, M_GRAMA, eixo="z")
irregular(grama, 0.5, 2.0, 51, sub=0.6)
for _ in range(90):  # a floresta à esquerda
    x, y = rnd.uniform(XE + 1, -5), rnd.uniform(2, FUNDO_Y - 1)
    if rnd.random() < 0.6:
        h = rnd.uniform(5, 9)
        cone(x, y, 1.6, rnd.uniform(1.4, 2.0), h, M_FOLHA)
    else:
        caixa("tronco", x - 0.25, y - 0.25, 1.6, x + 0.25, y + 0.25, 4.5, M_MADEIRA)
        esfera(x, y, 5.5, rnd.uniform(1.8, 2.6), M_FOLHA2)
for x, y, w, d, h in [(2, 9, 6, 5, 4), (11, 4, 5, 5, 3.5), (21, 12, 6, 5, 4.5), (6, 20, 5, 6, 4), (16, 24, 6, 5, 3.5), (27, 5, 5, 4, 3)]:
    caixa("casa", x, y, 1.4, x + w, y + d, 1.4 + h, M_PAREDE)
    t = cone(x + w / 2, y + d / 2, 1.4 + h, max(w, d) * 0.75, 3.0, M_TELHA, lados=4)
    t.rotation_euler.z = math.pi / 4
# a pedreira: um buraco em degraus atrás da vila
for k in range(5):
    pts = [(30 + 1.6 * k + 2.5 * math.cos(a) * (1 - k * 0.1) * 4.5, 30 + 1.0 * k + 2.0 * math.sin(a) * (1 - k * 0.12) * 4.5)
           for a in [i * math.tau / 24 for i in range(24)]]
    prisma("degrau", pts, 1.4 - k * 1.6 - 0.2, 1.45 - k * 1.6, M_TERRA if k % 2 else M_ROCHA, eixo="z")
# o castelete (torre do elevador) em cima do poço
for dx in (-2.5, 2.5):
    for dy in (1.5, 6.5):
        caixa("castelete", POCO_X + dx - 0.3, dy - 0.3, 1.4, POCO_X + dx + 0.3, dy + 0.3, 15, M_MADEIRA)
for z in (5, 9, 13):
    caixa("x", POCO_X - 2.8, 1.2, z, POCO_X + 2.8, 1.8, z + 0.4, M_MADEIRA)
bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=2.2, depth=0.6, location=(POCO_X, 4, 16.5), rotation=(0, math.pi / 2, 0))
bpy.context.object.data.materials.append(M_MADEIRA)

# ---------------------------------------------------------------- o poço do elevador (torre de madeira até o fundo)
for nome, x0, x1, chao, fr, prof, alt, tipo in salas:
    for dx in (-2.3, 2.3):
        for dy in (fr + 1.0, fr + 5.0):
            caixa("poste", POCO_X + dx - 0.25, dy - 0.25, chao - LAJE, POCO_X + dx + 0.25, dy + 0.25, chao + alt + 2, M_MADEIRA)
    for z in range(int(chao), int(chao + alt), 3):
        caixa("trave", POCO_X - 2.5, fr + 0.8, z, POCO_X + 2.5, fr + 1.2, z + 0.3, M_MADEIRA)
    caixa("plataforma", POCO_X - 3, fr - 0.5, chao - 0.6, POCO_X + 3, fr + 6, chao, M_MADEIRA)
for nome, x0, x1, chao, fr, prof, alt, tipo in salas[1:3]:
    caixa("gaiola", POCO_X - 1.7, fr + 1.6, chao + 0.1, POCO_X + 1.7, fr + 4.4, chao + 3.4, M_MADEIRA)

# ---------------------------------------------------------------- a escada em espiral, num nicho aberto na rocha
cy0 = 8.0
cy1 = salas[-1][4] + 8.0
z0, z1 = 1.4, salas[-1][3]
N = 1400
# a rocha da direita (a casca da espiral), com o nicho aberto pra frente (inclinado junto com os andares)
casca = caixa("casca", POCO_X + 3.5, cy1 - 8.0, Z_FUNDO + 4, XD + 2, FUNDO_Y, 1.4, M_ROCHA)
irregular(casca, 2.0, 4.0, 77, sub=0.9)
# o nicho: um cilindro inclinado cortado da casca, e a frente aberta
bm = bmesh.new()
cima = [bm.verts.new((ESP_X + (ESP_R + 0.8) * math.cos(a), cy0 + (ESP_R + 0.8) * math.sin(a), z0 + 3)) for a in [k * math.tau / 32 for k in range(32)]]
baixo = [bm.verts.new((ESP_X + (ESP_R + 0.8) * math.cos(a), cy1 + (ESP_R + 0.8) * math.sin(a), z1 - 2)) for a in [k * math.tau / 32 for k in range(32)]]
bm.faces.new(cima)
bm.faces.new(baixo[::-1])
for k in range(32):
    j = (k + 1) % 32
    bm.faces.new((cima[k], cima[j], baixo[j], baixo[k]))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
nicho = objeto("nicho", bm, M_ROCHA)
menos(casca, nicho)
abre = prisma("abre", [(cy0 - 90, z0 + 4), (cy0, z0 + 4), (cy1, z1 - 3), (cy1 - 90, z1 - 3)], ESP_X - ESP_R - 2, ESP_X + ESP_R + 2, M_ROCHA, eixo="x")
menos(casca, abre)
# a rampa da espiral
bm = bmesh.new()
ver = []
for i in range(N + 1):
    t = i / N
    z = z0 + (z1 - z0) * t
    cy = cy0 + (cy1 - cy0) * t
    a = t * (len(salas) + 0.5) * math.tau
    ver.append([bm.verts.new((ESP_X + r * math.cos(a), cy + r * math.sin(a), z)) for r in (ESP_R - 2.8, ESP_R)])
for i in range(N):
    bm.faces.new((ver[i][0], ver[i][1], ver[i + 1][1], ver[i + 1][0]))
esp = objeto("espiral", bm, M_MADEIRA)
sd = esp.modifiers.new("s", "SOLIDIFY")
sd.thickness = 0.7
aplica(esp)
for k in range(0, N, 35):  # o corrimão
    t = k / N
    a = t * (len(salas) + 0.5) * math.tau
    x, y, z = ESP_X + ESP_R * math.cos(a), cy0 + (cy1 - cy0) * t + ESP_R * math.sin(a), z0 + (z1 - z0) * t
    caixa("corrimao", x - 0.15, y - 0.15, z, x + 0.15, y + 0.15, z + 1.6, M_MADEIRA)
bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=ESP_R - 3.0, depth=1, location=(0, 0, 0))
miolo = bpy.context.object
bm = bmesh.new()
cima = [bm.verts.new((ESP_X + 1.0 * math.cos(a), cy0 + 1.0 * math.sin(a), z0 + 2)) for a in [k * math.tau / 16 for k in range(16)]]
baixo = [bm.verts.new((ESP_X + 1.0 * math.cos(a), cy1 + 1.0 * math.sin(a), z1 - 2)) for a in [k * math.tau / 16 for k in range(16)]]
bm.faces.new(cima)
bm.faces.new(baixo[::-1])
for k in range(16):
    j = (k + 1) % 16
    bm.faces.new((cima[k], cima[j], baixo[j], baixo[k]))
bpy.data.objects.remove(miolo)
objeto("miolo", bm, M_MADEIRA)

# ---------------------------------------------------------------- o que tem em cada andar
for nome, x0, x1, chao, fr, prof, alt, tipo in salas:
    atras = fr + prof - 2.0
    for x in range(int(x0) + 5, int(x1) - 3, 10):  # escoras de mina (2 postes + viga) e lampiões
        xx = x + rnd.uniform(-1.5, 1.5)
        hh = min(alt - 2.5, 7.0)
        for dx in (-1.6, 1.6):
            caixa("escora", xx + dx - 0.3, atras - 1.2, chao, xx + dx + 0.3, atras - 0.6, chao + hh, M_MADEIRA)
        caixa("viga", xx - 2.2, atras - 1.3, chao + hh, xx + 2.2, atras - 0.5, chao + hh + 0.6, M_MADEIRA)
        esfera(xx, atras - 1.5, chao + hh - 1.0, 0.35, M_LUZ, 1)
        luz(xx, atras - 3, chao + hh - 1, 250, (1.0, 0.65, 0.3), 0.5)
    for _ in range(int((x1 - x0) / 3)):  # estalactites no teto
        x = rnd.uniform(x0 + 2, x1 - 2)
        t = (x - x0) / (x1 - x0)
        zt = chao + 1.5 + (alt) * math.sin(math.pi * t) ** 0.35 - 0.5
        cone(x, rnd.uniform(fr + 6, atras), zt, rnd.uniform(0.4, 0.9), rnd.uniform(1.5, 3.5), M_ROCHA, 6, vira=True)
    for _ in range(8):  # pedras no chão
        esfera(rnd.uniform(x0 + 3, x1 - 3), rnd.uniform(fr + prof - 6, fr + prof - 3), chao + 0.3, rnd.uniform(0.6, 1.4), M_ROCHA, 1)
    if tipo is None:  # as galerias: trilho e vagonetes
        caixa("trilho", x0 + 2, fr + 4, chao, x1 - 2, fr + 4.6, chao + 0.25, M_MADEIRA)
        for x in (x0 + 12, x0 + 40):
            caixa("vagonete", x, fr + 3.4, chao + 0.3, x + 3, fr + 5.6, chao + 2, M_MADEIRA)
    elif tipo == "acido":
        for _ in range(6):
            x, y = rnd.uniform(x0 + 4, x1 - 6), rnd.uniform(fr + 3, fr + prof - 7)
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=rnd.uniform(2.5, 5), depth=0.2, location=(x, y, chao + 0.05))
            bpy.context.object.scale.y = 0.6
            bpy.context.object.data.materials.append(M_ACIDO)
        for _ in range(12):
            cone(rnd.uniform(x0 + 3, x1 - 3), rnd.uniform(fr + prof - 7, fr + prof - 3), chao, 0.7, rnd.uniform(1.5, 3), rnd.choice([M_CRISTAL, M_CRISTAL_V]), 5)
        luz((x0 + x1) / 2, fr + 10, chao + 5, 8000, (0.5, 1.0, 0.3), 8)
    elif tipo == "lava":
        rio = []
        for i in range(41):
            x = x0 + 2 + (x1 - x0 - 5) * i / 40
            rio.append((x, fr + 10 + ondula(x, 1.0, 2.0, 0.2)))
        for i in range(40, -1, -1):
            x = x0 + 2 + (x1 - x0 - 5) * i / 40
            rio.append((x, fr + 13.5 + ondula(x, 1.0, 2.0, 0.2) + ondula(x, 4.0, 0.8, 0.5)))
        prisma("rio", rio, chao - 0.2, chao + 0.08, M_LAVA, eixo="z")
        for x in (x0 + 10, x0 + 33, x1 - 12):  # lava escorrendo da parede
            caixa("queda", x, atras - 0.6, chao, x + 1.4, atras + 0.2, chao + alt - 2, M_LAVA)
        for x in range(int(x0) + 6, int(x1), 14):
            luz(x, fr + 12, chao + 3, 6000, (1.0, 0.4, 0.1), 3)
    elif tipo == "cachoeira":
        caixa("queda_agua", -10, atras - 0.6, chao, -3, atras + 0.2, chao + alt, M_AGUA)
        bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=6, depth=0.2, location=(-6.5, atras - 5, chao + 0.05))
        bpy.context.object.scale.y = 0.7
        bpy.context.object.data.materials.append(M_AGUA)
        for _ in range(4):
            bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=rnd.uniform(2, 3.5), depth=0.2,
                                                location=(rnd.uniform(x0 + 4, -18), rnd.uniform(fr + 4, fr + prof - 7), chao + 0.05))
            bpy.context.object.scale.y = 0.6
            bpy.context.object.data.materials.append(M_LAVA)
        luz(-6.5, atras - 6, chao + 4, 4000, (0.3, 0.6, 1.0), 6)
        luz(x0 + 10, fr + 10, chao + 3, 4000, (1.0, 0.4, 0.1), 3)
    elif tipo == "lago":
        lago = []
        for i in range(40):
            a = i * math.tau / 40
            r = 1.0 + 0.12 * math.sin(3 * a + 1) + 0.06 * math.sin(7 * a)
            lago.append((x0 + 22 + 17 * r * math.cos(a), fr + prof * 0.45 + 10 * r * math.sin(a)))
        prisma("lago", lago, chao - 0.3, chao + 0.1, M_AGUA, eixo="z")
        for _ in range(14):
            cone(rnd.uniform(x0 + 3, x1 - 3), rnd.uniform(fr + prof - 6, fr + prof - 2), chao, 0.6, rnd.uniform(1.2, 2.6), M_CRISTAL, 5)
        luz(x0 + 22, fr + 12, chao + 5, 6000, (0.3, 0.6, 1.0), 8)

# ---------------------------------------------------------------- luz, câmera
sol = bpy.data.lights.new("sol", "SUN")
sol.energy = 2.6
sol.color = (1.0, 0.95, 0.85)
so = bpy.data.objects.new("sol", sol)
so.rotation_euler = (math.radians(40), math.radians(-30), math.radians(15))
cena.collection.objects.link(so)
luz2 = bpy.data.lights.new("frente", "SUN")  # luz de preenchimento vinda da câmera: a parede de trás aparece
luz2.energy = 1.2
luz2.color = (1.0, 0.85, 0.7)
lo2 = bpy.data.objects.new("frente", luz2)
lo2.rotation_euler = (math.radians(62), 0, math.radians(8))
cena.collection.objects.link(lo2)
mundo = bpy.data.worlds.new("w")
cena.world = mundo
mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.03, 0.03, 0.035, 1)

cam_d = bpy.data.cameras.new("cam")
cam_d.type = "ORTHO"
cam = bpy.data.objects.new("cam", cam_d)
cena.collection.objects.link(cam)
cena.camera = cam
cam.rotation_euler = (math.radians(60), 0, 0)   # 30° de cima, olhando pra +Y (a frente das faixas é horizontal)
xs = (XE - 3, XD + 3)
up_lo = 0.866 * (Z_FUNDO - 2) + 0.5 * salas[-1][4]
up_hi = 0.866 * 18 + 0.5 * FUNDO_Y
larg = xs[1] - xs[0]
alt_tela = up_hi - up_lo
fw = Vector((0, math.sin(math.radians(60)), -math.cos(math.radians(60))))
upv = Vector((0, math.cos(math.radians(60)), math.sin(math.radians(60))))
cam.location = Vector(((xs[0] + xs[1]) / 2, 0, 0)) + upv * ((up_lo + up_hi) / 2) - fw * 300
cam_d.clip_end = 1000
cena.render.resolution_x = LARG_PX
cena.render.resolution_y = int(LARG_PX * alt_tela / larg)
cam_d.sensor_fit = "HORIZONTAL"
cam_d.ortho_scale = larg
if len(argv) > 4:  # um recorte do tamanho da tela do jogo: <x do centro> <altura na tela do centro> <largura em unidades>
    cx, cu, esc = float(argv[2]), float(argv[3]), float(argv[4])
    cam.location = Vector((cx, 0, 0)) + upv * cu - fw * 300
    cam_d.ortho_scale = esc
    cena.render.resolution_x, cena.render.resolution_y = 1280, 720
cena.render.engine = "BLENDER_EEVEE"
cena.eevee.use_shadows = True
cena.view_settings.view_transform = "AgX"
cena.view_settings.look = "AgX - Punchy"
cena.render.filepath = SAIDA
bpy.ops.render.render(write_still=True)
print("ok", SAIDA, cena.render.resolution_x, cena.render.resolution_y)
