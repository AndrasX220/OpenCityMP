using Godot;

namespace OpenCityMP;

/// <summary>Original faceted mesh reconstruction from a single reference image.
/// Model faces -Z. Seated origin is at the seat, standing origin at the soles.
/// Not a scan or exact reproduction. Static separate parts; no skeleton yet.</summary>
public partial class ReferenceCharacter : Node3D
{
    [Export] public bool Seated { get; set; } = true;
    private readonly Material _cloth = Mat("939592");
    private readonly Material _shade = Mat("747874");
    private readonly Material _skin = Mat("b6a17a");
    private readonly Material _black = Mat("252b2b");
    private readonly Material _sole = Mat("656967");

    private static StandardMaterial3D Mat(string color) => new()
    {
        AlbedoColor = new Color(color), Roughness = .94f,
        // Two-sided triangles keep procedural facets visible regardless of winding.
        CullMode = BaseMaterial3D.CullModeEnum.Disabled
    };

    public override void _Ready()
    {
        float hip = Seated ? 0 : .88f;
        var root = new Node3D { Name = "BodyParts", Position = new Vector3(0, hip, 0) };
        AddChild(root);
        RingBody(root, "Jacket", new[] {
            new Vector3(.21f, .02f, .13f), new Vector3(.24f, .23f, .14f),
            new Vector3(.30f, .55f, .15f), new Vector3(.21f, .65f, .12f)
        }, Vector3.Zero, _cloth);
        RingBody(root, "Hood", new[] {
            new Vector3(.17f,.56f,.14f), new Vector3(.20f,.69f,.14f),
            new Vector3(.14f,.77f,.10f)
        }, new Vector3(0,0,.035f), _shade);
        Segment(root,"Neck",new Vector3(0,.65f,0),new Vector3(0,.77f,0),.075f,.07f,_skin);
        RingBody(root,"Head",new[] {
            new Vector3(.065f,.73f,.065f),new Vector3(.115f,.80f,.095f),
            new Vector3(.127f,.94f,.11f),new Vector3(.10f,1.015f,.09f),
            new Vector3(.045f,1.04f,.05f)
        },new Vector3(0,0,-.015f),_skin);
        Box(root,"Nose",new Vector3(.046f,.065f,.055f),new Vector3(0,.856f,-.126f),_skin);
        Box(root,"Mouth",new Vector3(.045f,.012f,.012f),new Vector3(0,.785f,-.101f),_black);
        foreach(float side in new[]{-1f,1f})
        {
            Box(root,"Lens",new Vector3(.10f,.064f,.025f),
                new Vector3(side*.06f,.917f,-.116f),_black);
            Box(root,"GlassesArm",new Vector3(.017f,.018f,.15f),
                new Vector3(side*.122f,.924f,-.02f),_black);
            RingBody(root,"Earcup",new[] {
                new Vector3(.036f,0,.06f),new Vector3(.046f,.045f,.065f),
                new Vector3(.036f,.13f,.06f)
            },new Vector3(side*.147f,.855f,0),_black);
            Segment(root,"Headband",new Vector3(side*.145f,.955f,.01f),
                new Vector3(side*.07f,1.05f,.01f),.017f,.017f,_black);
            // Shoulder harness runs down the jacket front and across the chest.
            Segment(root,"Harness",new Vector3(side*.185f,.625f,-.13f),
                new Vector3(side*.10f,.33f,-.155f),.027f,.023f,_black);
            Segment(root,"BackHarness",new Vector3(side*.185f,.62f,.12f),
                new Vector3(side*.11f,.10f,.135f),.024f,.024f,_black);
            var shoulder = new Vector3(side*.285f,.54f,0);
            var elbow = Seated ? new Vector3(side*.35f,.24f,-.10f) :
                new Vector3(side*.34f,.27f,0);
            var wrist = Seated ? new Vector3(side*.07f,.11f,-.35f) :
                new Vector3(side*.34f,.025f,-.015f);
            Segment(root,"UpperSleeve",shoulder,elbow,.12f,.093f,_cloth);
            Segment(root,"ForeSleeve",elbow,wrist,.095f,.066f,_cloth);
            Segment(root,"Cuff",wrist,new Vector3(wrist.X,wrist.Y-.025f,wrist.Z-.02f),
                .07f,.068f,_shade);
            var palm = wrist + new Vector3(-side*.024f,-.01f,-.035f);
            Box(root,"Palm",new Vector3(.095f,.044f,.115f),palm,_skin);
            // Individually modelled fingers, lightly folded in the lap.
            for(int i=0;i<4;i++)
            {
                var a=palm+new Vector3((i-1.5f)*.022f,-.007f,-.05f);
                var b=a+new Vector3(-side*.022f,-.014f,-.06f);
                Segment(root,"Finger",a,b,.010f,.008f,_skin);
            }
            Segment(root,"Thumb",palm+new Vector3(side*.05f,0,0),
                palm+new Vector3(side*.075f,-.015f,-.045f),.017f,.012f,_skin);

            var thigh = new Vector3(side*.145f,0,0);
            var knee = Seated ? new Vector3(side*.22f,-.12f,-.43f) :
                new Vector3(side*.145f,-.40f,0);
            var ankle = Seated ? new Vector3(side*.23f,-.54f,-.48f) :
                new Vector3(side*.15f,-.77f,-.015f);
            Segment(root,"Thigh",thigh,knee,.145f,.115f,_cloth);
            Segment(root,"Shin",knee,ankle,.11f,.071f,_cloth);
            Box(root,"Boot",new Vector3(.16f,.14f,.27f),
                ankle+new Vector3(0,-.025f,-.065f),_black);
            Box(root,"Sole",new Vector3(.17f,.033f,.29f),
                ankle+new Vector3(0,-.095f,-.065f),_sole);
            for(int i=0;i<3;i++)
                Box(root,"Lace",new Vector3(.12f,.012f,.018f),
                    ankle+new Vector3(0,.045f,-.07f-i*.035f),_sole);
        }
        Segment(root,"BandTop",new Vector3(-.07f,1.05f,.01f),
            new Vector3(.07f,1.05f,.01f),.017f,.017f,_black);
        Box(root,"ChestStrap",new Vector3(.45f,.037f,.025f),new Vector3(0,.36f,-.155f),_black);
        Box(root,"Buckle",new Vector3(.06f,.052f,.04f),new Vector3(0,.36f,-.173f),_sole);
        Box(root,"Zip",new Vector3(.011f,.29f,.014f),new Vector3(0,.18f,-.146f),_black);
    }

