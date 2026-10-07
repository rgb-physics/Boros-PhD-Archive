function [totTable] = getTrajObjTimeTable(trajStruct)
%GETTRAJOBJTIMETABLE Takes in a structure of trajectory info TRAJSTRUCT with
%a field TRAJINDS, each containing an Nx2 array of object IDs and times at
%which the object is recorded. The function returns a table of vectors,
%each corresponding to the time, object ID, and trajcetory ID

%Count number of objects in each trajectory
allInds = vertcat(trajStruct.TrajInds);
trajLens = [0 cellfun(@numel, {trajStruct.TrajInds})/2];
trajStartInds = arrayfun(@(x) sum(trajLens(1:x)), 1:numel(trajLens));

%Generate vector of trajectory IDs
trajIDVec = ones(numel(allInds)/2,1);
for currTraj = 1:numel(trajStruct)
    currRange = (trajStartInds(currTraj)+1):trajStartInds(currTraj+1);
    trajIDVec(currRange) = trajIDVec(currRange)*currTraj;
end

%Sort vectors based on time
ogTimes = allInds(:,2);
[Time,timeOrder] = sort(ogTimes);
ObjectID = allInds(timeOrder,1);
TrajectoryID = trajIDVec(timeOrder);

%Save in table
totTable = table(Time, ObjectID, TrajectoryID);

end

