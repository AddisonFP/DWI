%% Dicom Loader Debugginer

addpath(genpath('/v/raid10/users/sjohnson/Matlab Code/Packages/'));
addpath(genpath('/v/raid10/users/sjohnson/Matlab Code/MedImageReslicer/'));

datadir = '/v/raid10/users/hodeen/2023/2023-02-09_DWI/DicomData/';


testfiles =  {'s000008 DWI2D_RF_iPAT_COR_4b_rabbitprotocol_TRACEW_DFC';
    's000014 DWI2D_RF_iPATr3_COR_4b_rabbitprotocol_TRACEW_DFC';
    's000016 fl3d_SEK_Mb_b50_100_840_QfatsatAndSatbands';
    's000034 fl3d_SEK020823_b50_100_840_FatSat Off _MELV2'}

for f = 2:length(testfiles)
    [DICOM, metadata, DicomHeader1] = loadDicomSliceInfo(datadir,testfiles{f});
    save([workdir testfiles{f} '_v2.mat'], 'DICOM','metadata','DicomHeader1'); 
    display(testfiles{f});
    display(size(DICOM));
end 

%%
for f = 1:length(testfiles)
     [imge, PosDCS, PosPCS, geomInfo] = load_image_DICOM(datadir, testfiles{f}, workdir);
end 

%%

datadir = '/System/Volumes/Data/v/raid10/animal_data/IACUC20-10004/R20-087/20201112120940MR HIFU^Allison/DicomData/';

fname = 's000010 segEPI_HIFU11c_Heat10_30s_45pct_x0yN2z10mm';
[DICOM, metadata, DicomHeader1] = loadDicomSliceInfo(datadir,fname);
