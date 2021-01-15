INPUT_DIR=$PWD/alignment/pacbioccs/split
OUTPUT_DIR=$PWD/alignment/pacbioccs/vcf
BIN_VERSION="0.8.0"
REF=$1
GCORES=$2
SCAFF=$3

PAT=`echo $SCAFF | sed 's/\([^\\]\);/\1\\\\;/g' | sed 's/\([^\\]\)=/\1\\\\=/g'`
echo $PAT

#short=`echo $SCAFF | cut -d';' -f1 | cut -d'.' -f2`
#echo $short
echo INPUT DIR: ${INPUT_DIR}
echo OUTDIR DIR: ${OUTPUT_DIR}
docker run --gpus 1 \
  -v "${INPUT_DIR}:/input" \
  -v "${OUTPUT_DIR}:/output" \
  -v "$(dirname "${REF}")":/data/ \
  gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}-gpu" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=PACBIO \
  --ref=/data/"$(basename "${REF}")" \
  --reads="/input/pacbioccs.${PAT}.bam" \
  --output_vcf="/output/pacbioccs.${PAT}.vcf.gz" \
  --regions "${PAT}" \
  --num_shards="${GCORES}"
