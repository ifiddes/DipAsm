#!/bin/bash
set -ex

HICPATH=$(readlink -f $1)
PBPATH=$(readlink -f $2)
SAMPLE=$3
PREF=$4
CORES=$5
GPUS=$6

SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

echo Using PacBioCCS data saved at: $PBPATH "All .fastq files here will be used"
echo Using Hi-C data saved at: $HICPATH "All *1.fastq and *2.fastq files here will be used"
echo Sample name: $SAMPLE
echo Output will be in ${SAMPLE}_output/$PREF

[ -d ${SAMPLE}_output ] || mkdir -p ${SAMPLE}_output
cd ${SAMPLE}_output
[ -d $PREF ] || mkdir -p $PREF
cd $PREF

[ -d alignment ] || mkdir -p alignment
cd alignment
[ -d hic ] || mkdir -p hic
[ -d pacbioccs ] || mkdir -p pacbioccs
cd ../
[ -d hapcut2 ] || mkdir -p hapcut2
[ -d whatshap ] || mkdir -p whatshap
[ -d haplotag ] || mkdir -p haplotag
[ -d assemble ] || mkdir -p assemble
[ -d hifiasm ] || mkdir -p hifiasm

eval "$(conda shell.bash hook)"
conda activate whdenovo

cd hifiasm
hifiasm -t ${CORES} -o ${SAMPLE}_${PREF} $PBPATH/*fastq
awk '/^S/{print ">"$2"\n"$3}' ${SAMPLE}_${PREF}.p_ctg.gfa | fold > ${SAMPLE}_${PREF}.p_ctg.fa
cd ..

echo "assembly done"
REF="$PWD/hifiasm/${SAMPLE}_${PREF}.p_ctg.fa"
ls -l $REF
bwa index ${REF}
samtools faidx ${REF}

$SCRIPTPATH/pacbioccs.sh $PBPATH $REF $SAMPLE $CORES $GPUS
wait
$SCRIPTPATH/hic.sh $HICPATH $REF $SAMPLE > hic.log 2>&1
wait
$SCRIPTPATH/phase.sh $REF $SAMPLE $PREF &2> phase.log
wait


hifiasm -l0 -t ${CORES} -o hifiasm/${SAMPLE}_${PREF}-H1 haplotag/*-SCAFF-H1.fasta haplotag/*-SCAFF-untagged.fasta
hifiasm -l0 -t ${CORES} -o hifiasm/${SAMPLE}_${PREF}-H2 haplotag/*-SCAFF-H2.fasta haplotag/*-SCAFF-untagged.fasta

awk '/^S/{print ">"$2"\n"$3}' ${SAMPLE}_${PREF}-H1.p_ctg.gfa | fold > ${SAMPLE}_${PREF}-H1.p_ctg.fa
awk '/^S/{print ">"$2"\n"$3}' ${SAMPLE}_${PREF}-H2.p_ctg.gfa | fold > ${SAMPLE}_${PREF}-H2.p_ctg.fa
