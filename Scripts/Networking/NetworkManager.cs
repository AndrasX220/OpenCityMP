using Godot;

namespace OpenCityMP.Networking;

/// <summary>
/// Dedicated-server/client connection scaffold for V0.2.
/// The V0.1 scene runs offline; no server is started automatically.
/// </summary>
public partial class NetworkManager : Node
{
    public const int DefaultPort = 22005;
    public const int MaxPlayers = 32;

    public Error Host(int port = DefaultPort)
    {
        var peer = new ENetMultiplayerPeer();
        var error = peer.CreateServer(port, MaxPlayers);
        if (error != Error.Ok)
        {
            GD.PushError("Server start failed: " + error);
            return error;
        }

        Multiplayer.MultiplayerPeer = peer;
        GD.Print("OpenCityMP server listening on UDP " + port);
        return Error.Ok;
    }

    public Error Join(string address, int port = DefaultPort)
    {
        var peer = new ENetMultiplayerPeer();
        var error = peer.CreateClient(address, port);
        if (error != Error.Ok)
        {
            GD.PushError("Connection failed: " + error);
            return error;
        }

        Multiplayer.MultiplayerPeer = peer;
        GD.Print("Connecting to " + address + ":" + port);
        return Error.Ok;
    }

    public void Disconnect()
    {
        Multiplayer.MultiplayerPeer?.Close();
        Multiplayer.MultiplayerPeer = null;
    }
}
