INPUT_DIR="$HOSTWD/test_output/out/"
OUTPUT_DIR="$HOSTWD/test_output/out/alignment/pacbioccs/vcf"
BIN_VERSION="0.8.0"
SCAFF=$2
PAT=`echo $SCAFF | sed 's/\([^\\]\);/\1\\\\;/g' | sed 's/\([^\\]\)=/\1\\\\=/g'`
echo $PAT

#short=`echo $SCAFF | cut -d';' -f1 | cut -d'.' -f2`
#echo $short
echo INPUT DIR: ${INPUT_DIR}
echo OUTDIR DIR: ${OUTPUT_DIR}
/wd/dipasm/outside_bin/singularity shell \
  -B "${INPUT_DIR}":"/input" \
  -B"${OUTPUT_DIR}":"/output" \
  /wd/dipasm/DipAsm/deepvariant_gpu.0.8.0.simg \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=PACBIO \
  --ref=/input/peregrine/asm-r3-pg0.1.5.3/p_ctg_cns.fa \
  --reads=/input/alignment/pacbioccs/split/"pacbioccs.${PAT}.bam" \
  --output_vcf="/output/pacbioccs.${PAT}.vcf.gz" \
  --regions "${PAT}" \
  --num_shards=16
