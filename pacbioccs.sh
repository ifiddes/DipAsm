#!/bin/bash
PBPATH=$1
CORES=$2
GPUS=$3
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
export SCRIPTPATH
let GCORES="CORES / GPUS"
set -ex

echo Minimap2

minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k -t ${CORES} \
  -R "@RG\tSM:$SAMPLE\tID:$SAMPLE" --eqx --secondary=no $REF $PBPATH/*.f*q 2> minimap2.pacbioccs.log \
  | samtools sort -@${CORES} --output-fmt BAM -o alignment/pacbioccs/pacbioccs.bam

[ -d alignment/pacbioccs/split ] || mkdir -p alignment/pacbioccs/split

echo Splitting PacBioCCS alignment
cut -d$'\t' -f1 ${REF}.fai | parallel -j${GPUS} 'samtools view -@${GCORES} -b alignment/pacbioccs/pacbioccs.bam {} > alignment/pacbioccs/split/pacbioccs.{}.bam'
cut -d$'\t' -f1 ${REF}.fai | parallel -j${GPUS} 'samtools index -@${GCORES} alignment/pacbioccs/split/pacbioccs.{}.bam'

[ -d alignment/pacbioccs/vcf ] || mkdir -p alignment/pacbioccs/vcf

echo DeepVariant.....
cut -d$'\t' -f1 ${REF}.fai | parallel -j${GPUS} '$SCRIPTPATH/dv.sh $REF $GCORES {}'

ls alignment/pacbioccs/vcf/*gz | parallel 'bgzip -cd {} > {.}'
ls alignment/pacbioccs/vcf/*vcf | parallel "grep -E '^#|0/0|1/1|0/1|1/0|0/2|2/0' {} > {.}.filtered.vcf"
