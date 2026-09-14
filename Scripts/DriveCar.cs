using Godot;

namespace OpenCityMP;

/// <summary>Offline arcade driving controller, not a suspension or tyre simulation.</summary>
public partial class DriveCar : CharacterBody3D
{
    private float _speed;
    private float _yaw;
    private float _cameraYaw;
    private float _cameraPitch = -.23f;
    private float _wheelSpin;
    private Node3D _cameraPivot = null!;
    private Node3D _pitchPivot = null!;
    private SpringArm3D _arm = null!;
    private Camera3D _camera = null!;
    private Label _hud = null!;
    private readonly Node3D[] _steerPivots = new Node3D[4];
    private readonly Node3D[] _spinPivots = new Node3D[4];

    public override void _Ready()
    {
        CollisionLayer = 2;
        CollisionMask = 1;
        FloorSnapLength = .5f;
        AddChild(new CollisionShape3D
        {
            Position = new Vector3(0, .8f, 0),
            Shape = new BoxShape3D { Size = new Vector3(1.85f, 1.2f, 4.6f) }
        });
        BuildVisual();
        _cameraPivot = new Node3D { Position = new Vector3(0, 1.7f, 0) };
        AddChild(_cameraPivot);
        _pitchPivot = new Node3D();
        _cameraPivot.AddChild(_pitchPivot);
        _arm = new SpringArm3D { SpringLength = 8, CollisionMask = 1, Margin = .25f };
        _pitchPivot.AddChild(_arm);
        _arm.AddExcludedObject(GetRid());
        _camera = new Camera3D { Current = true, Fov = 70, Far = 2500, Near = .1f };
        _arm.AddChild(_camera);
        var canvas = new CanvasLayer();
        AddChild(canvas);
        var panel = new PanelContainer { Position = new Vector2(20, 20) };
        canvas.AddChild(panel);
        var margin = new MarginContainer();
        foreach (var key in new[] { "margin_left", "margin_right", "margin_top", "margin_bottom" })
            margin.AddThemeConstantOverride(key, 14);
        panel.AddChild(margin);
        _hud = new Label();
        _hud.AddThemeFontSizeOverride("font_size", 18);
        margin.AddChild(_hud);
        Input.MouseMode = Input.MouseModeEnum.Captured;
    }

    private void BuildVisual()
    {
        // Original generic sedan. This is NOT the requested third-party W210.
        var paint = Countryside.Material("233d49");
        paint.Metallic = .45f;
        paint.Roughness = .3f;
        var glass = Countryside.Material("7196a3");
        glass.Roughness = .18f;
        var trim = Countryside.Material("25282c");
        var chrome = Countryside.Material("afbac0");
        var lamps = Countryside.Material("fff2c5");
        var tail = Countryside.Material("bd3431");
        Countryside.Box(this, new Vector3(1.85f, .55f, 4.6f), new Vector3(0, .7f, 0), paint);
        Countryside.Box(this, new Vector3(1.63f, .6f, 2.25f), new Vector3(0, 1.23f, .15f), glass);
        Countryside.Box(this, new Vector3(1.67f, .09f, 2.25f), new Vector3(0, 1.57f, .15f), paint);
        foreach (float x in new[] { -.82f, .82f })
        {
            Countryside.Box(this, new Vector3(.07f, .67f, .10f), new Vector3(x, 1.22f, .15f), trim);
            Countryside.Box(this, new Vector3(.25f, .18f, .3f), new Vector3(x * 1.24f, 1.1f, -.9f), paint);
            Countryside.Box(this, new Vector3(.025f, .08f, 4.2f), new Vector3(x * 1.14f, .68f, 0), chrome);
        }
        Countryside.Box(this, new Vector3(1.85f, .18f, .12f), new Vector3(0, .45f, -2.3f), trim);
        Countryside.Box(this, new Vector3(1.85f, .18f, .12f), new Vector3(0, .45f, 2.3f), trim);
        Countryside.Box(this, new Vector3(.62f, .3f, .06f), new Vector3(0, .8f, -2.33f), chrome);
        foreach (float x in new[] { -.7f, -.43f, .43f, .7f })
            AddChild(new MeshInstance3D
            {
                Mesh = new SphereMesh { Radius = .13f, Height = .26f, RadialSegments = 12, Rings = 6 },
                Scale = new Vector3(1, 1, .3f), Position = new Vector3(x, .83f, -2.34f),
                MaterialOverride = lamps
            });
        foreach (float x in new[] { -.65f, .65f })
            Countryside.Box(this, new Vector3(.42f, .22f, .06f), new Vector3(x, .8f, 2.32f), tail);

        for (int i = 0; i < 4; i++)
        {
            _steerPivots[i] = new Node3D
            {
                Position = new Vector3(i % 2 == 0 ? -.94f : .94f, .36f, i < 2 ? -1.45f : 1.45f)
            };
            AddChild(_steerPivots[i]);
            _spinPivots[i] = new Node3D();
            _steerPivots[i].AddChild(_spinPivots[i]);
            _spinPivots[i].AddChild(new MeshInstance3D
            {
                Mesh = new CylinderMesh { TopRadius = .36f, BottomRadius = .36f, Height = .24f,
                    RadialSegments = 16 }, RotationDegrees = new Vector3(0, 0, 90), MaterialOverride = trim
            });
            _spinPivots[i].AddChild(new MeshInstance3D
            {
                Mesh = new CylinderMesh { TopRadius = .22f, BottomRadius = .22f, Height = .25f,
                    RadialSegments = 8 }, RotationDegrees = new Vector3(0, 0, 90), MaterialOverride = chrome
            });
        }
    }

