using Godot;

namespace OpenCityMP;

/// <summary>A 1.2 km square flat driving area with a loop road and distant hills.</summary>
public partial class Countryside : Node3D
{
    public static StandardMaterial3D Material(string hex) => new()
    {
        AlbedoColor = new Color(hex), Roughness = 0.88f
    };

    public static MeshInstance3D Box(Node3D parent, Vector3 size, Vector3 position,
        Material material, bool solid = false)
    {
        var mesh = new MeshInstance3D { Mesh = new BoxMesh { Size = size },
            Position = position, MaterialOverride = material };
        parent.AddChild(mesh);
        if (solid)
        {
            var body = new StaticBody3D { Position = position, CollisionLayer = 1, CollisionMask = 0 };
            body.AddChild(new CollisionShape3D { Shape = new BoxShape3D { Size = size } });
            parent.AddChild(body);
        }
        return mesh;
    }

    public override void _Ready()
    {
        var skyMaterial = new ProceduralSkyMaterial
        {
            SkyTopColor = new Color("4485b5"), SkyHorizonColor = new Color("edc8a1"),
            GroundBottomColor = new Color("5c6c45"), GroundHorizonColor = new Color("edc8a1")
        };
        AddChild(new WorldEnvironment
        {
            Environment = new Godot.Environment
            {
                BackgroundMode = Godot.Environment.BGMode.Sky,
                Sky = new Sky { SkyMaterial = skyMaterial },
                AmbientLightSource = Godot.Environment.AmbientSource.Color,
                AmbientLightColor = new Color("b6c9de"), AmbientLightEnergy = 0.65f,
                TonemapMode = Godot.Environment.ToneMapper.Filmic,
                FogEnabled = true, FogLightColor = new Color("d6c9af"), FogDensity = 0.001f
            }
        });
        AddChild(new DirectionalLight3D
        {
            RotationDegrees = new Vector3(-28, -40, 0), LightColor = new Color("ffd6a3"),
            LightEnergy = 1.3f, ShadowEnabled = true,
            DirectionalShadowMaxDistance = 160
        });

        var grass = Material("708252");
        var asphalt = Material("414448");
        var shoulder = Material("a1957b");
        var stripe = Material("e9dfb6");
        Box(this, new Vector3(1200, 2, 1200), new Vector3(0, -1, 0), grass, true);
        // Four broad straights: the northern and southern ones connect the long sides.
        foreach (float x in new[] { 0f, 300f })
        {
            Box(this, new Vector3(17, .03f, 780), new Vector3(x, .015f, 0), shoulder);
            Box(this, new Vector3(12, .03f, 780), new Vector3(x, .045f, 0), asphalt);
            for (int z = -366; z <= 366; z += 12)
                Box(this, new Vector3(.16f, .01f, 5), new Vector3(x, .067f, z), stripe);
        }
        foreach (float z in new[] { -380f, 380f })
        {
            Box(this, new Vector3(317, .03f, 17), new Vector3(150, .018f, z), shoulder);
            Box(this, new Vector3(312, .03f, 12), new Vector3(150, .05f, z), asphalt);
            for (int x = 15; x < 294; x += 12)
                Box(this, new Vector3(5, .01f, .16f), new Vector3(x, .072f, z), stripe);
        }
        // Gravel practice area alongside the starting road.
        Box(this, new Vector3(90, .035f, 120), new Vector3(-52, .02f, 0), shoulder);
        Box(this, new Vector3(25, .04f, 20), new Vector3(-10, .025f, 0), shoulder);

        var random = new RandomNumberGenerator { Seed = 450210 };
        var bark = Material("6f5541");
        var foliage = Material("3e6343");
        // Deterministic sparse grove, keeping the roads and training apron clear.
        for (int i = 0; i < 180; i++)
        {
            float x = random.RandfRange(-540, 540);
            float z = random.RandfRange(-540, 540);
            if (Mathf.Abs(x) < 18 || Mathf.Abs(x - 300) < 18 ||
                (x > -25 && x < 325 && Mathf.Abs(Mathf.Abs(z) - 380) < 22) ||
                (x > -110 && x < 15 && Mathf.Abs(z) < 80)) continue;
            float h = random.RandfRange(4, 9);
            Box(this, new Vector3(.6f, h, .6f), new Vector3(x, h / 2, z), bark, true);
            AddChild(new MeshInstance3D
            {
                Mesh = new CylinderMesh { TopRadius = 0, BottomRadius = h * .45f,
                    Height = h, RadialSegments = 7 },
                Position = new Vector3(x, h, z), MaterialOverride = foliage
            });
        }
        var hillMat = Material("69725e");
        // Scenic hills outside the driving boundary; not traversable terrain.
        for (int i = 0; i < 32; i++)
        {
            float angle = i * Mathf.Tau / 32;
            float h = random.RandfRange(80, 220);
            AddChild(new MeshInstance3D
            {
                Mesh = new SphereMesh { Radius = 1, Height = 2, RadialSegments = 12, Rings = 6 },
                Position = new Vector3(Mathf.Cos(angle) * 760, -30, Mathf.Sin(angle) * 760),
                Scale = new Vector3(160, h, 160), MaterialOverride = hillMat
            });
        }
        var fence = Material("6a6656");
        foreach (float edge in new[] { -590f, 590f })
        {
            Box(this, new Vector3(1180, 1.5f, 1), new Vector3(0, .75f, edge), fence, true);
            Box(this, new Vector3(1, 1.5f, 1180), new Vector3(edge, .75f, 0), fence, true);
        }
        // Roadside shelter.
        var wood = Material("826951");
        foreach (float x in new[] { -85f, -69f })
        foreach (float z in new[] { -46f, -34f })
            Box(this, new Vector3(.4f, 4, .4f), new Vector3(x, 2, z), wood, true);
        Box(this, new Vector3(18, .4f, 14), new Vector3(-77, 4, -40), Material("784c3c"), true);
    }
}
