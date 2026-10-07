% I made a mistake and stored MinAxStats inconsistently in statStruct
% object when running blobPropsFromTrajs_R_Inertia.m prior to 
% 2026-04-29. Loads, iterates through, corrects, and saves structures.
% 2026-04-29 - Rémi Boros

% baseDirs = {'<redacted original absolute path>',...
baseDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};
fileName = 'trajSorted_RMin_Anisotropy.mat';

%% Iterate through each directory, then through each index and correct

for index = 1:numel(baseDirs)

    dataDir = baseDirs{index};
    load(fullfile(dataDir,fileName));
    temp = statStruct;
    for objInd = 1:numel(statStruct)
        currEntry = statStruct(objInd).MinAxStats;

        if size(currEntry,2) > size(currEntry,1)
            statStruct(objInd).MinAxStats = currEntry';
        end

    end
    save(fullfile(dataDir,fileName),'statStruct');
end