% Combine two channels by renormalizing, then putting chan 1 in 1-32k and
% chan 2in 32k-65k. Used to display MTs and K4 in Paraview
% 2025-07-14 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName1 = 'T240_carved_488.tif';
dataName2 = 'T240_carved_560.tif';

modeCut = 5000;

%% Split 

img1 = double(tiffreadVolume(fullfile(dataDir,dataName1)));
img2 = double(tiffreadVolume(fullfile(dataDir,dataName2)));
% 
mode1 = mode(img1(img1>modeCut));
mode2 = mode(img2(img2>modeCut));

test1 = img1>mode1;
test2 = img2>mode2;

temp = img1/mode1 > img2/mode2;

%% Manual
strelObj = strel('sphere',1);
mask1 = (imgaussfilt3(img1,2) > 10800);
% mask1 = (imdilate(imerode(img1 > 11000,strelObj),strelObj));
