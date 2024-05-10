const std = @import("std");

const Sdk = @This();

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("relToPath requires an absolute path!");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

fn assimpPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("relToPath requires an absolute path!");
    return comptime blk: {
        const root_dir = sdkPath("/vendor/assimp");
        break :blk root_dir ++ suffix;
    };
}

builder: *std.Build,

pub fn init(b: *std.Build) *Sdk {
    const sdk = b.allocator.create(Sdk) catch @panic("out of memory");
    sdk.* = Sdk{
        .builder = b,
    };
    return sdk;
}

const UpperCaseFormatter = std.fmt.Formatter(struct {
    pub fn format(
        string: []const u8,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) @TypeOf(writer).Error!void {
        _ = fmt;
        _ = options;

        var tmp: [256]u8 = undefined;
        var i: usize = 0;
        while (i < string.len) : (i += tmp.len) {
            try writer.writeAll(std.ascii.upperString(&tmp, string[i..@min(string.len, i + tmp.len)]));
        }
    }
}.format);

fn fmtUpperCase(string: []const u8) UpperCaseFormatter {
    return UpperCaseFormatter{ .data = string };
}

const define_name_patches = struct {
    pub const Blender = "BLEND";
    pub const Unreal = "3D";
};

/// Creates a new LibExeObjStep that will build Assimp. `linkage`
pub fn createLibrary(sdk: *Sdk, linkage: std.Build.Step.Linkage, formats: FormatSet) *std.Build.Step {
    const lib = switch (linkage) {
        .static => sdk.builder.addStaticLibrary("assimp", null),
        .dynamic => sdk.builder.addSharedLibrary("assimp", null, .unversioned),
    };

    lib.linkLibC();
    lib.linkLibCpp();

    for (sdk.getIncludePaths()) |path| {
        lib.addIncludePath(path);
    }

    lib.addIncludePath(assimpPath("/"));
    lib.addIncludePath(assimpPath("/contrib"));
    lib.addIncludePath(assimpPath("/code"));
    lib.addIncludePath(assimpPath("/contrib/pugixml/src/"));
    lib.addIncludePath(assimpPath("/contrib/rapidjson/include"));
    lib.addIncludePath(assimpPath("/contrib/unzip"));
    lib.addIncludePath(assimpPath("/contrib/zlib"));
    lib.addIncludePath(assimpPath("/contrib/openddlparser/include"));

    addSources(lib, &sources.common);

    inline for (std.meta.fields(Format)) |fld| {
        if (@field(formats, fld.name)) {
            addSources(lib, &@field(sources, fld.name));
        } else {
            var name = fld.name;
            if (@hasDecl(define_name_patches, fld.name))
                name = @field(define_name_patches, fld.name);

            const define_importer = sdk.builder.fmt("ASSIMP_BUILD_NO_{}_IMPORTER", .{fmtUpperCase(name)});
            const define_exporter = sdk.builder.fmt("ASSIMP_BUILD_NO_{}_EXPORTER", .{fmtUpperCase(name)});

            lib.defineCMacro(define_importer, null);
            lib.defineCMacro(define_exporter, null);
        }
    }

    inline for (comptime std.meta.declarations(sources.libraries)) |ext_lib| {
        addSources(lib, &@field(sources.libraries, ext_lib.name));
    }

    return lib;
}

fn addSources(lib: *std.Build.Step, file_list: []const []const u8) void {
    const flags = [_][]const u8{};

    for (file_list) |src| {
        const ext = std.fs.path.extension(src);
        if (std.mem.eql(u8, ext, ".c")) {
            lib.addCSourceFile(src, &flags);
        } else {
            lib.addCSourceFile(src, &flags);
        }
    }
}

/// Returns the include path for the Assimp library.
pub fn getIncludePaths(sdk: *Sdk) []const []const u8 {
    _ = sdk;
    const T = struct {
        const paths = [_][]const u8{
            sdkPath("/include"),
            sdkPath("/vendor/assimp/include"),
        };
    };
    return &T.paths;
}

