using Godot;

namespace OpenCityMP;

// Driving sandbox entry point. Legacy city/controller remain available in source.
public partial class Main : Node3D
{
    public override void _Ready()
    {
        var world = new Countryside { Name = "Countryside" };
        AddChild(world);
        var car = new DriveCar { Name = "TestSedan", Position = new Vector3(0, 0.8f, 0) };
        AddChild(car);
    }
}
