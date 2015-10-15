#!/bin/sh
# set -e
BASE=$PWD
cd $BASE

# 1d tube parameters
N=100
NCOARSE=100
ML=1 # multi-level, i.e., manifold mapping


# coupling parameters
PPNAME=s-iqn-ils
CP=serial-implicit
PP=IQN-ILS

REUSED=0

FILTER=QR1-filter
EPS=1e-13

# ------------------------------------------------------------------------------------------------------------

if [ ${ML} = 0 ]; then
    if [ ${CP} = "serial-implicit" ]; then
        cp preCICE_S.xml preCICE.xml 
    else
        cp preCICE_V.xml preCICE.xml 
    fi
else
    if [ ${CP} = "serial-implicit" ]; then
        cp MM_preCICE_S.xml preCICE.xml 
    else
        cp MM_preCICE_V.xml preCICE.xml 
    fi
fi

FILE=preCICE.xml
DEST_DIR=experimens/${PPNAME}/



sed -i s/singularity-limit\ value=\"[0-9e]*\"/singularity-limit\ value=\"$EPS\"/g ${FILE}
# change parameter in config (timesteps reused)
sed -i s/timesteps-reused\ value=\"[0-9]*\"/timesteps-reused\ value=\"${REUSED}\"/g ${FILE}
# change post processing
#sed -i s/post-processing:[A-Za-z-]*/post-processing:${PP}/g ${FILE}
# change coupling scheme
sed -i s/coupling-scheme:[A-Za-z-]*/coupling-scheme:${CP}/g ${FILE}
#change filter
sed -i s/filter\ name=\"[A-Z0-9a-z-]*\"/filter\ name=\"${FILTER}\"/g ${FILE}


for EXTRAPOLATION in 0 # 2
do 
    sed -i s/extrapolation-order\ value=\"[0-9]*\"/extrapolation-order\ value=\"${EXTRAPOLATION}\"/g ${FILE}
    for KAPPA in 1000 # 100 10
    do
        for TAU in 0.1 # 0.01 0.001
        do
            if [ ${ML} = 0 ]; then
                ./FluidSolver ${FILE} $N ${TAU} ${KAPPA} ${ML} &
                ./StructureSolver ${FILE} $N ${ML}
            else
                ./FluidSolver ${FILE} $N ${NCOARSE} ${TAU} ${KAPPA} ${ML} &
                ./StructureSolver ${FILE} $N ${NCOARSE} ${ML}
            fi

            if [ ! -d ${DEST_DIR} ]; then
                mkdir ${DEST_DIR}
            fi
#            cp iterations-STRUCTURE_1D.txt ${DEST_DIR}/iter_${PPNAME}_reused-${REUSED}_extrapol-${EXTRAPOLATION}
        done
    done
done
