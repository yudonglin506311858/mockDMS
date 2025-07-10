
#!/bin/bash
# 输入文件
input_file="out_cas12m.txt"
# 输出文件
output_file="extracted_sequences.fasta"
# 初始化标志变量
start=0
sequence=""
# 循环读取文件内容
while IFS= read -r line; do
    # 如果行以">="开头，说明找到了序列名
    if [[ $line == ">"* ]]; then
        # 如果已经找到了起始标志，则写入之前提取的序列
        if [ $start -eq 1 ]; then
            # 写入序列名和序列
            echo "$header" >> "$output_file"
            echo "$sequence" >> "$output_file"
        fi
        # 提取新的序列名
        header="${line}"
        # 设置起始标志为1
        start=1
        # 清空之前的序列
        sequence=""
    elif [[ $line == "Sbjct"* ]]; then
        # 如果行以"Sbjct"开头，则提取序列
        # 去除行首的"Sbjct"，并删除两端的空格和-符号，保留序列部分
        seq_part="${line:6}"
        seq_part="${seq_part//[[:digit:]]/}"
        seq_part="${seq_part//-/}"
        seq_part="${seq_part//[[:space:]]/}"
        sequence+="$seq_part"
    fi
done < "$input_file"

# 处理最后一个序列
if [ $start -eq 1 ]; then
    # 写入最后一个序列
    echo "$header" >> "$output_file"
    echo "$sequence" >> "$output_file"
fi
echo "提取完成，结果保存在 $output_file 文件中。"



awk '{
    if (/^>/) {
        if (seq_length[id] < length(seq)) {
            seq_length[id] = length(seq);
            sequences[id] = seq;
        }
        id = substr($0, 2);
        seq = "";
    } else {
        seq = seq $0;
    }
}
END {
    if (seq_length[id] < length(seq)) {
        seq_length[id] = length(seq);
        sequences[id] = seq;
    }
    for (id in sequences) {
        print ">" id;
        print sequences[id];
    }
}' extracted_sequences.fasta > unique_sequences.fasta





#然后统计氨基酸的长度
#awk '/^>/ {if (seqlen){print seqlen}; printf substr($0, 2) " "; seqlen=0; next} {seqlen += length($0)} END {print seqlen}' unique_sequences.fasta > sequence_lengths.txt
awk '/^>/ {if (seqlen){print seqlen}; printf substr($0, 2) " "; seqlen=0; next} {seqlen += length($0)} END {print seqlen}' unique_sequences.fasta | awk '{print $1, $NF}' > sequence_lengths.txt



#保留特定长度氨基酸以上的蛋白质
#awk 'BEGIN {RS=">"; ORS=""} length($2) >= 250 {print ">"$0}' extracted_sequences.fasta > filtered_sequences.fasta

awk '/^>/ {
       if (seq) {
           if (length(seq) > 500 && length(seq) < 1000) {
               print header"\n"seq
           }
       };
       header=$0;
       seq=""
     }
     !/^>/ {
       seq=seq""$0
     }
     END {
       if (length(seq) > 500 && length(seq) < 1000) {
           print header"\n"seq
       }
     }' unique_sequences.fasta > filtered_sequences.fasta

awk '/^>/ {if (seqlen){print seqlen}; printf substr($0, 2) " "; seqlen=0; next} {seqlen += length($0)} END {print seqlen}'  filtered_sequences.fasta | awk '{print $1, $NF}' >  filtered_sequence_lengths.txt


#sudo apt install ncbi-entrez-direct
#提取所有的蛋白质ID，然后使用efetch软件来提取序列
grep '^>' filtered_sequences.fasta  | awk '{print $1}' | sed 's/>//' > target_ids.txt
while read id; do efetch -db protein -id $id -format fasta; done < target_ids.txt > filtered_extracted_sequences.fasta
#https://blog.csdn.net/qq_43138237/article/details/129325813



# 运行 MAFFT 比对
#mafft --auto --thread 60 filtered_sequences.fasta  > aligned.fasta
mafft --retree 1  --thread 60 --maxiterate 0 filtered_extracted_sequences.fasta> aligned_sequences.fasta

#鉴定相似性，筛选相似性在0.7以上的序列
#The filtered set was then clustered using MMSeqs2 at 70% sequence identity with a minimum coverage of 70%. 
mmseqs easy-cluster aligned_sequences.fasta clustered_sequences.fasta tmp_directory --min-seq-id 0.7 --cov-mode 1 -c 0.7 --threads 60

