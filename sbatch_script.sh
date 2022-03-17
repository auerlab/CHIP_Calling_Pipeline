#!/bin/bash

#SBATCH --job-name=CHIP
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=2gb
#SBATCH --time=6:00:00
#SBATCH --array=1-5
#SBATCH --account=pauer
#SBATCH --output=/scratch/u/pauer/MDS_CHIP_mCA/slurm_out/slurm%j.out

### Get sample ID of the nth file for the nth job in the array
cd CRAM_FILES
sample_id=$( ls -lh | grep '.cram.crai' | awk '{split($9, a, "."); print(a[1]);}' | awk -v line=${SLURM_ARRAY_TASK_ID} '{if(NR == line){print $1};}' )
cd ../

echo ${sample_id}

### Define directories
cram_dir="/scratch/u/pauer/MDS_CHIP_mCA/CRAM_FILES"
ref_dir="/scratch/u/pauer/MDS_CHIP_mCA/REF_FILES"
out_dir="/scratch/u/pauer/MDS_CHIP_mCA/OUTPUT"
ann_dir="/scratch/u/pauer/MDS_CHIP_mCA/ANNOVAR_FILES"
whitelist_dir="/scratch/u/pauer/MDS_CHIP_mCA/WHITELIST_FILTER_FILES"

## Somatic variant calling with Octopus
module load octopus
octopus -I ${cram_dir}/${sample_id}.cram -R  ${ref_dir}/hg38.fasta -C cancer -o ${out_dir}/${sample_id}.vcf --max-genotypes 100 --very-fast --keep-unfiltered-calls --threads 16

### Annotation with ANNOVAR 
module load annovar
table_annovar.pl ${out_dir}/${sample_id}.vcf ${ann_dir} \
        -buildver hg38 \
        -out ${out_dir}/${sample_id} \
        -remove \
        -protocol refGene,cosmic70 \
        -operation g,f \
        -nastring . -vcfinput

### Filtering off the whitelist
module load  R/4.0.4
Rscript ${whitelist_dir}/whitelist_filter_rscript.R --args ${sample_id} ${out_dir}

