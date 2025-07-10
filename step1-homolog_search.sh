#要设置PSI-BLAST的覆盖率（Coverage），您可以使用 -qcov_hsp_perc 参数。这个参数控制每个查询的HSP（高相似性区段）在查询序列中的覆盖率百分比。您可以将其设置为您期望的覆盖率百分比值，以便筛选出符合要求的结果。
#要设置PSI-BLAST的身份度（Identity），您可以使用 -threshold 参数。该参数用于设置期望的匹配身份度阈值，通常以百分比表示。默认情况下，该值为11，但您可以根据需要将其设置为更高的值，以获得更相似的序列。

#准备 protein.fasta。

#最终结果：
/data/yudonglin/software/blast/bin/psiblast -query protein.fasta  -qcov_hsp_perc 0.8   -evalue 1e-6 -db /data4/yudonglin/tnpB_project/blast_db/nr/nr -num_iterations 8 -num_alignments 20000 -out_ascii_pssm ascii_pssm_cas12m.txt -out out_cas12m.txt -out_pssm pssm_cas12m.txt -comp_based_stats 0 -inclusion_ethresh 1e-7 -num_threads 60
