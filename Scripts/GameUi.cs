using Godot;

namespace OpenCityMP;

public partial class GameUi : CanvasLayer
{
    public override void _Ready()
    {
        var overlay = new Control
        {
            Name = "Overlay",
            MouseFilter = Control.MouseFilterEnum.Ignore
        };
        overlay.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        AddChild(overlay);

        var panel = new PanelContainer
        {
            Position = new Vector2(18.0f, 18.0f),
            Size = new Vector2(420.0f, 104.0f),
            MouseFilter = Control.MouseFilterEnum.Ignore
        };
        var panelStyle = new StyleBoxFlat
        {
            BgColor = new Color(0.035f, 0.045f, 0.075f, 0.83f),
            CornerRadiusTopLeft = 12,
            CornerRadiusTopRight = 12,
            CornerRadiusBottomLeft = 12,
            CornerRadiusBottomRight = 12,
            BorderWidthLeft = 2,
            BorderWidthTop = 2,
            BorderWidthRight = 2,
            BorderWidthBottom = 2,
            BorderColor = new Color("ef5a7b")
        };
        panel.AddThemeStyleboxOverride("panel", panelStyle);
        overlay.AddChild(panel);

        var text = new Label
        {
            Text = "OPEN CITY MP  •  V0.1 PROTOTÍPUS\nWASD: mozgás   SHIFT: futás   SPACE: ugrás\nEgér: kamera   Görgő: távolság   ESC: kurzor",
            Position = new Vector2(16.0f, 11.0f)
        };
        text.AddThemeColorOverride("font_color", new Color("fff4de"));
        text.AddThemeColorOverride("font_shadow_color", new Color(0, 0, 0, 0.8f));
        text.AddThemeConstantOverride("shadow_offset_x", 2);
        text.AddThemeConstantOverride("shadow_offset_y", 2);
        text.AddThemeFontSizeOverride("font_size", 16);
        panel.AddChild(text);

        var crosshair = new Label
        {
            Text = "•",
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            OffsetLeft = -12.0f,
            OffsetTop = -16.0f,
            OffsetRight = 12.0f,
            OffsetBottom = 16.0f
        };
        crosshair.SetAnchorsPreset(Control.LayoutPreset.Center);
        crosshair.AddThemeColorOverride("font_color", new Color(1.0f, 0.85f, 0.55f, 0.85f));
        crosshair.AddThemeFontSizeOverride("font_size", 25);
        overlay.AddChild(crosshair);

        var status = new Label
        {
            Text = "VICE POINT TEST DISTRICT  //  OFFLINE",
            HorizontalAlignment = HorizontalAlignment.Right,
            OffsetLeft = -380.0f,
            OffsetTop = -52.0f,
            OffsetRight = -22.0f,
            OffsetBottom = -20.0f
        };
        status.SetAnchorsPreset(Control.LayoutPreset.BottomRight);
        status.AddThemeColorOverride("font_color", new Color("ffd57a"));
        status.AddThemeFontSizeOverride("font_size", 15);
        overlay.AddChild(status);
    }
}
