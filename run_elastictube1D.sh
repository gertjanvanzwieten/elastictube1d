#!/bin/sh
# set -e
BASE=$PWD
cd $BASE
# ---------------------------------------- PARAMETERS --------------------------------------------------------
# 1d tube parameters
N=100
NCOARSE=40
ML=1 # multi-level, i.e., manifold mapping


# coupling parameters
PPNAME=s-mm-iqn-ils
CP=serial-implicit
PP=IQN-ILS

EXTRAPOLATION=0
REUSED=0

FILTER=QR1
EPS=1e-13

COPY=1
ONLY_POSTPROC=0
POSTPROC=1


DEST_DIR=experiments/${PPNAME}/FSI-${N}-${NCOARSE}_NEW3/extrp-0/
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


sed -i s/timesteps-reused\ value=\"[0-9]*\"/timesteps-reused\ value=\"${REUSED}\"/g ${FILE}                # set reuse
sed -i s/extrapolation-order\ value=\"[0-9]*\"/extrapolation-order\ value=\"${EXTRAPOLATION}\"/g ${FILE}   # set extrapolation order
#sed -i s/post-processing:[A-Za-z-]*/post-processing:${PP}/g ${FILE}                                       # set post processing method
sed -i s/coupling-scheme:[A-Za-z-]*/coupling-scheme:${CP}/g ${FILE}                                        # set coupling scheme
#sed -i s/filter\ type=\"[A-Z0-9a-z-]*\"\ limit=\"[0-9e]*\"/filter\ type=\"${FILTER}\"\ limit=\"${EPS}\"/g ${FILE}   # set filter method

echo "Start Simulation run"
if [ ${COPY} = 1 ]; then
    cp ${FILE} ${DEST_DIR}/${FILE}
fi

# COMPUTATION, PARAMETER STUDY
if [ ${ONLY_POSTPROC} = 0 ]; then

    for EXTRAPOLATION in  2
    do 
        sed -i s/extrapolation-order\ value=\"[0-9]*\"/extrapolation-order\ value=\"${EXTRAPOLATION}\"/g ${FILE}
        for KAPPA in 10  100   1000
        do
            for TAU in 0.1 0.01 0.001
            do
                echo "\n ############################### \n"
                echo " run 1d elastictube with N="${N}", tau="${TAU}", kappa="${KAPPA}
                echo " coupling-scheme: "${CP}
                echo " post-processing: "${PP}
                echo " reuse="${REUSED}
                echo " extrapolation order="${EXTRAPOLATION}
                echo "\n ###############################"
                if [ ${ML} = 0 ]; then
                    ./FluidSolver ${FILE} $N ${TAU} ${KAPPA} ${ML} > log.fluid 2>&1 &
                    ./StructureSolver ${FILE} $N ${ML} > log.structure 2>&1
                else
                    ./FluidSolver ${FILE} $N ${NCOARSE} ${TAU} ${KAPPA} ${ML} > log.fluid 2>&1 &
                    ./StructureSolver ${FILE} $N ${NCOARSE} ${ML} > log.structure 2>&1
                fi

                if [ ! -d ${DEST_DIR} ]; then
                    mkdir ${DEST_DIR}
                fi
                if [ ${COPY} = 1 ]; then
                    if [ ${ML} = 0 ]; then
                        cp iterations-STRUCTURE_1D.txt ${DEST_DIR}/iter_FSI-${N}-${NCOARSE}_${PPNAME}_reused-${REUSED}_extrapol-${EXTRAPOLATION}_[${N}_${TAU}_${KAPPA}].txt
                    else
                        cp iterations-STRUCTURE_1D.txt ${DEST_DIR}/iter_FSI-${N}-${NCOARSE}_${PPNAME}_reused-${REUSED}_extrapol-${EXTRAPOLATION}_[${N}-${NCOARSE}_${TAU}_${KAPPA}].txt
                    fi
                fi
            done
        done
    done

fi


# POST-PROCESSING OF OUTPUT DATA
if [ ${POSTPROC} = 1 ]; then
    if [ ${ML} = 0 ]; then
        python script_postprocessing_iter.py ${DEST_DIR}
    else
        python script_MMpostprocessing_iter.py ${DEST_DIR}
    fi

    cp iterations_FSI-${N}-${NCOARSE}_*.dat ${DEST_DIR}/
    cp log.pp ${DEST_DIR}/log.pp

    echo "\n -- pgfplots iteration table ---\n\n"
    cat iterations_FSI-${N}-${NCOARSE}_*.dat
    echo "\n -- post procesing log file  ---\n\n"
    cat log.pp

    rm iterations_FSI-${N}-${NCOARSE}_*.dat
    rm log.pp
fi