    public override void _UnhandledInput(InputEvent e)
    {
        if (e is InputEventMouseMotion m && Input.MouseMode == Input.MouseModeEnum.Captured)
        {
            _cameraYaw -= m.Relative.X * .003f;
            _cameraPitch = Mathf.Clamp(_cameraPitch - m.Relative.Y * .003f, -.7f, .1f);
        }
        if (e is InputEventKey k && k.Pressed && !k.Echo)
        {
            if (k.Keycode == Key.Escape) Input.MouseMode = Input.MouseModeEnum.Visible;
            if (k.Keycode == Key.R) ResetCar();
            if (k.Keycode == Key.C) { _cameraYaw = 0; _cameraPitch = -.23f; }
        }
        if (e is InputEventMouseButton b && b.Pressed)
        {
            if (b.ButtonIndex == MouseButton.Left) Input.MouseMode = Input.MouseModeEnum.Captured;
            if (b.ButtonIndex == MouseButton.WheelUp) _arm.SpringLength = Mathf.Max(4, _arm.SpringLength - .5f);
            if (b.ButtonIndex == MouseButton.WheelDown) _arm.SpringLength = Mathf.Min(14, _arm.SpringLength + .5f);
        }
    }

    private void ResetCar()
    {
        GlobalPosition = new Vector3(0, .8f, 0);
        Velocity = Vector3.Zero;
        _speed = _yaw = _cameraYaw = 0;
        Rotation = Vector3.Zero;
    }

    public override void _PhysicsProcess(double delta)
    {
        float dt = (float)delta;
        bool active = Input.MouseMode == Input.MouseModeEnum.Captured;
        bool gas = active && Input.IsPhysicalKeyPressed(Key.W);
        bool brake = active && Input.IsPhysicalKeyPressed(Key.S);
        bool handbrake = active && Input.IsPhysicalKeyPressed(Key.Space);
        float steering = active ? (Input.IsPhysicalKeyPressed(Key.A) ? 1 : 0) -
            (Input.IsPhysicalKeyPressed(Key.D) ? 1 : 0) : 0;
        bool grounded = IsOnFloor();
        if (grounded)
        {
            if (gas && !brake) _speed = Mathf.MoveToward(_speed, 42, (_speed < 0 ? 18 : 7) * dt);
            else if (brake && !gas) _speed = Mathf.MoveToward(_speed, -10, (_speed > 0 ? 20 : 5) * dt);
            else _speed = Mathf.MoveToward(_speed, 0, 2.2f * dt);
            if (handbrake || !active) _speed = Mathf.MoveToward(_speed, 0, 26 * dt);
            _yaw += steering * Mathf.Clamp(_speed / 9, -1, 1) *
                Mathf.Lerp(1.1f, .40f, Mathf.Clamp(Mathf.Abs(_speed) / 42, 0, 1)) * dt;
        }
        Rotation = new Vector3(0, _yaw, 0);
        var forward = -GlobalBasis.Z;
        float vertical = grounded ? -.5f : Velocity.Y - 22 * dt;
        Velocity = forward * _speed + Vector3.Up * vertical;
        MoveAndSlide();
        // Remove accumulated engine speed on impact; no tunnelling/teleport movement.
        if (IsOnWall()) _speed = new Vector3(Velocity.X, 0, Velocity.Z).Dot(forward);
        if (GlobalPosition.Y < -15) ResetCar();
        _wheelSpin -= _speed * dt / .36f;
        for (int i = 0; i < 4; i++)
        {
            _steerPivots[i].Rotation = new Vector3(0, i < 2 ? steering * .4f : 0, 0);
            _spinPivots[i].Rotation = new Vector3(_wheelSpin, 0, 0);
        }
        _cameraPivot.Rotation = new Vector3(0, _cameraYaw, 0);
        _pitchPivot.Rotation = new Vector3(_cameraPitch, 0, 0);
        _camera.Fov = Mathf.Lerp(_camera.Fov, 70 + Mathf.Abs(_speed) * .15f, 4 * dt);
        _hud.Text = "OPEN CITY MP / VIDÉKI VEZETÉSI TESZT\n" +
            Mathf.RoundToInt(Mathf.Abs(_speed) * 3.6f) + " km/h  |  " + (_speed < -.1f ? "R" : "D") +
            "\nW: gáz   S: fék / hátramenet   A/D: kormány   SPACE: erős fék" +
            "\nEgér: kamera   Görgő: zoom   C: kamera vissza   R: autó vissza" +
            "\nESC: kurzor / fékezés   Kattintás: vezetés\n" +
            "Saját tesztautó • nem a W210 mod • offline • nincs kiszállás";
    }
}
