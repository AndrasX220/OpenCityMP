using Godot;

namespace OpenCityMP;

public partial class PlayerController : CharacterBody3D
{
    [Export] public float WalkSpeed { get; set; } = 5.4f;
    [Export] public float SprintSpeed { get; set; } = 8.5f;
    [Export] public float Acceleration { get; set; } = 22.0f;
    [Export] public float JumpVelocity { get; set; } = 7.2f;
    [Export] public float MouseSensitivity { get; set; } = 0.0024f;

    private const float Gravity = 22.0f;
    private Node3D _visual = null!;
    private Node3D _cameraYaw = null!;
    private Node3D _cameraPitch = null!;
    private SpringArm3D _springArm = null!;
    private float _yaw;
    private float _pitch = -0.20f;

    public override void _Ready()
    {
        CollisionLayer = 2;
        CollisionMask = 1;
        BuildCharacter();
        BuildCamera();
        Input.MouseMode = Input.MouseModeEnum.Captured;
    }

    private void BuildCharacter()
    {
        AddChild(new CollisionShape3D
        {
            Name = "PlayerCollision",
            Position = new Vector3(0.0f, 0.95f, 0.0f),
            Shape = new CapsuleShape3D
            {
                Radius = 0.42f,
                Height = 1.9f
            }
        });

        _visual = new Node3D { Name = "CharacterVisual" };
        AddChild(_visual);

        var skin = new StandardMaterial3D
        {
            AlbedoColor = new Color("d9a06f"),
            Roughness = 0.92f
        };
        var shirt = new StandardMaterial3D
        {
            AlbedoColor = new Color("f15b64"),
            Roughness = 0.9f
        };
        var jeans = new StandardMaterial3D
        {
            AlbedoColor = new Color("253a63"),
            Roughness = 0.95f
        };
        var dark = new StandardMaterial3D
        {
            AlbedoColor = new Color("161822"),
            Roughness = 0.95f
        };

        AddPart(_visual, "Body", new CapsuleMesh
        {
            Radius = 0.40f,
            Height = 1.08f,
            RadialSegments = 8,
            Rings = 4
        }, new Vector3(0.0f, 1.18f, 0.0f), shirt);

        AddPart(_visual, "Head", new SphereMesh
        {
            Radius = 0.31f,
            Height = 0.62f,
            RadialSegments = 8,
            Rings = 4
        }, new Vector3(0.0f, 1.92f, 0.0f), skin);

        AddPart(_visual, "LegLeft", new BoxMesh
        {
            Size = new Vector3(0.28f, 0.68f, 0.30f)
        }, new Vector3(-0.20f, 0.46f, 0.0f), jeans);
        AddPart(_visual, "LegRight", new BoxMesh
        {
            Size = new Vector3(0.28f, 0.68f, 0.30f)
        }, new Vector3(0.20f, 0.46f, 0.0f), jeans);

        AddPart(_visual, "Hair", new SphereMesh
        {
            Radius = 0.315f,
            Height = 0.28f,
            RadialSegments = 8,
            Rings = 3
        }, new Vector3(0.0f, 2.12f, 0.01f), dark);
    }

    private static void AddPart(
        Node3D parent,
        string name,
        PrimitiveMesh mesh,
        Vector3 position,
        Material material)
    {
        parent.AddChild(new MeshInstance3D
        {
            Name = name,
            Mesh = mesh,
            Position = position,
            MaterialOverride = material
        });
    }

    private void BuildCamera()
    {
        _cameraYaw = new Node3D
        {
            Name = "CameraYaw",
            Position = new Vector3(0.0f, 1.25f, 0.0f)
        };
        AddChild(_cameraYaw);

        _cameraPitch = new Node3D { Name = "CameraPitch" };
        _cameraYaw.AddChild(_cameraPitch);

        _springArm = new SpringArm3D
        {
            Name = "CameraArm",
            SpringLength = 5.7f,
            Margin = 0.18f,
            CollisionMask = 1
        };
        _cameraPitch.AddChild(_springArm);
        _springArm.AddExcludedObject(GetRid());

        _springArm.AddChild(new Camera3D
        {
            Name = "PlayerCamera",
            Current = true,
            Fov = 67.0f,
            Near = 0.08f
        });

        UpdateCameraRotation();
    }