    private static void Box(Node3D parent,string name,Vector3 size,Vector3 p,Material m)
    {
        parent.AddChild(new MeshInstance3D { Name=name, Position=p,
            Mesh=new BoxMesh { Size=size },MaterialOverride=m });
    }

    private static void Segment(Node3D parent,string name,Vector3 a,Vector3 b,
        float radiusA,float radiusB,Material mat)
    {
        var axis=(b-a).Normalized();
        var helper=Mathf.Abs(axis.Dot(Vector3.Up))>.95f?Vector3.Right:Vector3.Up;
        var x=helper.Cross(axis).Normalized();
        var z=x.Cross(axis).Normalized();
        var part=new Node3D { Name=name, Position=a, Basis=new Basis(x,axis,z) };
        parent.AddChild(part);
        RingBody(part,"Facets",new[] {new Vector3(radiusA,0,radiusA),
            new Vector3((radiusA+radiusB)*.52f,a.DistanceTo(b)*.48f,(radiusA+radiusB)*.52f),
            new Vector3(radiusB,a.DistanceTo(b),radiusB)},Vector3.Zero,mat);
    }

    private static void RingBody(Node3D parent,string name,Vector3[] rings,Vector3 p,Material mat)
    {
        const int sides=8;
        var st=new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);
        Vector3 V(int r,int i)
        {
            float angle=Mathf.Tau*i/sides+Mathf.Pi/8;
            return new Vector3(Mathf.Cos(angle)*rings[r].X,rings[r].Y,
                Mathf.Sin(angle)*rings[r].Z);
        }
        void Tri(Vector3 a,Vector3 b,Vector3 c)
        {
            var n=(b-a).Cross(c-a).Normalized();
            st.SetNormal(n); st.AddVertex(a);st.SetNormal(n);st.AddVertex(b);
            st.SetNormal(n);st.AddVertex(c);
        }
        for(int r=0;r<rings.Length-1;r++)
        for(int i=0;i<sides;i++)
        {
            Tri(V(r,i),V(r+1,i),V(r+1,(i+1)%sides));
            Tri(V(r,i),V(r+1,(i+1)%sides),V(r,(i+1)%sides));
        }
        for(int i=0;i<sides;i++)
        {
            Tri(new Vector3(0,rings[0].Y,0),V(0,i),V(0,(i+1)%sides));
            int last=rings.Length-1;
            Tri(new Vector3(0,rings[last].Y,0),V(last,(i+1)%sides),V(last,i));
        }
        parent.AddChild(new MeshInstance3D { Name=name,Position=p,
            Mesh=st.Commit(),MaterialOverride=mat });
        st.Dispose();
    }
}
