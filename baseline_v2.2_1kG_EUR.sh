#!/bin/bash

set -eu

# Be sure to set the appropriate path to the bedfiles for $bedfiledir.
# (download https://github.com/precimed/gsa-mixer/tree/main/reference/baselineLD_v2.2_bedfiles_only_binary & extract it)
#
bedfiledir=/home/oleksanf/github/precimed/gsa-mixer/reference/baselineLD_v2.2_bedfiles_only_binary
basedir=$(cd $(dirname $0) && pwd)
bedfilelist="$basedir/baseline_v2.2_bedfiles.txt"

# NB! ldsc is not relevant for GSA-MiXeR annotations, because it's only used for computing LD-weighted annotations; we don't need that in GSA-MiXeR
#ldscdir=~/src/github.com/bulik/ldsc
#ldsc=$ldscdir/ldsc.py
#snps=$ldscdir/hapmap3_snps

chr=$1
bfile=/home/oleksanf/github/comorment/mixer/reference/ldsc/1000G_EUR_Phase3_plink/1000G.EUR.QC.$chr
bim=$bfile.bim
bfilename=$(basename $bfile)

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
mv baseline.$chr.annot.gz /home/oleksanf/github/comorment/mixer/reference/ldsc/1000G_EUR_Phase3_plink/baseline_v2.2_1000G.EUR.QC.${chr}.annot.gz

#$ldsc --l2 --bfile $bfile --ld-wind-cm 1 --annot baseline.$chr.annot.gz --out baseline.$chr --print-snps $snps/hm.$chr.snp

# this is how I created the environment (a bit legacy, but still worked as of Sep 2024)
# conda create --name bx python=3.7.0
# conda install pandas=1.2.1 
# conda install -c conda-forge -c bioconda bx-python


# submission command:
# source activate bx
#for chr in $(seq 22); do echo "./baseline_v2.2_1kG_EUR.sh ${chr}"; done
