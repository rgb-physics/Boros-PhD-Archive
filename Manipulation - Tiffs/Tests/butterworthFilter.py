import skimage
from skimage import filters  
import numpy as np
# Apply butterworth
def butterFiltPy3D(dataMat, cutOffFreq, slopeOrd, padVal, hpBool):
    dataMat = np.asarray(dataMat)
    filtData = filters.butterworth(dataMat, cutoff_frequency_ratio=cutOffFreq, high_pass=(hpBool == 1), order=slopeOrd, channel_axis=None, squared_butterworth=True, npad=int(padVal))
    filtDataMat = np.array(filtData).T; #Convert to contiguous array
    return filtDataMat
# Run function
filtData = butterFiltPy3D(dataMat, cutOffFreq, slopeOrd, padVal, hpBool)