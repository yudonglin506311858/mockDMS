# mockDMS

## 流程
PSI-BLAST—efetch—MMSeqs2—MAFFT—DMS—ratio

## step0-dataset_prepare

下载软件和数据

## step1-homolog_search

寻找同源性序列。准备protein.fasta。

## step2-sequence_extract

提取保守性序列。

## step3-DMS_minic

得到amino_acid_counts.txt。

## step4-result_calculate

得到具体的突变频率比例，并且输出突变频率最高的位点。