/// Adds Assimp to the given `target`, using both `build_mode` and `target` from it.
/// Will link dynamically or statically depending on linkage.
pub fn addTo(sdk: *Sdk, target: *std.Build.Step, linkage: std.Build.Step.Linkage, formats: FormatSet) void {
    const lib = sdk.createLibrary(linkage, formats);
    lib.setTarget(target.target);
    lib.setBuildMode(target.build_mode);
    target.linkLibrary(lib);
    for (sdk.getIncludePaths()) |path| {
        target.addIncludePath(path);
    }
}

pub const Format = enum {
    @"3DS",
    @"3MF",
    @"AC",
    @"AMF",
    @"ASE",
    @"Assbin",
    @"Assjson",
    @"Assxml",
    @"B3D",
    @"Blender",
    @"BVH",
    @"C4D",
    @"COB",
    @"Collada",
    @"CSM",
    @"DXF",
    @"FBX",
    @"glTF",
    @"glTF2",
    @"HMP",
    @"IFC",
    @"Irr",
    @"LWO",
    @"LWS",
    @"M3D",
    @"MD2",
    @"MD3",
    @"MD5",
    @"MDC",
    @"MDL",
    @"MMD",
    @"MS3D",
    @"NDO",
    @"NFF",
    @"Obj",
    @"OFF",
    @"Ogre",
    @"OpenGEX",
    @"Ply",
    @"Q3BSP",
    @"Q3D",
    @"Raw",
    @"SIB",
    @"SMD",
    @"Step",
    @"STEPParser",
    @"STL",
    @"Terragen",
    @"Unreal",
    @"X",
    @"X3D",
    @"XGL",
};

pub const FormatSet = struct {
    pub const empty = std.mem.zeroes(FormatSet);

    pub const all = blk: {
        var set = empty;
        inline for (std.meta.fields(FormatSet)) |fld| {
            @field(set, fld.name) = true;
        }
        break :blk set;
    };

    pub const default = all
    // problems with rapidjson
        .remove(.glTF)
        .remove(.glTF2)
    // complex build
        .remove(.X3D)
    // propietary code:
        .remove(.C4D);

    pub fn add(set: FormatSet, format: Format) FormatSet {
        var copy = set;
        inline for (std.meta.fields(FormatSet)) |fld| {
            if (std.mem.eql(u8, fld.name, @tagName(format))) {
                @field(copy, fld.name) = true;
            }
        }
        return copy;
    }

    pub fn remove(set: FormatSet, format: Format) FormatSet {
        var copy = set;
        inline for (std.meta.fields(FormatSet)) |fld| {
            if (std.mem.eql(u8, fld.name, @tagName(format))) {
                @field(copy, fld.name) = false;
            }
        }
        return copy;
    }

    @"3DS": bool,
    @"3MF": bool,
    @"AC": bool,
    @"AMF": bool,
    @"ASE": bool,
    @"Assbin": bool,
    @"Assjson": bool,
    @"Assxml": bool,
    @"B3D": bool,
    @"Blender": bool,
    @"BVH": bool,
    @"C4D": bool,
    @"COB": bool,
    @"Collada": bool,
    @"CSM": bool,
    @"DXF": bool,
    @"FBX": bool,
    @"glTF": bool,
    @"glTF2": bool,
    @"HMP": bool,
    @"IFC": bool,
    @"Irr": bool,
    @"LWO": bool,
    @"LWS": bool,
    @"M3D": bool,
    @"MD2": bool,
    @"MD3": bool,
    @"MD5": bool,
    @"MDC": bool,
    @"MDL": bool,
    @"MMD": bool,
    @"MS3D": bool,
    @"NDO": bool,
    @"NFF": bool,
    @"Obj": bool,
    @"OFF": bool,
    @"Ogre": bool,
    @"OpenGEX": bool,
    @"Ply": bool,
    @"Q3BSP": bool,
    @"Q3D": bool,
    @"Raw": bool,
    @"SIB": bool,
    @"SMD": bool,
    @"Step": bool,
    @"STEPParser": bool,
    @"STL": bool,
    @"Terragen": bool,
    @"Unreal": bool,
    @"X": bool,
    @"X3D": bool,
    @"XGL": bool,
};

