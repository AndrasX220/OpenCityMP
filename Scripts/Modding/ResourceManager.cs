using System.Collections.Generic;
using System.Text.Json;
using Godot;

namespace OpenCityMP.Modding;

/// <summary>
/// Discovers MTA-style resource manifests. Lua execution is planned for V0.3.
/// </summary>
public partial class ResourceManager : Node
{
    public const string ResourcesRoot = "res://resources";
    public IReadOnlyDictionary<string, ResourceManifest> Resources => _resources;

    private readonly Dictionary<string, ResourceManifest> _resources = new();

    public override void _Ready()
    {
        DiscoverResources();
    }

    public void DiscoverResources()
    {
        _resources.Clear();
        using var directory = DirAccess.Open(ResourcesRoot);
        if (directory is null)
        {
            GD.Print("No resources directory found.");
            return;
        }

        directory.ListDirBegin();
        while (true)
        {
            var entry = directory.GetNext();
            if (string.IsNullOrEmpty(entry)) break;
            if (!directory.CurrentIsDir() || entry.StartsWith(".")) continue;

            var manifestPath = ResourcesRoot + "/" + entry + "/resource.json";
            if (!FileAccess.FileExists(manifestPath)) continue;

            try
            {
                var json = FileAccess.GetFileAsString(manifestPath);
                var manifest = JsonSerializer.Deserialize<ResourceManifest>(
                    json,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (manifest is null || string.IsNullOrWhiteSpace(manifest.Name))
                    continue;

                _resources[manifest.Name] = manifest;
                GD.Print("Resource discovered: " + manifest.Name + " " + manifest.Version);
            }
            catch (JsonException exception)
            {
                GD.PushWarning("Invalid manifest at " + manifestPath + ": " + exception.Message);
            }
        }
        directory.ListDirEnd();
    }
}

public sealed class ResourceManifest
{
    public string Name { get; set; } = "";
    public string Version { get; set; } = "0.0.0";
    public string Description { get; set; } = "";
    public ResourceScripts Scripts { get; set; } = new();
}

public sealed class ResourceScripts
{
    public string[] Server { get; set; } = System.Array.Empty<string>();
    public string[] Client { get; set; } = System.Array.Empty<string>();
    public string[] Shared { get; set; } = System.Array.Empty<string>();
}
