// Unreal engine integration file.

using System.IO;
using UnrealBuildTool;

public class HalcyonZig : ModuleRules
{
	public HalcyonZig(ReadOnlyTargetRules Target) : base(Target)
	{
		Type = ModuleType.External;

		if (Target.Platform == UnrealTargetPlatform.Win64)
		{
			// Add the import library
			PublicAdditionalLibraries.Add(Path.Combine(ModuleDirectory, "zig-out", "lib", "Halcyon.lib"));
			// PublicSystemLibraries.Add("ucrt.lib");
			PublicSystemLibraries.Add("ntdll.lib");
			// PublicSystemLibraries.Add("msvcrt.lib");
			// PublicSystemLibraries.Add("vcruntime.lib");

			// Delay-load the DLL, so we can load it from the right place first
			// PublicDelayLoadDLLs.Add("Halcyon.dll");

			// Ensure that the DLL is staged along with the executable
			// RuntimeDependencies.Add("$(PluginDir)/Binaries/ThirdParty/zig-halcyon/zig-out/lib/Halcyon.dll");
        }
        else if (Target.Platform == UnrealTargetPlatform.Mac)
        {
            PublicDelayLoadDLLs.Add(Path.Combine(ModuleDirectory, "Mac", "Release", "libHalcyon.dylib"));
            RuntimeDependencies.Add("$(PluginDir)/Source/ThirdParty/zig-halcyon/zig-out/lib/libHalcyon.dylib");
        }
        else if (Target.Platform == UnrealTargetPlatform.Linux)
		{
			string ExampleSoPath = Path.Combine("$(PluginDir)", "Binaries", "ThirdParty", "zig-halcyon", "zig-out", "lib", "libHalcyon.so");
			PublicAdditionalLibraries.Add(ExampleSoPath);
			PublicDelayLoadDLLs.Add(ExampleSoPath);
			RuntimeDependencies.Add(ExampleSoPath);
		}
	}
}
