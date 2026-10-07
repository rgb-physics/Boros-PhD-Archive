function [CC] = pixIDStruct2CC(conn,imgSize,numObjs, pixInds)
%PIXIDSTRUCT2CC Converts a structure of indices into a connected
%components object with desired Connectivity, Image Size, and number of
%objects

CC = struct();
CC.Connectivity = conn;
CC.ImageSize = imgSize;
CC.NumObjects = numObjs;
CC.PixelIdxList = pixInds;

end

