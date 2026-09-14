using Godot;

namespace OpenCityMP;

public partial class LowPolyCity : Node3D
{
    private readonly RandomNumberGenerator _random = new();
    private bool _built;

    private StandardMaterial3D _grass = null!;
    private StandardMaterial3D _road = null!;
    private StandardMaterial3D _sidewalk = null!;
    private StandardMaterial3D _line = null!;
    private StandardMaterial3D _trunk = null!;
    private StandardMaterial3D _leaf = null!;
    private StandardMaterial3D _glass = null!;
    private StandardMaterial3D _dark = null!;

    public void Build()
    {
        if (_built) return;
        _built = true;
        _random.Seed = 4502002;

        CreateMaterials();
        AddBox("Ground", new Vector3(150.0f, 1.0f, 150.0f),
            new Vector3(0.0f, -0.55f, 0.0f), _grass, true);

        BuildRoadGrid();
        BuildBlocks();
        BuildBoulevardDetails();
        BuildParkedCars();
        BuildBoundary();
    }

    private void CreateMaterials()
    {
        _grass = MakeMaterial("61825b");
        _road = MakeMaterial("252934");
        _sidewalk = MakeMaterial("b8a58e");
        _line = MakeMaterial("f1c75b");
        _trunk = MakeMaterial("76513d");
        _leaf = MakeMaterial("31856a");
        _glass = MakeMaterial("86b7bd", 0.35f);
        _dark = MakeMaterial("171a22");
    }

    private static StandardMaterial3D MakeMaterial(string color, float roughness = 0.90f)
    {
        return new StandardMaterial3D
        {
            AlbedoColor = new Color(color),
            Roughness = roughness
        };
    }

    private void BuildRoadGrid()
    {
        float[] roadCoordinates = { -56.0f, -28.0f, 0.0f, 28.0f, 56.0f };
        foreach (var coordinate in roadCoordinates)
        {
            AddBox("RoadX", new Vector3(140.0f, 0.10f, 9.0f),
                new Vector3(0.0f, 0.01f, coordinate), _road, false);
            AddBox("RoadZ", new Vector3(9.0f, 0.11f, 140.0f),
                new Vector3(coordinate, 0.02f, 0.0f), _road, false);

            for (var marker = -66; marker <= 66; marker += 6)
            {
                AddBox("LaneMark", new Vector3(2.4f, 0.025f, 0.12f),
                    new Vector3(marker, 0.08f, coordinate), _line, false);
                AddBox("LaneMark", new Vector3(0.12f, 0.025f, 2.4f),
                    new Vector3(coordinate, 0.09f, marker), _line, false);
            }
        }
    }

    private void BuildBlocks()
    {
        float[] blockCenters = { -42.0f, -14.0f, 14.0f, 42.0f };
        string[] palette =
        {
            "dc7f6e", "e3b96d", "6e9aa4", "8c78a8",
            "d6d0b4", "c86967", "5f8e83", "c59672"
        };

        foreach (var blockX in blockCenters)
        foreach (var blockZ in blockCenters)
        {
            AddBox("Sidewalk", new Vector3(18.0f, 0.24f, 18.0f),
                new Vector3(blockX, 0.08f, blockZ), _sidewalk, true);

            float[] offset = { -4.8f, 4.8f };
            foreach (var xOffset in offset)
            foreach (var zOffset in offset)
            {
                var width = _random.RandfRange(6.2f, 8.1f);
                var depth = _random.RandfRange(6.2f, 8.1f);
                var height = _random.RandfRange(7.0f, 23.0f);
                var position = new Vector3(blockX + xOffset, height * 0.5f + 0.22f, blockZ + zOffset);
                var wall = MakeMaterial(palette[_random.RandiRange(0, palette.Length - 1)]);

                AddBox("Building", new Vector3(width, height, depth), position, wall, true);
                AddRooftop(position, width, height, depth);
                AddWindowBands(position, width, height, depth);
            }
        }
    }

    private void AddRooftop(Vector3 buildingPosition, float width, float height, float depth)
    {
        var roofPosition = new Vector3(
            buildingPosition.X,
            buildingPosition.Y + height * 0.5f + 0.35f,
            buildingPosition.Z);
        AddBox("Roof", new Vector3(width + 0.35f, 0.45f, depth + 0.35f),
            roofPosition, _dark, false);

        if (_random.Randf() > 0.50f)
        {
            AddBox("RoofUnit", new Vector3(1.8f, 1.1f, 1.5f),
                roofPosition + new Vector3(0.0f, 0.75f, 0.0f), _sidewalk, false);
        }
    }

    private void AddWindowBands(Vector3 position, float width, float height, float depth)
    {
        var floors = Mathf.Max(2, Mathf.FloorToInt(height / 3.0f));
        for (var floor = 1; floor < floors; floor++)
        {
            var y = position.Y - height * 0.5f + floor * 2.8f;
            AddBox("Windows", new Vector3(width * 0.72f, 0.75f, 0.05f),
                new Vector3(position.X, y, position.Z + depth * 0.5f + 0.03f), _glass, false);
            AddBox("Windows", new Vector3(0.05f, 0.75f, depth * 0.72f),
                new Vector3(position.X + width * 0.5f + 0.03f, y, position.Z), _glass, false);
        }
    }

