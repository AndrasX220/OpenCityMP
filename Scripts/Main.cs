using Godot;
using OpenCityMP.Modding;
using OpenCityMP.Networking;

namespace OpenCityMP;

public partial class Main : Node3D
{
    public override void _Ready()
    {
        SetupEnvironment();

        var city = new LowPolyCity { Name = "VicePointTestDistrict" };
        AddChild(city);
        city.Build();

        var player = new PlayerController
        {
            Name = "LocalPlayer",
            Position = new Vector3(3.0f, 1.2f, 8.0f)
        };
        AddChild(player);

        AddChild(new GameUi { Name = "HUD" });
        AddChild(new NetworkManager { Name = "NetworkManager" });
        AddChild(new ResourceManager { Name = "ResourceManager" });

        GD.Print("OpenCityMP V0.1 ready.");
    }

    private void SetupEnvironment()
    {
        var environment = new Godot.Environment
        {
            BackgroundMode = Godot.Environment.BGMode.Color,
            BackgroundColor = new Color("58a6b8"),
            AmbientLightSource = Godot.Environment.AmbientSource.Color,
            AmbientLightColor = new Color("ffd0a6"),
            AmbientLightEnergy = 0.72f,
            FogEnabled = true,
            FogLightColor = new Color("e8a878"),
            FogLightEnergy = 0.85f,
            FogDensity = 0.0038f
        };

        AddChild(new WorldEnvironment
        {
            Name = "PS2Environment",
            Environment = environment
        });

        AddChild(new DirectionalLight3D
        {
            Name = "Sun",
            RotationDegrees = new Vector3(-48.0f, -32.0f, 0.0f),
            LightColor = new Color("ffd29c"),
            LightEnergy = 1.25f,
            ShadowEnabled = true
        });
    }
}
