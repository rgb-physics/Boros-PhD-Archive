%% super silly pad images

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataName = 'ogLUTT%03i.png';

selTimes = [40 110];
scaleHeight = 1.14;
zFrac = scaleHeight/1.81;

padH = .41/scaleHeight;

avgLen = 100;
startX = 300;
zPix = 1/3.7;

%% 

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currImg = imread(fullfile(dataDir,sprintf(dataName,currT)));
    zSize = size(currImg,1);
    zRange = round(1:zSize*zFrac);
    zPadded = zeros(round(numel(zRange).*(1+padH)), size(currImg,2));
    zPadded(end-zRange,:) = flipud(currImg(zRange,:));

    currProfile = mean(zPadded(:,startX+(1:avgLen)),2);
    figure
    plot(currProfile,((1:size(zPadded,1)) - round(numel(zRange).*(padH)))*zPix,'black','LineWidth',2);

end