    private void BuildBoulevardDetails()
    {
        for (var z = -48; z <= 48; z += 12)
        {
            AddPalm(new Vector3(-6.2f, 0.0f, z));
            AddPalm(new Vector3(6.2f, 0.0f, z));
        }

        AddBox("WelcomeSign", new Vector3(7.4f, 2.0f, 0.55f),
            new Vector3(13.0f, 3.1f, 5.5f), MakeMaterial("e45d8b"), true);
        AddBox("SignPost", new Vector3(0.35f, 3.2f, 0.35f),
            new Vector3(10.0f, 1.6f, 5.5f), _dark, true);
        AddBox("SignPost", new Vector3(0.35f, 3.2f, 0.35f),
            new Vector3(16.0f, 1.6f, 5.5f), _dark, true);
    }

    private void AddPalm(Vector3 position)
    {
        AddMesh("PalmTrunk", new CylinderMesh
        {
            TopRadius = 0.18f,
            BottomRadius = 0.30f,
            Height = 4.8f,
            RadialSegments = 7
        }, position + Vector3.Up * 2.4f, Vector3.Zero, _trunk);

        for (var index = 0; index < 5; index++)
        {
            var angle = Mathf.Tau * index / 5.0f;
            var leafPosition = position + new Vector3(
                Mathf.Sin(angle) * 0.75f,
                5.0f,
                Mathf.Cos(angle) * 0.75f);
            AddMesh("PalmLeaf", new SphereMesh
            {
                Radius = 0.72f,
                Height = 0.55f,
                RadialSegments = 7,
                Rings = 3
            }, leafPosition, new Vector3(0.0f, angle, 0.0f), _leaf);
        }
    }

    private void BuildParkedCars()
    {
        AddCar(new Vector3(3.0f, 0.0f, -18.0f), 0.0f, "ed5565");
        AddCar(new Vector3(-3.0f, 0.0f, 20.0f), 0.0f, "e5bd45");
        AddCar(new Vector3(-18.0f, 0.0f, 3.0f), 90.0f, "68a7c4");
        AddCar(new Vector3(34.0f, 0.0f, -3.0f), 90.0f, "b97ac9");
        AddCar(new Vector3(-3.0f, 0.0f, -46.0f), 0.0f, "e6e2d5");
    }

    private void AddCar(Vector3 position, float rotationY, string color)
    {
        var car = new Node3D
        {
            Name = "ParkedCar",
            Position = position,
            RotationDegrees = new Vector3(0.0f, rotationY, 0.0f)
        };
        AddChild(car);
        var paint = MakeMaterial(color, 0.55f);

        AddBoxTo(car, "CarBody", new Vector3(1.8f, 0.55f, 3.8f),
            new Vector3(0.0f, 0.65f, 0.0f), paint);
        AddBoxTo(car, "CarCabin", new Vector3(1.55f, 0.62f, 1.7f),
            new Vector3(0.0f, 1.17f, -0.15f), _glass);

        float[] wheelX = { -0.96f, 0.96f };
        float[] wheelZ = { -1.20f, 1.20f };
        foreach (var x in wheelX)
        foreach (var z in wheelZ)
        {
            AddMeshTo(car, "Wheel", new CylinderMesh
            {
                TopRadius = 0.39f,
                BottomRadius = 0.39f,
                Height = 0.30f,
                RadialSegments = 10
            }, new Vector3(x, 0.42f, z), new Vector3(0.0f, 0.0f, 90.0f), _dark);
        }

        var body = new StaticBody3D
        {
            CollisionLayer = 1,
            CollisionMask = 0,
            Position = new Vector3(0.0f, 0.65f, 0.0f)
        };
        body.AddChild(new CollisionShape3D
        {
            Shape = new BoxShape3D { Size = new Vector3(1.9f, 1.25f, 3.9f) }
        });
        car.AddChild(body);
    }

    private void BuildBoundary()
    {
        AddBox("BoundaryNorth", new Vector3(150.0f, 4.0f, 1.0f),
            new Vector3(0.0f, 2.0f, -74.5f), _dark, true);
        AddBox("BoundarySouth", new Vector3(150.0f, 4.0f, 1.0f),
            new Vector3(0.0f, 2.0f, 74.5f), _dark, true);
        AddBox("BoundaryWest", new Vector3(1.0f, 4.0f, 150.0f),
            new Vector3(-74.5f, 2.0f, 0.0f), _dark, true);
        AddBox("BoundaryEast", new Vector3(1.0f, 4.0f, 150.0f),
            new Vector3(74.5f, 2.0f, 0.0f), _dark, true);
    }

    private void AddBox(
        string name,
        Vector3 size,
        Vector3 position,
        Material material,
        bool collision)
    {
        AddMesh(name, new BoxMesh { Size = size }, position, Vector3.Zero, material);

        if (!collision) return;
        var body = new StaticBody3D
        {
            Name = name + "Collision",
            Position = position,
            CollisionLayer = 1,
            CollisionMask = 0
        };
        body.AddChild(new CollisionShape3D
        {
            Shape = new BoxShape3D { Size = size }
        });
        AddChild(body);
    }

    private void AddMesh(
        string name,
        PrimitiveMesh mesh,
        Vector3 position,
        Vector3 rotationDegrees,
        Material material)
    {
        AddMeshTo(this, name, mesh, position, rotationDegrees, material);
    }

    private static void AddMeshTo(
        Node3D parent,
        string name,
        PrimitiveMesh mesh,
        Vector3 position,
        Vector3 rotationDegrees,
        Material material)
    {
        parent.AddChild(new MeshInstance3D
        {
            Name = name,
            Mesh = mesh,
            Position = position,
            RotationDegrees = rotationDegrees,
            MaterialOverride = material
        });
    }

    private static void AddBoxTo(
        Node3D parent,
        string name,
        Vector3 size,
        Vector3 position,
        Material material)
    {
        AddMeshTo(parent, name, new BoxMesh { Size = size }, position, Vector3.Zero, material);
    }
}
