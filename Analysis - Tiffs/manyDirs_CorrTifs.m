%% Correct 3D tifs and scale in preparation for segmentation
% Expected to run after corr3DTif_Simplify.m
% For each directory, must contain a "TotalCorrectionMatrix.tif" as well as
% separated tifs in a sub-folder named '0 Raw Tifs' and a metadata.m file
% with appropriate parameters saved (also from above script)
% 2026-01-22 - Rémi Boros

% baseDirs = {'<redacted original absolute path>',...
baseDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 5',...
    };

nameAppends = {'_E1', '_E2', '_E3', '', '_E5'};
rawName = 'Time%06i_raw560%s.tif';

rawDir = '0 Raw Tifs';
ilastikDir = '2 Downscaled For Ilastik 8bit';
corrDir = '3 Illumination Bleach Corrected 16bit';
corrMatName = 'TotalCorrectionMatrix.tif';

tRange = 1:100;

%%  Iterate through directories, correct tifs

for dirInd = 1:numel(baseDirs)
    
    % Define directory info
    currDir = baseDirs{dirInd}; currAppend = nameAppends{dirInd};
    corrDir8bit = fullfile(currDir,ilastikDir);
    corrDirBleach = fullfile(currDir,corrDir);
    rawSubDir = fullfile(currDir,rawDir);
    % Load variables and correction matrix
    load(fullfile(currDir,'metadata.mat'));
    totalCorrSC = double(tiffreadVolume(fullfile(currDir,corrMatName)));
    totalCorr = totalCorrSC / (matIntT1/matVol);

    % Iterate through time and save ill. corr. rescaled images
    for tInd = 1:numel(tRange)
        currT = tRange(tInd);
        % Load data
        if exist(fullfile(rawSubDir,sprintf(rawName,currT,currAppend)),'file')
            currTif = tiffreadVolume(fullfile(rawSubDir,sprintf(rawName,currT,currAppend)));
            currImg = double(cropTiffSave(currTif, cropCorner, winSize, 0));
        else
            continue
        end
        % Correct for bleaching
        blchScale = matIntT1/sum(currImg(:));
        % Apply correction matrix
        corrImg = currImg./totalCorr*blchScale;
        % Rescale for Ilastik 
        currCorr8bit = max(0, corrImg - cutOffs8bit(1))*255/abs(diff(cutOffs8bit));
        rs8Bit = imresize3(currCorr8bit,round(size(corrImg).*ilastikTrainRescale));
        % Save data
        save3DTiff(uint8(rs8Bit), fullfile(corrDir8bit, sprintf(corrName8bit, currT)));
        save3DTiff(cast(corrImg,tifClass), fullfile(corrDirBleach, sprintf(corrNameBleach, currT)));
    end
end


