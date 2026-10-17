using System;
using System.Runtime.InteropServices;

enum EDataFlow { eRender = 0, eCapture = 1, eAll = 2 }
enum ERole { eConsole = 0, eMultimedia = 1, eCommunications = 2 }

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int EnumAudioEndpoints(EDataFlow flow, int stateMask, out IMMDeviceCollection devices);
    int GetDefaultAudioEndpoint(EDataFlow flow, ERole role, out IMMDevice device);
}

[Guid("0BD7A1BE-05A0-4D5C-8A14-18CFC3D1B65F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceCollection {
    int GetCount(out int count);
    int Item(int index, out IMMDevice device);
}

[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref Guid iid, int clsCtx, IntPtr param, [MarshalAs(UnmanagedType.IUnknown)] out object iface);
    int OpenPropertyStore(int access, out IPropertyStore store);
    int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
}

[Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IPropertyStore {
    int GetCount(out int c);
    int GetAt(int i, out PropertyKey key);
    int GetValue(ref PropertyKey key, out PropVariant val);
}

[StructLayout(LayoutKind.Sequential)]
struct PropertyKey { public Guid fmtid; public int pid; }
[StructLayout(LayoutKind.Sequential)]
struct PropVariant { public ushort vt, w1, w2, w3; public IntPtr p; public int i; }

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int RegisterControlChangeNotify(IntPtr n);
    int UnregisterControlChangeNotify(IntPtr n);
    int GetChannelCount(out uint c);
    int SetMasterVolumeLevel(float db, ref Guid ctx);
    int SetMasterVolumeLevelScalar(float level, ref Guid ctx);
    int GetMasterVolumeLevel(out float db);
    int GetMasterVolumeLevelScalar(out float level);
    int SetChannelVolumeLevel(uint ch, float db, ref Guid ctx);
    int SetChannelVolumeLevelScalar(uint ch, float level, ref Guid ctx);
    int GetChannelVolumeLevel(uint ch, out float db);
    int GetChannelVolumeLevelScalar(uint ch, out float level);
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool mute, ref Guid ctx);
    int GetMute(out bool mute);
}

[Guid("870af69c-171d-4cf9-af29-092f86dc0818"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IPolicyConfig {
    int Unused1(); int Unused2(); int Unused3(); int Unused4(); int Unused5();
    int Unused6(); int Unused7(); int Unused8(); int Unused9(); int Unused10();
    int SetDefaultEndpoint([MarshalAs(UnmanagedType.LPWStr)] string deviceId, ERole role);
}

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorCom { }

[ComImport, Guid("870af69c-171d-4cf9-af29-092f86dc0818")]
class PolicyConfigCom { }

class Program {
    static PropertyKey PKEY_NAME = new PropertyKey {
        fmtid = new Guid("a45c254e-df1c-4efd-8020-67d146a850e0"), pid = 2
    };
    static Guid IID_VOL = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");
    static Guid NULL_GUID = Guid.Empty;
    const int CLSCTX_ALL = 23;

    static string GetName(IMMDevice dev) {
        IPropertyStore store;
        dev.OpenPropertyStore(0, out store);
        PropVariant pv;
        var key = PKEY_NAME;
        store.GetValue(ref key, out pv);
        return Marshal.PtrToStringUni(pv.p) ?? "?";
    }

    static void Main() {
        var en = (IMMDeviceEnumerator)new MMDeviceEnumeratorCom();
        IMMDeviceCollection col;
        en.EnumAudioEndpoints(EDataFlow.eRender, 1, out col);
        int count; col.GetCount(out count);
        string speakerId = null;

        Console.WriteLine("=== Playback endpoints ===");
        for (int i = 0; i < count; i++) {
            IMMDevice dev; col.Item(i, out dev);
            string id; dev.GetId(out id);
            string name = GetName(dev);
            object o; dev.Activate(ref IID_VOL, CLSCTX_ALL, IntPtr.Zero, out o);
            var vol = (IAudioEndpointVolume)o;
            bool muted; vol.GetMute(out muted);
            float level; vol.GetMasterVolumeLevelScalar(out level);
            Console.WriteLine(name);
            Console.WriteLine("  Muted=" + muted + " Volume=" + (int)(level * 100) + "%");
            vol.SetMute(false, ref NULL_GUID);
            vol.SetMasterVolumeLevelScalar(1.0f, ref NULL_GUID);
            if (name.IndexOf("Speaker", StringComparison.OrdinalIgnoreCase) >= 0)
                speakerId = id;
        }

        if (speakerId != null) {
            var policy = (IPolicyConfig)new PolicyConfigCom();
            foreach (ERole role in Enum.GetValues(typeof(ERole))) {
                policy.SetDefaultEndpoint(speakerId, role);
            }
            Console.WriteLine("\nSet default output to Speakers for all roles.");
        }

        Console.WriteLine("\n=== Default devices now ===");
        foreach (ERole role in Enum.GetValues(typeof(ERole))) {
            IMMDevice d; en.GetDefaultAudioEndpoint(EDataFlow.eRender, role, out d);
            Console.WriteLine(role + ": " + GetName(d));
        }
    }
}
