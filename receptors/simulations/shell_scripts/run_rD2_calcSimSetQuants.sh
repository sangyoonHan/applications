#!/bin/sh
#SBATCH --partition=super
#SBATCH --nodes=1
#SBATCH --job-name=rD2_calcSSQ
#SBATCH --output=rD2_calcSSQ.out
#SBATCH --error=rD2_calcSSQ.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=robel.yirdaw@utsouthwestern.edu

module load matlab

aPDir=("aP0p2" "aP0p3" "aP0p4" "aP0p5" "aP0p6" "aP0p7" "aP0p8")
lRDir=("lR0p1" "lR0p2" "lR0p3" "lR0p4" "lR0p5" "lR0p6")

for i in {0..3}
do
   for j in {0..5}
   do
      matlab -nodisplay -nosplash -noFigureWindows -logfile ${aPDir[$i]}/${lRDir[$j]}/calcSSQ_log.txt -r "cd /project/biophysics/jaqaman_lab/interKinetics/ryirdaw/2014/11/112414/probeISanalysis_sT25_dT0p01/rD2/; calculateSimSetQuants('${aPDir[$i]}/${lRDir[$j]}',10,'rD2_${aPDir[$i]}_${lRDir[$j]}'); exit" &
   done
done

wait
for i in {4..6}
do
   for j in {0..5}
   do
      matlab -nodisplay -nosplash -noFigureWindows -logfile ${aPDir[$i]}/${lRDir[$j]}/calcSSQ_log.txt -r "cd /project/biophysics/jaqaman_lab/interKinetics/ryirdaw/2014/11/112414/probeISanalysis_sT25_dT0p01/rD2/; calculateSimSetQuants('${aPDir[$i]}/${lRDir[$j]}',10,'rD2_${aPDir[$i]}_${lRDir[$j]}'); exit" &
   done
done

wait