const sources = struct {
    const src_root = assimpPath("/code");

    const common = [_][]const u8{
        src_root ++ "/CApi/AssimpCExport.cpp",
        src_root ++ "/CApi/CInterfaceIOWrapper.cpp",
        src_root ++ "/Common/AssertHandler.cpp",
        src_root ++ "/Common/Assimp.cpp",
        src_root ++ "/Common/BaseImporter.cpp",
        src_root ++ "/Common/BaseProcess.cpp",
        src_root ++ "/Common/Bitmap.cpp",
        src_root ++ "/Common/CreateAnimMesh.cpp",
        src_root ++ "/Common/DefaultIOStream.cpp",
        src_root ++ "/Common/DefaultIOSystem.cpp",
        src_root ++ "/Common/DefaultLogger.cpp",
        src_root ++ "/Common/Exceptional.cpp",
        src_root ++ "/Common/Exporter.cpp",
        src_root ++ "/Common/Importer.cpp",
        src_root ++ "/Common/ImporterRegistry.cpp",
        src_root ++ "/Common/material.cpp",
        src_root ++ "/Common/PostStepRegistry.cpp",
        src_root ++ "/Common/RemoveComments.cpp",
        src_root ++ "/Common/scene.cpp",
        src_root ++ "/Common/SceneCombiner.cpp",
        src_root ++ "/Common/ScenePreprocessor.cpp",
        src_root ++ "/Common/SGSpatialSort.cpp",
        src_root ++ "/Common/simd.cpp",
        src_root ++ "/Common/SkeletonMeshBuilder.cpp",
        src_root ++ "/Common/SpatialSort.cpp",
        src_root ++ "/Common/StandardShapes.cpp",
        src_root ++ "/Common/Subdivision.cpp",
        src_root ++ "/Common/TargetAnimation.cpp",
        src_root ++ "/Common/Version.cpp",
        src_root ++ "/Common/VertexTriangleAdjacency.cpp",
        src_root ++ "/Common/ZipArchiveIOSystem.cpp",
        src_root ++ "/Material/MaterialSystem.cpp",
        src_root ++ "/Pbrt/PbrtExporter.cpp",
        src_root ++ "/PostProcessing/ArmaturePopulate.cpp",
        src_root ++ "/PostProcessing/CalcTangentsProcess.cpp",
        src_root ++ "/PostProcessing/ComputeUVMappingProcess.cpp",
        src_root ++ "/PostProcessing/ConvertToLHProcess.cpp",
        src_root ++ "/PostProcessing/DeboneProcess.cpp",
        src_root ++ "/PostProcessing/DropFaceNormalsProcess.cpp",
        src_root ++ "/PostProcessing/EmbedTexturesProcess.cpp",
        src_root ++ "/PostProcessing/FindDegenerates.cpp",
        src_root ++ "/PostProcessing/FindInstancesProcess.cpp",
        src_root ++ "/PostProcessing/FindInvalidDataProcess.cpp",
        src_root ++ "/PostProcessing/FixNormalsStep.cpp",
        src_root ++ "/PostProcessing/GenBoundingBoxesProcess.cpp",
        src_root ++ "/PostProcessing/GenFaceNormalsProcess.cpp",
        src_root ++ "/PostProcessing/GenVertexNormalsProcess.cpp",
        src_root ++ "/PostProcessing/ImproveCacheLocality.cpp",
        src_root ++ "/PostProcessing/JoinVerticesProcess.cpp",
        src_root ++ "/PostProcessing/LimitBoneWeightsProcess.cpp",
        src_root ++ "/PostProcessing/MakeVerboseFormat.cpp",
        src_root ++ "/PostProcessing/OptimizeGraph.cpp",
        src_root ++ "/PostProcessing/OptimizeMeshes.cpp",
        src_root ++ "/PostProcessing/PretransformVertices.cpp",
        src_root ++ "/PostProcessing/ProcessHelper.cpp",
        src_root ++ "/PostProcessing/RemoveRedundantMaterials.cpp",
        src_root ++ "/PostProcessing/RemoveVCProcess.cpp",
        src_root ++ "/PostProcessing/ScaleProcess.cpp",
        src_root ++ "/PostProcessing/SortByPTypeProcess.cpp",
        src_root ++ "/PostProcessing/SplitByBoneCountProcess.cpp",
        src_root ++ "/PostProcessing/SplitLargeMeshes.cpp",
        src_root ++ "/PostProcessing/TextureTransform.cpp",
        src_root ++ "/PostProcessing/TriangulateProcess.cpp",
        src_root ++ "/PostProcessing/ValidateDataStructure.cpp",
    };

    const libraries = struct {
        const unzip = [_][]const u8{
            assimpPath("/contrib/unzip/unzip.c"),
            assimpPath("/contrib/unzip/ioapi.c"),
            assimpPath("/contrib/unzip/crypt.c"),
        };
        const zip = [_][]const u8{
            assimpPath("/contrib/zip/src/zip.c"),
        };
        const zlib = [_][]const u8{
            assimpPath("/contrib/zlib/inflate.c"),
            assimpPath("/contrib/zlib/infback.c"),
            assimpPath("/contrib/zlib/gzclose.c"),
            assimpPath("/contrib/zlib/gzread.c"),
            assimpPath("/contrib/zlib/inftrees.c"),
            assimpPath("/contrib/zlib/gzwrite.c"),
            assimpPath("/contrib/zlib/compress.c"),
            assimpPath("/contrib/zlib/inffast.c"),
            assimpPath("/contrib/zlib/uncompr.c"),
            assimpPath("/contrib/zlib/gzlib.c"),
            // assimpRoot() ++ "/contrib/zlib/contrib/testzlib/testzlib.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/inflate86/inffas86.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/masmx64/inffas8664.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/infback9/infback9.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/infback9/inftree9.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/minizip/miniunz.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/minizip/minizip.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/minizip/unzip.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/minizip/ioapi.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/minizip/mztools.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/minizip/zip.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/minizip/iowin32.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/puff/pufftest.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/puff/puff.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/blast/blast.c",
            // assimpRoot() ++ "/contrib/zlib/contrib/untgz/untgz.c",
            assimpPath("/contrib/zlib/trees.c"),
            assimpPath("/contrib/zlib/zutil.c"),
            assimpPath("/contrib/zlib/deflate.c"),
            assimpPath("/contrib/zlib/crc32.c"),
            assimpPath("/contrib/zlib/adler32.c"),
        };
        const poly2tri = [_][]const u8{
            assimpPath("/contrib/poly2tri/poly2tri/common/shapes.cc"),
            assimpPath("/contrib/poly2tri/poly2tri/sweep/sweep_context.cc"),
            assimpPath("/contrib/poly2tri/poly2tri/sweep/advancing_front.cc"),
            assimpPath("/contrib/poly2tri/poly2tri/sweep/cdt.cc"),
            assimpPath("/contrib/poly2tri/poly2tri/sweep/sweep.cc"),
        };
        const clipper = [_][]const u8{
            assimpPath("/contrib/clipper/clipper.cpp"),
        };
        const openddlparser = [_][]const u8{
            assimpPath("/contrib/openddlparser/code/OpenDDLParser.cpp"),
            assimpPath("/contrib/openddlparser/code/OpenDDLExport.cpp"),
            assimpPath("/contrib/openddlparser/code/DDLNode.cpp"),
            assimpPath("/contrib/openddlparser/code/OpenDDLCommon.cpp"),
            assimpPath("/contrib/openddlparser/code/Value.cpp"),
            assimpPath("/contrib/openddlparser/code/OpenDDLStream.cpp"),
        };
    };

    const @"3DS" = [_][]const u8{
        src_root ++ "/AssetLib/3DS/3DSConverter.cpp",
        src_root ++ "/AssetLib/3DS/3DSExporter.cpp",
        src_root ++ "/AssetLib/3DS/3DSLoader.cpp",
    };
    const @"3MF" = [_][]const u8{
        src_root ++ "/AssetLib/3MF/D3MFExporter.cpp",
        src_root ++ "/AssetLib/3MF/D3MFImporter.cpp",
        src_root ++ "/AssetLib/3MF/D3MFOpcPackage.cpp",
        src_root ++ "/AssetLib/3MF/XmlSerializer.cpp",
    };
    const @"AC" = [_][]const u8{
        src_root ++ "/AssetLib/AC/ACLoader.cpp",
    };
    const @"AMF" = [_][]const u8{
        src_root ++ "/AssetLib/AMF/AMFImporter_Geometry.cpp",
        src_root ++ "/AssetLib/AMF/AMFImporter_Material.cpp",
        src_root ++ "/AssetLib/AMF/AMFImporter_Postprocess.cpp",
        src_root ++ "/AssetLib/AMF/AMFImporter.cpp",
    };
    const @"ASE" = [_][]const u8{
        src_root ++ "/AssetLib/ASE/ASELoader.cpp",
        src_root ++ "/AssetLib/ASE/ASEParser.cpp",
    };
    const @"Assbin" = [_][]const u8{
        src_root ++ "/AssetLib/Assbin/AssbinExporter.cpp",
        src_root ++ "/AssetLib/Assbin/AssbinFileWriter.cpp",
        src_root ++ "/AssetLib/Assbin/AssbinLoader.cpp",
    };
    const @"Assjson" = [_][]const u8{
        src_root ++ "/AssetLib/Assjson/cencode.c",
        src_root ++ "/AssetLib/Assjson/json_exporter.cpp",
        src_root ++ "/AssetLib/Assjson/mesh_splitter.cpp",
    };
    const @"Assxml" = [_][]const u8{
        src_root ++ "/AssetLib/Assxml/AssxmlExporter.cpp",
        src_root ++ "/AssetLib/Assxml/AssxmlFileWriter.cpp",
    };
    const @"B3D" = [_][]const u8{
        src_root ++ "/AssetLib/B3D/B3DImporter.cpp",
    };
    const @"Blender" = [_][]const u8{
        src_root ++ "/AssetLib/Blender/BlenderBMesh.cpp",
        src_root ++ "/AssetLib/Blender/BlenderCustomData.cpp",
        src_root ++ "/AssetLib/Blender/BlenderDNA.cpp",
        src_root ++ "/AssetLib/Blender/BlenderLoader.cpp",
        src_root ++ "/AssetLib/Blender/BlenderModifier.cpp",
        src_root ++ "/AssetLib/Blender/BlenderScene.cpp",
        src_root ++ "/AssetLib/Blender/BlenderTessellator.cpp",
    };
    const @"BVH" = [_][]const u8{
        src_root ++ "/AssetLib/BVH/BVHLoader.cpp",
    };
    const @"C4D" = [_][]const u8{
        src_root ++ "/AssetLib/C4D/C4DImporter.cpp",
    };
    const @"COB" = [_][]const u8{
        src_root ++ "/AssetLib/COB/COBLoader.cpp",
    };
    const @"Collada" = [_][]const u8{
        src_root ++ "/AssetLib/Collada/ColladaExporter.cpp",
        src_root ++ "/AssetLib/Collada/ColladaHelper.cpp",
        src_root ++ "/AssetLib/Collada/ColladaLoader.cpp",
        src_root ++ "/AssetLib/Collada/ColladaParser.cpp",
    };
    const @"CSM" = [_][]const u8{
        src_root ++ "/AssetLib/CSM/CSMLoader.cpp",
    };
    const @"DXF" = [_][]const u8{
        src_root ++ "/AssetLib/DXF/DXFLoader.cpp",
    };
    const @"FBX" = [_][]const u8{
        src_root ++ "/AssetLib/FBX/FBXAnimation.cpp",
        src_root ++ "/AssetLib/FBX/FBXBinaryTokenizer.cpp",
        src_root ++ "/AssetLib/FBX/FBXConverter.cpp",
        src_root ++ "/AssetLib/FBX/FBXDeformer.cpp",
        src_root ++ "/AssetLib/FBX/FBXDocument.cpp",
        src_root ++ "/AssetLib/FBX/FBXDocumentUtil.cpp",
        src_root ++ "/AssetLib/FBX/FBXExporter.cpp",
        src_root ++ "/AssetLib/FBX/FBXExportNode.cpp",
        src_root ++ "/AssetLib/FBX/FBXExportProperty.cpp",
        src_root ++ "/AssetLib/FBX/FBXImporter.cpp",
        src_root ++ "/AssetLib/FBX/FBXMaterial.cpp",
        src_root ++ "/AssetLib/FBX/FBXMeshGeometry.cpp",
        src_root ++ "/AssetLib/FBX/FBXModel.cpp",
        src_root ++ "/AssetLib/FBX/FBXNodeAttribute.cpp",
        src_root ++ "/AssetLib/FBX/FBXParser.cpp",
        src_root ++ "/AssetLib/FBX/FBXProperties.cpp",
        src_root ++ "/AssetLib/FBX/FBXTokenizer.cpp",
        src_root ++ "/AssetLib/FBX/FBXUtil.cpp",
    };
    const @"glTF" = [_][]const u8{
        src_root ++ "/AssetLib/glTF/glTFCommon.cpp",
        src_root ++ "/AssetLib/glTF/glTFExporter.cpp",
        src_root ++ "/AssetLib/glTF/glTFImporter.cpp",
    };
    const @"glTF2" = [_][]const u8{
        src_root ++ "/AssetLib/glTF2/glTF2Exporter.cpp",
        src_root ++ "/AssetLib/glTF2/glTF2Importer.cpp",
    };
    const @"HMP" = [_][]const u8{
        src_root ++ "/AssetLib/HMP/HMPLoader.cpp",
    };
    const @"IFC" = [_][]const u8{
        src_root ++ "/AssetLib/IFC/IFCBoolean.cpp",
        src_root ++ "/AssetLib/IFC/IFCCurve.cpp",
        src_root ++ "/AssetLib/IFC/IFCGeometry.cpp",
        src_root ++ "/AssetLib/IFC/IFCLoader.cpp",
        src_root ++ "/AssetLib/IFC/IFCMaterial.cpp",
        src_root ++ "/AssetLib/IFC/IFCOpenings.cpp",
        src_root ++ "/AssetLib/IFC/IFCProfile.cpp",
        // src_root ++ "/AssetLib/IFC/IFCReaderGen_4.cpp", // not used?
        src_root ++ "/AssetLib/IFC/IFCReaderGen1_2x3.cpp",
        src_root ++ "/AssetLib/IFC/IFCReaderGen2_2x3.cpp",
        src_root ++ "/AssetLib/IFC/IFCUtil.cpp",
    };
    const @"Irr" = [_][]const u8{
        src_root ++ "/AssetLib/Irr/IRRLoader.cpp",
        src_root ++ "/AssetLib/Irr/IRRMeshLoader.cpp",
        src_root ++ "/AssetLib/Irr/IRRShared.cpp",
    };
    const @"LWO" = [_][]const u8{
        src_root ++ "/AssetLib/LWO/LWOAnimation.cpp",
        src_root ++ "/AssetLib/LWO/LWOBLoader.cpp",
        src_root ++ "/AssetLib/LWO/LWOLoader.cpp",
        src_root ++ "/AssetLib/LWO/LWOMaterial.cpp",
        src_root ++ "/AssetLib/LWS/LWSLoader.cpp",
    };
    const @"LWS" = [_][]const u8{
        src_root ++ "/AssetLib/M3D/M3DExporter.cpp",
        src_root ++ "/AssetLib/M3D/M3DImporter.cpp",
        src_root ++ "/AssetLib/M3D/M3DWrapper.cpp",
    };
    const @"M3D" = [_][]const u8{};
    const @"MD2" = [_][]const u8{
        src_root ++ "/AssetLib/MD2/MD2Loader.cpp",
    };
    const @"MD3" = [_][]const u8{
        src_root ++ "/AssetLib/MD3/MD3Loader.cpp",
    };
    const @"MD5" = [_][]const u8{
        src_root ++ "/AssetLib/MD5/MD5Loader.cpp",
        src_root ++ "/AssetLib/MD5/MD5Parser.cpp",
    };
    const @"MDC" = [_][]const u8{
        src_root ++ "/AssetLib/MDC/MDCLoader.cpp",
    };
    const @"MDL" = [_][]const u8{
        src_root ++ "/AssetLib/MDL/HalfLife/HL1MDLLoader.cpp",
        src_root ++ "/AssetLib/MDL/HalfLife/UniqueNameGenerator.cpp",
        src_root ++ "/AssetLib/MDL/MDLLoader.cpp",
        src_root ++ "/AssetLib/MDL/MDLMaterialLoader.cpp",
    };
    const @"MMD" = [_][]const u8{
        src_root ++ "/AssetLib/MMD/MMDImporter.cpp",
        src_root ++ "/AssetLib/MMD/MMDPmxParser.cpp",
    };
    const @"MS3D" = [_][]const u8{
        src_root ++ "/AssetLib/MS3D/MS3DLoader.cpp",
    };
    const @"NDO" = [_][]const u8{
        src_root ++ "/AssetLib/NDO/NDOLoader.cpp",
    };
    const @"NFF" = [_][]const u8{
        src_root ++ "/AssetLib/NFF/NFFLoader.cpp",
    };
    const @"Obj" = [_][]const u8{
        src_root ++ "/AssetLib/Obj/ObjExporter.cpp",
        src_root ++ "/AssetLib/Obj/ObjFileImporter.cpp",
        src_root ++ "/AssetLib/Obj/ObjFileMtlImporter.cpp",
        src_root ++ "/AssetLib/Obj/ObjFileParser.cpp",
    };
    const @"OFF" = [_][]const u8{
        src_root ++ "/AssetLib/OFF/OFFLoader.cpp",
    };
    const @"Ogre" = [_][]const u8{
        src_root ++ "/AssetLib/Ogre/OgreBinarySerializer.cpp",
        src_root ++ "/AssetLib/Ogre/OgreImporter.cpp",
        src_root ++ "/AssetLib/Ogre/OgreMaterial.cpp",
        src_root ++ "/AssetLib/Ogre/OgreStructs.cpp",
        src_root ++ "/AssetLib/Ogre/OgreXmlSerializer.cpp",
    };
    const @"OpenGEX" = [_][]const u8{
        src_root ++ "/AssetLib/OpenGEX/OpenGEXExporter.cpp",
        src_root ++ "/AssetLib/OpenGEX/OpenGEXImporter.cpp",
    };
    const @"Ply" = [_][]const u8{
        src_root ++ "/AssetLib/Ply/PlyExporter.cpp",
        src_root ++ "/AssetLib/Ply/PlyLoader.cpp",
        src_root ++ "/AssetLib/Ply/PlyParser.cpp",
    };
    const @"Q3BSP" = [_][]const u8{
        src_root ++ "/AssetLib/Q3BSP/Q3BSPFileImporter.cpp",
        src_root ++ "/AssetLib/Q3BSP/Q3BSPFileParser.cpp",
    };
    const @"Q3D" = [_][]const u8{
        src_root ++ "/AssetLib/Q3D/Q3DLoader.cpp",
    };
    const @"Raw" = [_][]const u8{
        src_root ++ "/AssetLib/Raw/RawLoader.cpp",
    };
    const @"SIB" = [_][]const u8{
        src_root ++ "/AssetLib/SIB/SIBImporter.cpp",
    };
    const @"SMD" = [_][]const u8{
        src_root ++ "/AssetLib/SMD/SMDLoader.cpp",
    };
    const @"Step" = [_][]const u8{
        src_root ++ "/AssetLib/Step/StepExporter.cpp",
    };
    const @"STEPParser" = [_][]const u8{
        src_root ++ "/AssetLib/STEPParser/STEPFileEncoding.cpp",
        src_root ++ "/AssetLib/STEPParser/STEPFileReader.cpp",
    };
    const @"STL" = [_][]const u8{
        src_root ++ "/AssetLib/STL/STLExporter.cpp",
        src_root ++ "/AssetLib/STL/STLLoader.cpp",
    };
    const @"Terragen" = [_][]const u8{
        src_root ++ "/AssetLib/Terragen/TerragenLoader.cpp",
    };
    const @"Unreal" = [_][]const u8{
        src_root ++ "/AssetLib/Unreal/UnrealLoader.cpp",
    };
    const @"X" = [_][]const u8{
        src_root ++ "/AssetLib/X/XFileExporter.cpp",
        src_root ++ "/AssetLib/X/XFileImporter.cpp",
        src_root ++ "/AssetLib/X/XFileParser.cpp",
    };
    const @"X3D" = [_][]const u8{
        src_root ++ "/AssetLib/X3D/X3DExporter.cpp",
        src_root ++ "/AssetLib/X3D/X3DImporter.cpp",
    };
    const @"XGL" = [_][]const u8{
        src_root ++ "/AssetLib/XGL/XGLLoader.cpp",
    };
};
