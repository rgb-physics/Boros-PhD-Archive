%% Take in .avi or .mp4, crop, save
% 2025-06-18 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = 'LSA-2022-01540_V1.webm';
% saveDir = '<redacted original absolute path>';
saveDir = '';

vidObj = VideoReader(fullfile(dataDir,dataName));
xRng = 701:1400;
yRng = 1:700;

nextT = 1;
% Iterate over time, load each frame, crop, save
while hasFrame(vidObj)

    currFrame = readFrame(vidObj);
    cropFrame = currFrame(yRng,xRng,:);
    imwrite(cropFrame, fullfile(saveDir,sprintf('Frame%03i.png',nextT)));
    nextT = nextT + 1;

end

fclose all;
