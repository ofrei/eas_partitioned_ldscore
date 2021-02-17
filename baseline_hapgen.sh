#!/bin/bash

set -eu

# Be sure to set the appropriate path to the bedfiles for $bedfiledir.
# (download http://data.broadinstitute.org/alkesgroup/LDSCORE/baseline_bedfiles.tgz & extract it).
#
bedfiledir=/home/oleksanf/vmshare/data/SIMU_PLSA_MIXER/baseline
basedir=$(cd $(dirname $0) && pwd)
bedfilelist="$basedir/baseline_bedfiles.txt"

#ldscdir=~/src/github.com/bulik/ldsc
#ldsc=$ldscdir/ldsc.py
#snps=$ldscdir/hapmap3_snps

bfile=$1
bim=$bfile.bim
bfilename=$(basename $bfile)
chr=${bfilename##*.}

mkdir -p $bfilename

cat $bim \
  | awk '
BEGIN {
  OFS="\t"
  print "CHR", "BP", "SNP", "CM", "base"
}
{print $1, $4, $2, $3, "1"}
' > $bfilename/base.annot

cat $bedfilelist | tail -n+2 | awk -v d=$bedfiledir '$0{print d"/"$0".bed"}' | parallel -j6 $basedir/annotate_snps.py --bfile $bfile --chr $chr --annot-bed {} --only-annot --out $bfilename/{/.}
cat $bedfilelist | awk -v d=$bfilename '$0{print d"/"$0".annot"}' | xargs paste -d$'\t' | gzip -c > baseline.$chr.annot.gz
mv baseline.$chr.annot.gz /home/oleksanf/vmshare/data/SIMU_PLSA_MIXER/bfile_merged

#$ldsc --l2 --bfile $bfile --ld-wind-cm 1 --annot baseline.$chr.annot.gz --out baseline.$chr --print-snps $snps/hm.$chr.snp

# submission command:
#for chr in $(seq 22); do echo "./baseline_hapgen.sh /home/oleksanf/vmshare/data/SIMU_PLSA_MIXER/bfile_merged/chr$chr"; done
