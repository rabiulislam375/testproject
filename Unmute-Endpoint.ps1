# Unmute and max volume on all active playback endpoints (WASAPI level)
# System beeps use waveOut; apps use endpoint volume - often muted separately

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public enum EDataFlow { eRender = 0, eCapture = 1, eAll = 2 }
public enum ERole { eConsole = 0, eMultimedia = 1, eCommunications = 2 }

[Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
public class MMDeviceEnumerator { }

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IMMDeviceEnumerator {
    int EnumAudioEndpoints(EDataFlow dataFlow, int dwStateMask, out IMMDeviceCollection ppDevices);
}

[Guid("0BD7A1BE-05A0-4D5C-8A14-18CFC3D1B65F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IMMDeviceCollection {
    int GetCount(out int pcDevices);
    int Item(int nDevice, out IMMDevice ppDevice);
}

[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IMMDevice {
    int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
    int OpenPropertyStore(int stgmAccess, out IntPtr properties);
    int GetId([MarshalAs(UnmanagedType.LPWStr)] out string ppstrId);
}

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IAudioEndpointVolume {
    int RegisterControlChangeNotify(IntPtr pNotify);
    int UnregisterControlChangeNotify(IntPtr pNotify);
    int GetChannelCount(out uint pnChannelCount);
    int SetMasterVolumeLevel(float fLevelDB, ref Guid pguidEventContext);
    int SetMasterVolumeLevelScalar(float fLevel, ref Guid pguidEventContext);
    int GetMasterVolumeLevel(out float pfLevelDB);
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int SetChannelVolumeLevel(uint nChannel, float fLevelDB, ref Guid pguidEventContext);
    int SetChannelVolumeLevelScalar(uint nChannel, float fLevel, ref Guid pguidEventContext);
    int GetChannelVolumeLevel(uint nChannel, out float pfLevelDB);
    int GetChannelVolumeLevelScalar(uint nChannel, out float pfLevel);
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, ref Guid pguidEventContext);
    int GetMute(out bool pbMute);
}

public static class EndpointFix {
    static Guid IID_IAudioEndpointVolume = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");
    static Guid GUID_NULL = Guid.Empty;
    static Guid DEVSTATE_ACTIVE = new Guid("00000001-0000-0000-0000-000000000001");

    public static void FixAll() {
        var en = (IMMDeviceEnumerator)new MMDeviceEnumerator();
        IMMDeviceCollection col;
        en.EnumAudioEndpoints(EDataFlow.eRender, 1, out col);
        int count; col.GetCount(out count);
        for (int i = 0; i < count; i++) {
            IMMDevice dev; col.Item(i, out dev);
            string id; dev.GetId(out id);
            object o;
            dev.Activate(ref IID_IAudioEndpointVolume, 23, IntPtr.Zero, out o);
            var vol = (IAudioEndpointVolume)o;
            bool muted; vol.GetMute(out muted);
            float level; vol.GetMasterVolumeLevelScalar(out level);
            vol.SetMute(false, ref GUID_NULL);
            vol.SetMasterVolumeLevelScalar(1.0f, ref GUID_NULL);
            Console.WriteLine("Device: " + id.Substring(Math.Max(0, id.Length - 40)));
            Console.WriteLine("  Was muted=" + muted + " volume=" + (int)(level * 100) + "% -> set 100% unmuted");
        }
    }
}
"@

Write-Host "Fixing WASAPI endpoint volume (app audio path)..." -ForegroundColor Cyan
[EndpointFix]::FixAll()
Write-Host "Done. Test YouTube or Spotify now." -ForegroundColor Green
