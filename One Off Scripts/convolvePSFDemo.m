% Take in an image, convolve with a PSF
% 
% dataDir = '';
% dataName = 'test2.png';
% pixSize = 2250/(330-50);            % indices/nm
% psfRad = 700;                       % in nm
% 
% % Load data, convolve
% gKern = psfRad*pixSize;
% 
% ogImg = imread(fullfile(dataDir,dataName));

%% Generate data from scratch
pixSize = 10;
pixelRange = 0:10:6000;     % nm
MTLen = 3000;               % nm
noiseFrac = .1;
numFils = 50;
MTWidth = 20;

baseMat = zeros(numel(pixelRange),numel(pixelRange),3);
randLens = 3000*(1 + (rand(1,numFils)*noiseFrac));
randOris = rand(1,numFils)*(pi);
randInds = round(rand(1,numFils)*numel(baseMat));
[comY,comX] = ind2sub(size(baseMat),randInds);
randCoMs = [comX;comY];
[bbX, bbY] = filBackBones2D(randCoMs, randLens, randOris);

% Store coordinates of all filaments for scaled matrix (i,j)
allCoords = -ones(numFils,numel(pixelRange),2);
scaledLens = randLens/pixSize;
for currFil = 1:numel(randLens)
    currCoords = zeros(round(scaledLens(currFil)),2);
    for currDim = 1:3
        currCoords(:,currDim) = linspace(bbX(currFil),bbY(currFil),round(scaledLens(currFil)));
        % Bound coords to positive definite values
        currCoords(:,currDim) = min(numel(pixelRange),mod1b(currCoords(:,currDim),numel(pixelRange)));
    end
    keptCoords = unique(round(currCoords),'rows');
    numKept = size(keptCoords,1);
    allCoords(currFil,1:numKept,:) = keptCoords;
end


%%
% Construct matrix
for index = 1:numFils

    currMat = zeros(numel(pixelRange),numel(pixelRange));



end



