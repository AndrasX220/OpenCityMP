using Godot;
namespace OpenCityMP;

public partial class CharacterPreview : Node3D
{
    private Node3D _orbit = null!;
    private float _angle = -.55f;
    private float _distance = 3.5f;
    private Camera3D _camera = null!;
    public override void _Ready()
    {
        AddChild(new WorldEnvironment { Environment = new Godot.Environment {
            BackgroundMode=Godot.Environment.BGMode.Color,BackgroundColor=new Color("202a30"),
            AmbientLightSource=Godot.Environment.AmbientSource.Color,
            AmbientLightColor=new Color("c0c9d0"),AmbientLightEnergy=.65f } });
        AddChild(new DirectionalLight3D {RotationDegrees=new Vector3(-35,-35,0),
            LightEnergy=1.1f,ShadowEnabled=true});
        Countryside.Box(this,new Vector3(5,.1f,5),new Vector3(0,-.08f,0),Countryside.Material("34434b"));
        Countryside.Box(this,new Vector3(.7f,.68f,.7f),new Vector3(0,.34f,.12f),Countryside.Material("146079"));
        AddChild(new ReferenceCharacter {Name="SeatedReference",Seated=true,Position=new Vector3(0,.68f,0)});
        _orbit=new Node3D { Position=new Vector3(0,.95f,0) };AddChild(_orbit);
        _camera=new Camera3D {Current=true,Fov=42};
        _orbit.AddChild(_camera);
        var canvas=new CanvasLayer();AddChild(canvas);
        canvas.AddChild(new Label {Position=new Vector2(20,20),
            Text="KARAKTER / saját low-poly rekonstrukció\nBal egér húzás: körbenézés • görgő: zoom\nStatikus ülő póz; nem az eredeti asset."});
        Input.MouseMode=Input.MouseModeEnum.Visible;
    }
    public override void _UnhandledInput(InputEvent e)
    {
        if(e is InputEventMouseMotion m && Input.IsMouseButtonPressed(MouseButton.Left))
            _angle-=m.Relative.X*.01f;
        if(e is InputEventMouseButton b && b.Pressed)
        {
            if(b.ButtonIndex==MouseButton.WheelUp) _distance=Mathf.Max(1.8f,_distance-.2f);
            if(b.ButtonIndex==MouseButton.WheelDown) _distance=Mathf.Min(6,_distance+.2f);
        }
    }
    public override void _Process(double delta)
    {
        _orbit.Rotation=new Vector3(0,_angle,0);
        _camera.Position=new Vector3(0,.28f,-_distance);
        _camera.LookAt(_orbit.GlobalPosition,Vector3.Up);
    }
}