    public override void _UnhandledInput(InputEvent inputEvent)
    {
        if (inputEvent is InputEventMouseMotion mouseMotion &&
            Input.MouseMode == Input.MouseModeEnum.Captured)
        {
            _yaw -= mouseMotion.Relative.X * MouseSensitivity;
            _pitch -= mouseMotion.Relative.Y * MouseSensitivity;
            _pitch = Mathf.Clamp(_pitch, -0.90f, 0.35f);
            UpdateCameraRotation();
        }

        if (inputEvent is InputEventMouseButton mouseButton && mouseButton.Pressed)
        {
            if (mouseButton.ButtonIndex == MouseButton.WheelUp)
                _springArm.SpringLength = Mathf.Max(2.5f, _springArm.SpringLength - 0.5f);
            if (mouseButton.ButtonIndex == MouseButton.WheelDown)
                _springArm.SpringLength = Mathf.Min(8.5f, _springArm.SpringLength + 0.5f);
            if (mouseButton.ButtonIndex == MouseButton.Left &&
                Input.MouseMode != Input.MouseModeEnum.Captured)
                Input.MouseMode = Input.MouseModeEnum.Captured;
        }

        if (inputEvent is InputEventKey keyEvent &&
            keyEvent.Pressed &&
            keyEvent.Keycode == Key.Escape)
            Input.MouseMode = Input.MouseModeEnum.Visible;
    }

    private void UpdateCameraRotation()
    {
        _cameraYaw.Rotation = new Vector3(0.0f, _yaw, 0.0f);
        _cameraPitch.Rotation = new Vector3(_pitch, 0.0f, 0.0f);
    }

    public override void _PhysicsProcess(double delta)
    {
        var velocity = Velocity;
        if (!IsOnFloor())
            velocity.Y -= Gravity * (float)delta;
        else if (Input.IsPhysicalKeyPressed(Key.Space))
            velocity.Y = JumpVelocity;

        var input = Vector2.Zero;
        if (Input.IsPhysicalKeyPressed(Key.W)) input.Y -= 1.0f;
        if (Input.IsPhysicalKeyPressed(Key.S)) input.Y += 1.0f;
        if (Input.IsPhysicalKeyPressed(Key.A)) input.X -= 1.0f;
        if (Input.IsPhysicalKeyPressed(Key.D)) input.X += 1.0f;
        input = input.Normalized();

        var forward = -_cameraYaw.GlobalBasis.Z;
        var right = _cameraYaw.GlobalBasis.X;
        forward.Y = 0.0f;
        right.Y = 0.0f;

        var direction = (right.Normalized() * input.X + forward.Normalized() * -input.Y).Normalized();
        var sprinting = Input.IsPhysicalKeyPressed(Key.Shift);
        var targetSpeed = sprinting ? SprintSpeed : WalkSpeed;
        var target = direction * targetSpeed;

        velocity.X = Mathf.MoveToward(velocity.X, target.X, Acceleration * (float)delta);
        velocity.Z = Mathf.MoveToward(velocity.Z, target.Z, Acceleration * (float)delta);
        Velocity = velocity;

        if (direction.LengthSquared() > 0.01f)
        {
            var targetAngle = Mathf.Atan2(direction.X, direction.Z);
            _visual.Rotation = new Vector3(
                0.0f,
                Mathf.LerpAngle(_visual.Rotation.Y, targetAngle, 12.0f * (float)delta),
                0.0f);
        }

        MoveAndSlide();
    }
}
