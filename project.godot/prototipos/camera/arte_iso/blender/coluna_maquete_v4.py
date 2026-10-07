"""MAQUETE v4 (2026-10-05, a partir do docs/NovoLayout/NewLayout.jpeg): a v3 aprovada (coluna_maquete.py) com o
que vale aproveitar do layout novo — a FERROVIA DE CARGA descendo do lado de fora da coluna (cavalete de madeira
em zigue-zague com vagonetes), as galerias como VILA DE MINERAÇÃO (cabanas, bocas, lampiões), o S2 como CAVERNA
DE CRISTAIS (mais cristal e poças d'água junto do ácido), o FÓSSIL gigante no S3 (lava), a FONTE TERMAL de vapor
no S4 e a CIDADE SUBTERRÂNEA no S5 (junto do lago).

Bloco 72 — MAQUETE no Blender (estrutura, sem arte final): a mina como a referência, vista pela câmera
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

POCO_X = 34.0                 # o poço do elevador
ESP_X, ESP_R = 52.0, 7.0      # a espiral (centro e raio)
FUNDO_Y = 44.0                # o fundo da rocha
XE, XD = -52.0, 68.0          # a largura da rocha
# nome, x0, x1 da sala, altura, profundidade do chão, recuo, cor da rocha, tipo
ANDARES = [
    ("galerias", -44, 30, 8.0, 12.0, 0.0, (0.30, 0.26, 0.22), None),
    ("S2", -46, 31, 17.0, 26.0, 13.0, (0.20, 0.25, 0.15), "acido"),
    ("S3", -40, 31, 18.0, 26.0, 13.0, (0.28, 0.13, 0.09), "lava"),
    ("S4", -47, 31, 17.0, 26.0, 13.0, (0.18, 0.17, 0.20), "cachoeira"),
    ("S5", -38, 31, 18.0, 26.0, 13.0, (0.14, 0.17, 0.22), "lago"),
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

# ---------------------------------------------------------------- a superfície: floresta | vila | mina
# Marco (2026-10-03): três áreas — a floresta, a vila (onde constrói, sem jazida no meio) e a MINA: uma
# montanha com a boca da mina, os minérios iniciais nela, um trilho com vagonete saindo da boca até o
# armazém, que fica logo na frente. O resto (os andares) continua igual.
VILA_X0 = -15.0               # a paliçada (floresta à esquerda)
BOCA_X = 52.0                 # a boca da mina (na montanha, atrás à direita)
M_ESTRADA = mat("estrada", (0.44, 0.35, 0.23), ruido=0.3, escala=1.2)
M_CARVAO = mat("carvao", (0.04, 0.04, 0.05), rugoso=0.3, ruido=0.4, escala=3.0)
M_COBRE = mat("cobre", (0.80, 0.40, 0.14), rugoso=0.35, ruido=0.25, escala=3.0)
M_TRILHO = mat("trilho", (0.40, 0.40, 0.44), rugoso=0.35)
M_ESCURO = mat("escuro", (0.0, 0.0, 0.0))
M_HORTA = mat("horta", (0.28, 0.46, 0.12), ruido=0.5, escala=2.5)
M_MONTANHA = mat("montanha", (0.36, 0.30, 0.24), ruido=0.5, escala=0.6)
M_PLACA = mat("placa", (0.80, 0.70, 0.45))
M_BANDEIRA = mat("bandeira", (0.70, 0.15, 0.10))


def vagonete(x, y, carga):
    caixa("vagonete", x - 1.1, y - 0.8, 1.9, x + 1.1, y + 0.8, 3.1, M_MADEIRA)
    for dx in (-0.7, 0.7):
        for dy in (-0.8, 0.8):
            bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.35, depth=0.2, location=(x + dx, y + dy, 1.85), rotation=(math.pi / 2, 0, 0))
            bpy.context.object.data.materials.append(M_TRILHO)
    for _ in range(9):
        esfera(x + rnd.uniform(-0.8, 0.8), y + rnd.uniform(-0.5, 0.5), 3.1 + rnd.uniform(0, 0.4), rnd.uniform(0.3, 0.5), carga, 1)


def telhado(x0, y0, x1, y1, z, h, m):
    """Telhado de duas águas (cumeeira ao longo de x)."""
    ym = (y0 + y1) / 2
    prisma("telhado", [(y0 - 0.5, z), (y1 + 0.5, z), (ym, z + h)], x0 - 0.5, x1 + 0.5, m, eixo="x")


def casa(x, y, w, d, h, m_parede=None):
    caixa("casa", x, y, 1.4, x + w, y + d, 1.4 + h, m_parede or M_PAREDE)
    telhado(x, y, x + w, y + d, 1.4 + h, 2.4, M_TELHA)
    caixa("porta", x + w / 2 - 0.5, y - 0.05, 1.4, x + w / 2 + 0.5, y + 0.1, 3.2, M_MADEIRA)


sup = []
for i in range(41):
    x = XE + (XD - XE) * i / 40
    sup.append((x, ondula(x, 9.0, 1.0, 0.3)))
sup += [(XD, FUNDO_Y), (XE, FUNDO_Y)]
terra = prisma("sup", sup, -0.2, 1.4, M_TERRA, eixo="z")
irregular(terra, 0.8, 3.0, 50, sub=0.7)
grama = prisma("grama", [(XE, 0.5), (VILA_X0 - 1.0, 0.6), (VILA_X0 - 1.0, FUNDO_Y), (XE, FUNDO_Y)], 1.2, 1.7, M_GRAMA, eixo="z")
irregular(grama, 0.5, 2.0, 51, sub=0.6)
for _ in range(110):  # a floresta
    x, y = rnd.uniform(XE + 1, VILA_X0 - 2.5), rnd.uniform(2, FUNDO_Y - 1)
    if rnd.random() < 0.55:
        cone(x, y, 1.6, rnd.uniform(1.3, 2.0), rnd.uniform(5, 9), M_FOLHA)
    else:
        caixa("tronco", x - 0.25, y - 0.25, 1.6, x + 0.25, y + 0.25, 4.5, M_MADEIRA)
        esfera(x, y, 5.5, rnd.uniform(1.8, 2.6), M_FOLHA2)
# a paliçada, com o portão
y = 1.0
while y < FUNDO_Y - 1:
    if not 14.0 < y < 19.0:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.35, depth=3.0, location=(VILA_X0, y, 2.9))
        bpy.context.object.data.materials.append(M_MADEIRA)
        cone(VILA_X0, y, 4.4, 0.35, 0.8, M_MADEIRA, 8)
    y += 0.75
# a estrada: do portão, cruzando a vila, até o armazém
prisma("estrada", [(VILA_X0, 14.5), (BOCA_X - 1, 14.5), (BOCA_X - 1, 18.5), (VILA_X0, 18.5)], 1.38, 1.47, M_ESTRADA, eixo="z")
prisma("estrada2", [(1.0, 0.8), (4.0, 0.8), (4.0, 14.5), (1.0, 14.5)], 1.38, 1.47, M_ESTRADA, eixo="z")
# a vila: Centro da Vila, igreja, casas, poço, horta — e lotes LIVRES marcados (espaço pra construir)
caixa("centro", -3, 20, 1.4, 7, 27, 6.6, M_PAREDE)
telhado(-3, 20, 7, 27, 6.6, 3.0, M_TELHA)
caixa("porta", 1.3, 19.9, 1.4, 2.7, 20.1, 4.0, M_MADEIRA)
bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.12, depth=6, location=(8, 21, 4.4))
bpy.context.object.data.materials.append(M_MADEIRA)
caixa("bandeira", 8, 20.9, 6.0, 10, 21.0, 7.2, M_BANDEIRA)
caixa("igreja", 21, 30, 1.4, 27, 39, 6.4, M_PAREDE)
telhado(21, 30, 27, 39, 6.4, 3.0, M_TELHA)
caixa("torre", 22.5, 27.5, 1.4, 25.5, 30.5, 11.0, M_PAREDE)
cone(24, 29, 11.0, 2.3, 4.0, M_TELHA, 4).rotation_euler.z = math.pi / 4
for x, y, w, d in [(-12, 3, 4.5, 4), (-12, 33, 4.5, 4), (-6, 37, 4.5, 4), (12, 3, 4.5, 4), (20, 3, 4.5, 4), (-12, 24, 4.5, 4)]:
    casa(x, y, w, d, 3.6)
bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.9, depth=1.0, location=(9, 11, 1.9))  # o poço
bpy.context.object.data.materials.append(M_ROCHA)
for i in range(5):  # a horta
    caixa("horta", -12, 9 + i * 0.9, 1.4, -4, 9.5 + i * 0.9, 1.75, M_HORTA)
for x0, y0, w, d in [(10, 21, 7, 5), (11, 31, 7, 5), (-6, 29, 5, 5), (13, 8, 6, 4)]:  # lotes livres (estacas e corda)
    for (px, py) in [(x0, y0), (x0 + w, y0), (x0, y0 + d), (x0 + w, y0 + d)]:
        caixa("estaca", px - 0.12, py - 0.12, 1.4, px + 0.12, py + 0.12, 2.4, M_MADEIRA)
    for a, b in [((x0, y0), (x0 + w, y0)), ((x0, y0 + d), (x0 + w, y0 + d))]:
        caixa("corda", a[0], a[1] - 0.04, 2.2, b[0], a[1] + 0.04, 2.28, M_PLACA)
    for a in [(x0, y0), (x0 + w, y0)]:
        caixa("corda", a[0] - 0.04, a[1], 2.2, a[0] + 0.04, a[1] + d, 2.28, M_PLACA)

# o castelete (torre do elevador) em cima do poço
for dx in (-2.5, 2.5):
    for dy in (1.5, 6.5):
        caixa("castelete", POCO_X + dx - 0.3, dy - 0.3, 1.4, POCO_X + dx + 0.3, dy + 0.3, 15, M_MADEIRA)
for z in (5, 9, 13):
    caixa("x", POCO_X - 2.8, 1.2, z, POCO_X + 2.8, 1.8, z + 0.4, M_MADEIRA)
bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=2.2, depth=0.6, location=(POCO_X, 4, 16.5), rotation=(0, math.pi / 2, 0))
bpy.context.object.data.materials.append(M_MADEIRA)

# ---- a MINA: um paredão de pedra em degraus (como a referência), com a boca principal embaixo, mais duas
# aberturas nos degraus de cima, escadas de madeira, andaime, guindaste, casinha de pedra; os minérios
# iniciais (carvão e cobre) nos veios do paredão; o trilho com vagonete até o armazém na frente.
def degrau_rocha(nome, x0, x1, y_frente, topo, semente):
    pts = []
    for i in range(33):  # a frente (ondulada), da esquerda pra direita
        x = x0 + (x1 - x0) * i / 32
        pts.append((x, y_frente + ondula(x, semente, 2.2, 0.35)))
    pts += [(x1 + 1.0, FUNDO_Y), (x0 - 1.0, FUNDO_Y)]
    ob = prisma(nome, pts, -1.0, topo, M_MONTANHA, eixo="z")
    irregular(ob, 1.6, 2.2, semente, sub=0.6)
    return ob


DEGRAUS = [degrau_rocha("degrau1", 39.0, 68.0, 22.0, 8.0, 61), degrau_rocha("degrau2", 42.0, 67.5, 29.0, 14.0, 62),
           degrau_rocha("degrau3", 46.0, 66.0, 36.0, 20.0, 63)]
bpy.context.view_layer.update()


def bate(origem, direcao):
    melhor = (None, None)
    dist = 1e9
    for ob in DEGRAUS:
        ok, p, nrm, _ = ob.ray_cast(Vector(origem), Vector(direcao))
        if ok and (p - Vector(origem)).length < dist:
            dist = (p - Vector(origem)).length
            melhor = (p, nrm)
    return melhor


def abertura(x, z0, larg, alt, y_face, fundo=12.0):
    """Corta uma boca em arco em todos os degraus e põe a moldura de madeira e os lampiões."""
    arco = [(x - larg / 2, z0 - 0.1), (x + larg / 2, z0 - 0.1)]
    for i in range(13):
        a = i * math.pi / 12
        arco.append((x + larg / 2 * math.cos(a), z0 + alt - larg / 2 * 0.85 + larg / 2 * 0.85 * math.sin(a)))
    for ob in DEGRAUS:
        menos(ob, prisma("corte", arco, y_face - 4, y_face + fundo, M_MONTANHA))
    caixa("fundo_boca", x - larg / 2 - 0.3, y_face + fundo - 3, z0 - 0.1, x + larg / 2 + 0.3, y_face + fundo - 2.5, z0 + alt + 0.5, M_ESCURO)
    for dx in (-larg / 2 - 0.3, larg / 2 + 0.3):
        caixa("moldura", x + dx - 0.3, y_face - 0.6, z0, x + dx + 0.3, y_face + 0.2, z0 + alt, M_MADEIRA)
    caixa("viga", x - larg / 2 - 0.9, y_face - 0.7, z0 + alt - 0.2, x + larg / 2 + 0.9, y_face + 0.3, z0 + alt + 0.6, M_MADEIRA)
    for dx in (-larg / 2 - 0.8, larg / 2 + 0.8):
        esfera(x + dx, y_face - 0.9, z0 + alt - 1.0, 0.28, M_LUZ, 1)
    luz(x, y_face - 2.0, z0 + alt - 1.0, 250, (1.0, 0.65, 0.3), 0.4)


def escada(xa, ya, za, xb, yb, zb, larg=1.4):
    """Escada de madeira reta de (a) até (b), com degraus e corrimão."""
    n = max(4, int(abs(zb - za) / 0.55))
    for i in range(n):
        t = i / n
        x, y, z = xa + (xb - xa) * t, ya + (yb - ya) * t, za + (zb - za) * t
        caixa("degrau_esc", x - larg / 2, y - 0.35, z - 0.12, x + larg / 2, y + 0.35, z + 0.12, M_MADEIRA)
        if i % 3 == 0:
            caixa("corrimao", x + larg / 2 - 0.1, y - 0.1, z, x + larg / 2 + 0.1, y + 0.1, z + 1.3, M_MADEIRA)
    for i in range(0, n, 2):  # os pés da escada
        t = i / n
        x, y, z = xa + (xb - xa) * t, ya + (yb - ya) * t, za + (zb - za) * t
        caixa("pe", x - 0.12, y - 0.12, min(za, zb), x + 0.12, y + 0.12, z, M_MADEIRA)


# a boca principal, no pé do paredão
yf = bate((BOCA_X, -10, 3.5), (0, 1, 0))[0].y
abertura(BOCA_X, 1.4, 5.2, 6.0, yf, 16.0)
caixa("chao_tunel", BOCA_X - 2.6, yf - 1, 1.3, BOCA_X + 2.6, yf + 12, 1.45, M_TERRA)
caixa("placa", BOCA_X - 1.6, yf - 0.8, 7.7, BOCA_X + 1.6, yf - 0.6, 8.8, M_PLACA)
# a segunda abertura, no degrau do meio (à direita), com plataforma, trilho curto e um vagonete
x2 = 61.5
y2 = bate((x2, -10, 11.5), (0, 1, 0))[0].y
z2 = bate((x2, y2 - 1.8, 40), (0, 0, -1))[0].z
abertura(x2, z2, 3.4, 4.2, y2)
caixa("plataforma2", x2 - 3.2, y2 - 3.2, z2 - 0.4, x2 + 3.2, y2 - 0.2, z2, M_MADEIRA)
for dx in (-3.0, 3.0):
    caixa("pe_plat", x2 + dx - 0.2, y2 - 3.1, 1.4, x2 + dx + 0.2, y2 - 2.7, z2, M_MADEIRA)
vagonete(x2 - 1.0, y2 - 1.7, M_COBRE)
# a terceira, pequena, lá em cima (à esquerda)
x3 = 50.0
y3 = bate((x3, -10, 17.0), (0, 1, 0))[0].y
z3 = bate((x3, y3 - 1.5, 60), (0, 0, -1))[0].z
abertura(x3, z3, 2.6, 3.4, y3)
# escadas de madeira subindo o paredão
p1 = bate((44.0, -10, 4.0), (0, 1, 0))[0]
t1 = bate((47.5, p1.y + 2.5, 40), (0, 0, -1))[0]
escada(42.5, p1.y - 1.2, 1.4, 47.5, p1.y - 1.2, t1.z)
p2 = bate((64.0, -10, 11.0), (0, 1, 0))[0]
t2 = bate((66.0, p2.y + 2.5, 40), (0, 0, -1))[0]
escada(60.0, p2.y - 1.6, z2, 65.5, p2.y - 1.6, t2.z)
# andaime encostado no degrau do meio (à esquerda)
pa = bate((45.5, -10, 11.0), (0, 1, 0))[0]
for x in (43.5, 45.5, 47.5):
    caixa("andaime_poste", x - 0.12, pa.y - 1.6, 7.5, x + 0.12, pa.y - 1.4, 14.5, M_MADEIRA)
for z in (9.5, 12.0, 14.3):
    caixa("andaime_tabua", 43.2, pa.y - 1.9, z, 47.8, pa.y - 0.9, z + 0.18, M_MADEIRA)
    caixa("andaime_trave", 43.2, pa.y - 1.6, z + 1.0, 47.8, pa.y - 1.5, z + 1.12, M_MADEIRA)
# o guindaste no degrau do meio
gx, gy = 55.5, 31.5
gz = bate((gx, gy, 60), (0, 0, -1))[0].z
caixa("mastro", gx - 0.25, gy - 0.25, gz, gx + 0.25, gy + 0.25, gz + 8.0, M_MADEIRA)
bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.18, depth=8.5, location=(gx - 3.0, gy - 1.2, gz + 6.2), rotation=(0.15, -1.05, 0))
bpy.context.object.data.materials.append(M_MADEIRA)
caixa("corda", gx - 6.6, gy - 1.6, gz - 1.5, gx - 6.5, gy - 1.5, gz + 4.2, M_PLACA)
caixa("balde", gx - 7.2, gy - 2.2, gz - 2.4, gx - 5.9, gy - 0.9, gz - 1.4, M_MADEIRA)
for dx, dy in [(-1.0, -1.0), (1.0, -1.0), (0, 1.2)]:
    caixa("escora_g", gx + dx - 0.15, gy + dy - 0.15, gz, gx + dx + 0.15, gy + dy + 0.15, gz + 1.6, M_MADEIRA)
# casinha de pedra no degrau de baixo (à direita)
hx, hy = 65.0, yf + 1.5
hz = bate((hx, hy + 2.0, 60), (0, 0, -1))[0].z
caixa("casinha", hx - 2.0, hy, hz, hx + 2.0, hy + 3.2, hz + 3.0, M_PAREDE)
telhado(hx - 2.0, hy, hx + 2.0, hy + 3.2, hz + 3.0, 1.6, M_TELHA)
caixa("porta_c", hx - 0.5, hy - 0.05, hz, hx + 0.5, hy + 0.1, hz + 1.8, M_MADEIRA)
# os minérios iniciais: carvão à esquerda da boca, cobre à direita e em volta da segunda abertura
for m, (xa, xb), (za, zb), n in [(M_CARVAO, (BOCA_X - 11, BOCA_X - 4), (2.5, 7), 8), (M_COBRE, (BOCA_X + 4, BOCA_X + 10), (2.5, 7), 6),
                                  (M_COBRE, (x2 - 5, x2 + 4), (z2 + 1, z2 + 4), 4)]:
    for _ in range(n):
        p, nrm = bate((rnd.uniform(xa, xb), -10, rnd.uniform(za, zb)), (0, 1, 0))
        if p is None:
            continue
        for _ in range(4):
            q = p + Vector((rnd.uniform(-0.7, 0.7), rnd.uniform(-0.3, 0.2), rnd.uniform(-0.6, 0.6)))
            o = cone(q.x, q.y, q.z - 0.4, rnd.uniform(0.35, 0.6), rnd.uniform(0.9, 1.6), m, 5)
            o.rotation_euler = (rnd.uniform(-1.2, -0.4), rnd.uniform(-0.4, 0.4), 0)
for _ in range(9):  # pinheiros nos degraus de cima
    x = rnd.uniform(47, 66)
    p, _ = bate((x, rnd.uniform(37, 43), 60), (0, 0, -1))
    if p is not None:
        cone(p.x, p.y, p.z - 0.3, 1.1, rnd.uniform(3.5, 5.5), M_FOLHA)
for _ in range(14):  # pedras soltas e entulho no pé do paredão
    esfera(rnd.uniform(BOCA_X - 13, BOCA_X + 14), rnd.uniform(yf - 5, yf - 0.5), 1.5, rnd.uniform(0.4, 1.0), M_MONTANHA, 1)
for k in range(4):  # madeira empilhada
    caixa("tora", 41.0, yf - 4.0 + k * 0.05, 1.4 + k * 0.45, 45.0, yf - 3.0, 1.85 + k * 0.45, M_MADEIRA)
# o trilho: de dentro da mina até a plataforma do armazém
Y_DOCA = 4.0
y = Y_DOCA
while y < yf + 8:
    caixa("dormente", BOCA_X - 1.3, y - 0.2, 1.4, BOCA_X + 1.3, y + 0.2, 1.52, M_MADEIRA)
    y += 0.9
for dx in (-0.7, 0.7):
    caixa("trilho", BOCA_X + dx - 0.1, Y_DOCA, 1.52, BOCA_X + dx + 0.1, yf + 8, 1.75, M_TRILHO)
vagonete(BOCA_X, yf - 3.0, M_CARVAO)   # saindo da mina, cheio de carvão
vagonete(BOCA_X, Y_DOCA + 1.5, M_COBRE)  # na plataforma do armazém
# o armazém, logo na frente da boca, com a plataforma do lado do trilho
AX0, AX1 = BOCA_X - 12.5, BOCA_X - 2.2
caixa("armazem", AX0, 2.0, 1.4, AX1, 11.0, 5.6, M_MADEIRA)
telhado(AX0, 2.0, AX1, 11.0, 5.6, 2.6, M_TELHA)
caixa("portao", AX0 + 3, 1.9, 1.4, AX0 + 7, 2.05, 4.6, M_ESCURO)
caixa("doca", AX1, 2.4, 1.4, AX1 + 1.2, 10.0, 2.2, M_MADEIRA)
for m, x in [(M_CARVAO, AX0 + 1.0), (M_COBRE, AX0 + 9.0)]:  # montes de minério na frente (Marco: só carvão e cobre)
    for _ in range(10):
        esfera(x + rnd.uniform(-0.9, 0.9), 0.9 + rnd.uniform(-0.5, 0.5), 1.6 + rnd.uniform(0, 0.5), rnd.uniform(0.3, 0.55), m, 1)
for x in (AX0 + 0.5, AX1 - 0.5):  # caixotes
    caixa("caixote", x - 0.5, 0.2, 1.4, x + 0.5, 1.2, 2.4, M_MADEIRA)
# a boca da escada em espiral (que desce pelos andares), do lado da mina
caixa("escada_boca", ESP_X + ESP_R - 1.5, 1.0, 1.4, ESP_X + ESP_R + 2.5, 5.0, 1.5, M_ESCURO)
for (px, py) in [(ESP_X + ESP_R - 1.5, 1.0), (ESP_X + ESP_R + 2.5, 1.0), (ESP_X + ESP_R - 1.5, 5.0), (ESP_X + ESP_R + 2.5, 5.0)]:
    caixa("poste_escada", px - 0.2, py - 0.2, 1.4, px + 0.2, py + 0.2, 4.6, M_MADEIRA)
telhado(ESP_X + ESP_R - 1.9, 0.6, ESP_X + ESP_R + 2.9, 5.4, 4.6, 1.4, M_MADEIRA)

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
cima = [bm.verts.new((ESP_X + 1.0 * math.cos(a), cy0 + 1.0 * math.sin(a), z0 - 0.5)) for a in [k * math.tau / 16 for k in range(16)]]
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


# ================================================================ v4: o que vem do NewLayout
M_OSSO = mat("osso", (0.86, 0.80, 0.66), ruido=0.15, escala=3.0)
M_VAPOR = mat("vapor", (0.85, 0.88, 0.92), emite=1.2, rugoso=0.3)
M_PEDRA = mat("pedra_cidade", (0.36, 0.36, 0.40), ruido=0.3, escala=2.0)
M_CRISTAL_C = mat("cristal_c", (0.25, 0.85, 0.95), emite=3.0)
M_FERRO = mat("ferro_cano", (0.30, 0.28, 0.27), rugoso=0.5)
M_ESCURO = mat("boca_escura", (0.02, 0.02, 0.02))
por_nome = {s_[0]: s_ for s_ in salas}


def entre(nome, p0, p1, larg, esp, m):
    """uma viga/rampa (caixa) de p0 a p1 (3D), larg no eixo y, esp de espessura."""
    p0, p1 = Vector(p0), Vector(p1)
    bm = bmesh.new()
    lado = Vector((0, larg / 2, 0))
    cima = Vector((0, 0, esp))
    vs = [bm.verts.new(v) for v in (p0 - lado, p1 - lado, p1 + lado, p0 + lado,
                                     p0 - lado + cima, p1 - lado + cima, p1 + lado + cima, p0 + lado + cima)]
    for f in ((0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
        bm.faces.new([vs[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return objeto(nome, bm, m)


# ---- a FERROVIA DE CARGA: cavalete de madeira à direita da coluna, rampas em zigue-zague da superfície até o S5
FX0, FX1 = XD + 2.6, XD + 13.0
pontos = [(FX0, 4.0, 1.4)]
for k, (nome, x0, x1, chao, fr, prof, alt, tipo) in enumerate(salas):
    y = max(fr + 3.0, 2.0)
    z_meio = (pontos[-1][2] + chao) / 2
    pontos.append((FX1 if k % 2 == 0 else FX0, y, z_meio))
    pontos.append((FX0 if k % 2 == 0 else FX1, y, chao))
for a, b in zip(pontos, pontos[1:]):
    entre("rampa", a, b, 2.6, 0.5, M_MADEIRA)
    for lado in (-0.8, 0.8):  # os trilhos
        entre("trilho_carga", (a[0], a[1] + lado, a[2] + 0.5), (b[0], b[1] + lado, b[2] + 0.5), 0.2, 0.18, M_TRILHO)
    for t in (0.0, 0.5):  # postes do cavalete
        p = Vector(a).lerp(Vector(b), t)
        caixa("poste_cav", p.x - 0.25, p.y + 1.0, Z_FUNDO, p.x + 0.25, p.y + 1.5, p.z, M_MADEIRA)
for k, (a, b) in enumerate(zip(pontos, pontos[1:])):
    if k % 2 == 1:  # um vagonete com minério a cada lance
        p = Vector(a).lerp(Vector(b), 0.45)
        caixa("vag_carga", p.x - 1.0, p.y - 0.8, p.z + 0.6, p.x + 1.0, p.y + 0.8, p.z + 1.8, M_FERRO)
        for _ in range(5):
            esfera(p.x + rnd.uniform(-0.6, 0.6), p.y + rnd.uniform(-0.4, 0.4), p.z + 1.9, 0.35, rnd.choice([M_ROCHA, M_LAVA, M_CRISTAL]), 1)
caixa("estacao_carga", FX0 - 3.0, 1.0, 1.4, FX1 + 1.5, 9.0, 1.9, M_MADEIRA)  # a plataforma lá em cima
for k, (nome, x0, x1, chao, fr, prof, alt, tipo) in enumerate(salas):  # cada andar: a boca do túnel até a linha
    y = max(fr + 3.0, 2.0)
    caixa("boca_carga", XD + 0.6, y - 2.0, chao, XD + 2.8, y + 2.0, chao + 4.0, M_ESCURO)
    caixa("batente_carga", XD + 0.4, y - 2.4, chao + 4.0, XD + 3.0, y + 2.4, chao + 4.6, M_MADEIRA)
    caixa("doca", XD + 0.4, y - 2.0, chao - 0.5, FX0 + 1.5, y + 2.0, chao, M_MADEIRA)
luz((FX0 + FX1) / 2, 0.0, 4.0, 1500, (1.0, 0.65, 0.3), 1.0)

# ---- GALERIAS = VILA DE MINERAÇÃO: cabanas encostadas na parede, bocas de túnel, lampiões
nome, x0, x1, chao, fr, prof, alt, tipo = por_nome["galerias"]
atras = fr + prof - 2.5
for x in (x0 + 6, x0 + 24, x0 + 46):
    caixa("cabana", x, atras - 4.5, chao, x + 5, atras - 0.5, chao + 3.2, M_MADEIRA)
    telhado(x - 0.3, atras - 4.8, x + 5.3, atras - 0.2, chao + 3.2, 1.6, M_TELHA)
    caixa("porta_cab", x + 2.0, atras - 4.6, chao, x + 3.0, atras - 4.4, chao + 2.0, M_ESCURO)
    esfera(x + 4.0, atras - 4.8, chao + 2.6, 0.3, M_LUZ, 1)
    luz(x + 4.0, atras - 6, chao + 2.6, 300, (1.0, 0.6, 0.25), 0.4)
for x in (x0 + 15, x0 + 36, x1 - 6):  # bocas de túnel na parede (escuras, com batente)
    caixa("boca_tunel", x, atras - 0.3, chao, x + 3, atras + 0.5, chao + 3.5, M_ESCURO)
    caixa("batente", x - 0.4, atras - 0.6, chao + 3.5, x + 3.4, atras - 0.2, chao + 4.1, M_MADEIRA)

# ---- S2 = CAVERNA DE CRISTAIS: aglomerados grandes de cristal e poças d'água entre o ácido
nome, x0, x1, chao, fr, prof, alt, tipo = por_nome["S2"]
for _ in range(9):
    cx, cy = rnd.uniform(x0 + 3, x1 - 4), rnd.uniform(fr + prof - 9, fr + prof - 3)
    for _ in range(4):
        cone(cx + rnd.uniform(-1.2, 1.2), cy + rnd.uniform(-0.8, 0.8), chao, rnd.uniform(0.5, 1.0), rnd.uniform(2.0, 4.5),
             rnd.choice([M_CRISTAL, M_CRISTAL_C, M_CRISTAL_V]), 5)
for _ in range(3):
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=rnd.uniform(2.5, 4), depth=0.2,
                                        location=(rnd.uniform(x0 + 6, x1 - 8), rnd.uniform(fr + 5, fr + prof - 9), chao + 0.06))
    bpy.context.object.scale.y = 0.6
    bpy.context.object.data.materials.append(M_AGUA)
luz((x0 + x1) / 2, fr + prof - 8, chao + 4, 3000, (0.6, 0.4, 1.0), 6)

# ---- S3 = CÂMARA DO FÓSSIL: um esqueleto gigante deitado ao pé da parede, com a lava em volta
nome, x0, x1, chao, fr, prof, alt, tipo = por_nome["S3"]
fx, fy = x0 + 22.0, fr + prof - 8.0
E = 1.6  # escala do esqueleto
for i in range(22):  # a coluna (vértebras) arqueada
    t = i / 21
    x = fx + E * (-9 + 18 * t)
    z = chao + E * (1.2 + 3.2 * math.sin(math.pi * min(1.0, t * 1.15)))
    esfera(x, fy, z, E * (0.55 - 0.25 * abs(t - 0.4)), M_OSSO, 1)
    if 0.15 < t < 0.65 and i % 2 == 0:  # costelas
        for lado in (-1, 1):
            entre("costela", (x, fy, z), (x + 0.6 * E, fy + lado * 2.2 * E, chao + 0.3), 0.35, 0.35, M_OSSO)
esfera(fx - 10.5 * E, fy, chao + 1.6 * E, 1.2 * E, M_OSSO, 2)  # o crânio
entre("mandibula", (fx - 11.8 * E, fy, chao + 0.9 * E), (fx - 9.6 * E, fy, chao + 0.4), 0.9 * E, 0.4, M_OSSO)
for dx in (-4.0, 4.0):  # as patas
    entre("pata", (fx + dx * E, fy, chao + 2.8 * E), (fx + (dx - 0.8) * E, fy - 1.0 * E, chao), 0.5, 0.5, M_OSSO)
luz(fx, fy - 6, chao + 6, 2500, (1.0, 0.5, 0.2), 4)

# ---- S4 = FONTE TERMAL: bicas de vapor saindo do chão e os canos de captação subindo pela parede
nome, x0, x1, chao, fr, prof, alt, tipo = por_nome["S4"]
for x in (x0 + 12, x0 + 24, x1 - 14):
    y = fr + prof * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.8, depth=0.2, location=(x, y, chao + 0.06))
    bpy.context.object.scale.y = 0.7
    bpy.context.object.data.materials.append(M_AGUA)
    for j in range(6):  # a coluna de vapor (bolas subindo, cada vez maiores)
        esfera(x + rnd.uniform(-0.4, 0.4), y + rnd.uniform(-0.3, 0.3), chao + 1.0 + j * 1.6, 0.6 + j * 0.28, M_VAPOR, 2)
    entre("cano", (x + 1.5, y, chao + 0.6), (x + 1.5, fr + prof - 2.5, chao + 0.6), 0.5, 0.5, M_FERRO)
    entre("cano_sobe", (x + 1.5, fr + prof - 2.5, chao + 0.6), (x + 1.6, fr + prof - 2.5, chao + alt - 3), 0.5, 0.5, M_FERRO)
    luz(x, y - 2, chao + 3, 1200, (0.8, 0.9, 1.0), 2)

# ---- S5 = CIDADE SUBTERRÂNEA: casas de pedra, uma torre e lampiões de cristal (o lago continua)
nome, x0, x1, chao, fr, prof, alt, tipo = por_nome["S5"]
cx0 = x0 + 42.0
for k in range(6):
    x = cx0 + (k % 3) * 5.5 + rnd.uniform(-0.5, 0.5)
    y = fr + prof - 6 - (k // 3) * 5.5
    h = rnd.uniform(3.0, 5.5)
    caixa("casa_pedra", x, y - 2, chao, x + 4.2, y + 2, chao + h, M_PEDRA)
    caixa("janela", x + 1.6, y - 2.05, chao + h * 0.5, x + 2.6, y - 1.95, chao + h * 0.5 + 1.0, M_CRISTAL_C)
caixa("torre", cx0 + 17, fr + prof - 7, chao, cx0 + 20, fr + prof - 4, chao + 10, M_PEDRA)
cone(cx0 + 18.5, fr + prof - 5.5, chao + 10, 2.4, 3, M_TELHA, 4)
for x in (cx0 - 2, cx0 + 8, cx0 + 15):
    caixa("poste_luz", x, fr + 6, chao, x + 0.3, fr + 6.3, chao + 3, M_FERRO)
    cone(x + 0.15, fr + 6.15, chao + 3, 0.45, 1.2, M_CRISTAL_C, 5)
    luz(x, fr + 5, chao + 3.5, 600, (0.3, 0.9, 1.0), 0.6)

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
xs = (XE - 3, XD + 16)  # (v4: + o cavalete da ferrovia de carga à direita)
up_lo = 0.866 * (Z_FUNDO - 2) + 0.5 * salas[-1][4]
up_hi = 0.866 * 25 + 0.5 * FUNDO_Y
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
    cena.render.resolution_x, cena.render.resolution_y = LARG_PX, LARG_PX * 9 // 16
cena.render.engine = "BLENDER_EEVEE"
cena.eevee.use_shadows = True
cena.view_settings.view_transform = "AgX"
cena.view_settings.look = "AgX - Punchy"
cena.render.filepath = SAIDA
bpy.ops.render.render(write_still=True)
print("ok", SAIDA, cena.render.resolution_x, cena.render.resolution_y)
