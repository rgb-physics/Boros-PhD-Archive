%%

% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = 'JCB_202007209_V3.mp4';
% saveDir = '<redacted original absolute path>';
saveDir = '';

%%

temp = VideoReader(fullfile(dataDir,dataName));
storeMat = [];
index = 0;
while hasFrame(temp)
    index = index + 1;
    storeMat(:,:,:,end) =  readFrame(temp);
    save3DTiff(uint8(storeMat(:,:,:,end)),fullfile(saveDir,sprintf('Frame%06i.tif',index)));
end

% stack = 