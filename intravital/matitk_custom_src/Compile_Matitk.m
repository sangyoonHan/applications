% compile mex file
% Compile_Matitk( 'C:\deepak\software_libraries\ITK-4.1.0\', 'C:\deepak\software_libraries\ITK-4.1.0\bin', pwd )

function Compile_Matitk( itksrc, itkbin, mexoutdir, flagDebugMode )

[ mfilepath, name, ext ] = fileparts( mfilename('fullpath') );

if ~exist( 'itksrc', 'var' )
    itksrc = uigetdir( 'C:' , 'Set ITK Source Directory' );
end

if ~exist( 'itkbin', 'var')
    itkbin = uigetdir( itksrc , 'Set ITK Bin Directory' );
end

if ~exist( 'mexoutdir', 'var')
    mexoutdir = uigetdir( mfilepath , 'Select output directory for the generated mex file (matitk_custom.mex*)' );
end

if ~exist( 'flagDebugMode', 'var' )
    flagDebugMode = false;
end

if flagDebugMode
    compiler_opt_flag = ' -g ';
    itklibdir = fullfile(itkbin,'\lib\debug\ ');
else
    compiler_opt_flag = ' -O ';
    itklibdir = fullfile(itkbin,'\lib\release\ ');
end

% Make sure you build ITK with /bigobj (if you are using cmake to build itk then 
% you can set this by adding it to CMAKE_CXX_FLAGS in advanced mode)
if strfind( computer('arch'), 'win' )
    compiler_opt_flag = [ ' COMPFLAGS="$COMPFLAGS /bigobj" ', compiler_opt_flag ];
end

% itksrc = 'C:\ITK\ITK-3.20.0';
% itkbin = 'C:\ITK\ITK-3.20.0_bin_vs05_cmk2.8.2';
% mexoutdir = pwd;

str_mex_cmd = ['mex -largeArrayDims -v ' compiler_opt_flag...    
    '-I' fullfile(itksrc, 'Modules/Bridge/VTK/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Compatibility/Deprecated/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/Common/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/FiniteDifference/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/ImageAdaptors/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/ImageFunction/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/Mesh/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/QuadEdgeMesh/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/SpatialObjects/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/TestKernel/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Core/Transform/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/AnisotropicSmoothing/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/AntiAlias/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/BiasCorrection/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/BinaryMathematicalMorphology/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/Colormap/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/Convolution/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/CurvatureFlow/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/Deconvolution/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/DiffusionTensorImage/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/DisplacementField/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/DistanceMap/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/FFT/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/FastMarching/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageCompare/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageCompose/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageFeature/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageFilterBase/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageFusion/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageGradient/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageGrid/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageIntensity/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageLabel/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageSource/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/ImageStatistics/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/LabelMap/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/MathematicalMorphology/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/Path/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/QuadEdgeMeshFiltering/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/Smoothing/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/SpatialFunction/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Filtering/Thresholding/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/BMP/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/BioRad/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/CSV/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/GDCM/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/GE/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/GIPL/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/HDF5/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/IPL/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/ImageBase/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/JPEG/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/LSM/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/Mesh/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/Meta/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/NIFTI/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/NRRD/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/PNG/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/RAW/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/Siemens/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/SpatialObjects/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/Stimulate/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/TIFF/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/TransformBase/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/TransformHDF5/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/TransformInsightLegacy/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/TransformMatlab/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/VTK/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/IO/XML/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Nonunit/Review/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/Eigen/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/FEM/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/NarrowBand/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/NeuralNetworks/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/Optimizers/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/Optimizersv4/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/Polynomials/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Numerics/Statistics/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Registration/Common/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Registration/FEM/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Registration/Metricsv4/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Registration/PDEDeformable/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Registration/RegistrationMethodsv4/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/BioCell/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/Classifiers/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/ConnectedComponents/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/DeformableMesh/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/KLMRegionGrowing/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/LabelVoting/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/LevelSets/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/LevelSetsv4/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/MarkovRandomFieldsClassifiers/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/RegionGrowing/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/SignedDistanceFunction/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/Voronoi/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Segmentation/Watersheds/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/DICOMParser/src/DICOMParser  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/Expat/src/expat  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GDCM/src/gdcm/Source/Common  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GDCM/src/gdcm/Source/DataDictionary  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GDCM/src/gdcm/Source/DataStructureAndEncodingDefinition  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GDCM/src/gdcm/Source/InformationObjectDefinition  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GDCM/src/gdcm/Source/MediaStorageAndFileFormat  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GDCM/src/gdcm/Source/MessageExchangeDefinition  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GDCM/src/gdcm/Utilities/C99  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/GIFTI/src/gifticlib  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/HDF5/src  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/JPEG/src  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/MetaIO/src/MetaIO  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/NIFTI/src/nifti/niftilib  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/NIFTI/src/nifti/znzlib  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/NrrdIO/src/NrrdIO  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/OpenJPEG/src/openjpeg  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/PNG/src  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/TIFF/src  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/VNL/src/vxl/core  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/VNL/src/vxl/v3p/netlib  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/VNL/src/vxl/vcl  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/VNLInstantiation/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/ThirdParty/ZLIB/src  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Video/Core/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Video/Filtering/include  ' ) ...
    '-I' fullfile(itksrc, 'Modules/Video/IO/include  ' ) ...   
    '-I' fullfile(itkbin, 'Modules/Core/Common  ') ...
    '-I' fullfile(itkbin, 'Modules/IO/ImageBase  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/DICOMParser/src/DICOMParser  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/Expat/src/expat  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/GDCM  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/GDCM/src/gdcm/Source/Common  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/HDF5/src  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/JPEG/src  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/KWSys/src  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/MetaIO/src/MetaIO  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/Netlib  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/NrrdIO/src/NrrdIO  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/OpenJPEG/src/openjpeg  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/PNG/src  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/TIFF/src  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/TIFF/src/itktiff  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/VNL/src/vxl/core  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/VNL/src/vxl/v3p/netlib  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/VNL/src/vxl/vcl  ') ...
    '-I' fullfile(itkbin, 'Modules/ThirdParty/ZLIB/src  ') ...  
    '-litksys-4.1 ' ...
    '-litkvnl_algo-4.1 ' ...
    '-litkvnl-4.1 ' ...
    '-litkv3p_netlib-4.1 ' ...
    '-lITKCommon-4.1 ' ...
    '-litkNetlibSlatec-4.1 ' ...
    '-lITKStatistics-4.1 ' ...
    '-lITKIOImageBase-4.1 ' ...
    '-lITKIOBMP-4.1 ' ...
    '-lITKIOBioRad-4.1 ' ...
    '-lITKEXPAT-4.1 ' ...
    '-litkopenjpeg-4.1 ' ...
    '-litkzlib-4.1 ' ...
    '-litkgdcmDICT-4.1 ' ...
    '-litkgdcmMSFF-4.1 ' ...
    '-lITKIOGDCM-4.1 ' ...
    '-lITKIOGIPL-4.1 ' ...
    '-litkjpeg-4.1 ' ...
    '-lITKIOJPEG-4.1 ' ...
    '-litktiff-4.1 ' ...
    '-lITKIOTIFF-4.1 ' ...
    '-lITKIOLSM-4.1 ' ...
    '-lITKMetaIO-4.1 ' ...
    '-lITKIOMeta-4.1 ' ...
    '-lITKznz-4.1 ' ...
    '-lITKniftiio-4.1 ' ...
    '-lITKIONIFTI-4.1 ' ...
    '-lITKNrrdIO-4.1 ' ...
    '-lITKIONRRD-4.1 ' ...
    '-litkpng-4.1 ' ...
    '-lITKIOPNG-4.1 ' ...
    '-lITKIOStimulate-4.1 ' ...
    '-lITKIOVTK-4.1 ' ...
    '-lITKMesh-4.1 ' ...
    '-lITKSpatialObjects-4.1 ' ...
    '-lITKPath-4.1 ' ...
    '-lITKLabelMap-4.1 ' ...
    '-lITKQuadEdgeMesh-4.1 ' ...
    '-lITKOptimizers-4.1 ' ...
    '-lITKPolynomials-4.1 ' ...
    '-lITKBiasCorrection-4.1 ' ...
    '-lITKBioCell-4.1 ' ...
    '-lITKDICOMParser-4.1 ' ...
    '-lITKIOXML-4.1 ' ...
    '-lITKIOSpatialObjects-4.1 ' ...
    '-lITKFEM-4.1 ' ...
    '-lITKIOIPL-4.1 ' ...
    '-lITKIOGE-4.1 ' ...
    '-lITKIOSiemens-4.1 ' ...
    '-lITKKLMRegionGrowing-4.1 ' ...
    '-lITKVTK-4.1 ' ...
    '-lITKWatersheds-4.1 ' ...
    '-lITKDeprecated-4.1 ' ...
    '-lITKgiftiio-4.1 ' ...
    '-lITKIOMesh-4.1 ' ...
    '-litkhdf5_cpp-4.1 ' ...
    '-litkhdf5-4.1 ' ...
    '-lITKIOCSV-4.1 ' ...
    '-lITKIOHDF5-4.1 ' ...
    '-lITKIOTransformBase-4.1 ' ...
    '-lITKIOTransformHDF5-4.1 ' ...
    '-lITKIOTransformInsightLegacy-4.1 ' ...
    '-lITKIOTransformMatlab-4.1 ' ...
    '-lITKOptimizersv4-4.1 ' ...
    '-lITKReview-4.1 ' ...
    '-lITKVideoCore-4.1 ' ...
    '-lITKVideoIO-4.1 ' ...
    '-litkgdcmIOD-4.1 ' ...
    '-litkgdcmDSED-4.1 ' ...
    '-litkgdcmCommon-4.1 ' ...
    '-litkgdcmjpeg8-4.1 ' ...
    '-litkgdcmjpeg12-4.1 ' ...
    '-litkgdcmjpeg16-4.1 ' ...
    '-L' itklibdir ...    
    'matitk_custom.cxx ' ...
    '-output ' fullfile( mexoutdir , 'matitk_custom' ) ];

	str_mex_cmd
	
	eval( str_mex_cmd );
    
return
