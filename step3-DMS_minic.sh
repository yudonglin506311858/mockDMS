
#!/bin/bash

# 提取参考序列的非'-'位置
awk '
  /^>cas12m/ {is_ref=1; next}
  is_ref {
    for (i=1; i<=length($0); i++) {
      if (substr($0,i,1) != "-") print i
    }
    exit
  }
' clustered_sequences.fasta_rep_seq.fasta > ref_positions.txt

# 处理其他序列
awk -v positions="$(tr '\n' ' ' < ref_positions.txt)" '
  BEGIN {
    split(positions, pos_arr, " ")
  }
  /^>/ {
    if (seq) {
      printf "%s\n", header
      for (i in pos_arr) {
        p = pos_arr[i]
        printf "%s", (p <= length(seq) ? substr(seq,p,1) : "-")
      }
      printf "\n"
    }
    header=$0
    seq=""
    next
  }
  {
    seq = seq $0
  }
  END {
    if (seq) {
      printf "%s\n", header
      for (i in pos_arr) {
        p = pos_arr[i]
        printf "%s", (p <= length(seq) ? substr(seq,p,1) : "-")
      }
      printf "\n"
    }
  }
' clustered_sequences.fasta_rep_seq.fasta > sequences.fasta

# 清理
rm ref_positions.txt


#!/bin/bash

# 输入文件
INPUT="sequences.fasta"

# 输出文件
COUNT_FILE="amino_acid_counts.txt"

# 获取cas12m序列（去除头和换行符）
CAS12M_SEQ=$(grep -A1 ">cas12m" $INPUT | tail -n1 | tr -d '\n')
CAS12M_LEN=${#CAS12M_SEQ}

# 标准氨基酸列表 + gap（21种）
AMINO_ACIDS="A C D E F G H I K L M N P Q R S T V W Y -"

# 初始化计数矩阵和位置计数器
declare -A COUNT_MATRIX
declare -a POS_COUNTS

# 初始化所有计数为0
for aa in $AMINO_ACIDS; do
  for ((i=0; i<$CAS12M_LEN; i++)); do
    COUNT_MATRIX["${aa}_${i}"]=0
  done
done

for ((i=0; i<$CAS12M_LEN; i++)); do
  POS_COUNTS[$i]=0
done

# 处理所有序列
process_sequence() {
  local seq=$1
  local cas_pos=0
  local seq_pos=0
  
  while (( cas_pos < CAS12M_LEN && seq_pos < ${#seq} )); do
    local cas_aa=${CAS12M_SEQ:$cas_pos:1}
    local seq_aa=${seq:$seq_pos:1}
    
    # 不跳过gap，所有字符都统计
    ((POS_COUNTS[$cas_pos]++))
    if [[ " $AMINO_ACIDS " == *" $seq_aa "* ]]; then
      ((COUNT_MATRIX["${seq_aa}_${cas_pos}"]++))
    else
      # 如果出现非标准字符，也可以放进一个其他分类，比如 X 或忽略
      ((COUNT_MATRIX["-${cas_pos}"]++))  # 这里保底放到 "-"
    fi

    ((cas_pos++))
    ((seq_pos++))
  done
}

# 读取并处理所有序列
CURRENT_SEQ=""
while IFS= read -r LINE; do
  if [[ "$LINE" == ">"* ]]; then
    # 处理前一个序列
    if [[ -n "$CURRENT_SEQ" ]]; then
      process_sequence "$CURRENT_SEQ"
    fi
    CURRENT_SEQ=""
  else
    CURRENT_SEQ+=$(echo "$LINE" | tr -d '\n')
  fi
done < "$INPUT"

# 处理最后一个序列
if [[ -n "$CURRENT_SEQ" ]]; then
  process_sequence "$CURRENT_SEQ"
fi

# 输出计数矩阵
echo "输出氨基酸计数矩阵到 $COUNT_FILE..."
echo -n "Pos" > $COUNT_FILE

# 写入列头（位置编号）
for ((i=0; i<$CAS12M_LEN; i++)); do
  printf "\t%d" $((i+1)) >> $COUNT_FILE
done
echo >> $COUNT_FILE

# 写入每行氨基酸计数
for aa in $AMINO_ACIDS; do
  echo -n "$aa" >> $COUNT_FILE
  for ((i=0; i<$CAS12M_LEN; i++)); do
    printf "\t%d" ${COUNT_MATRIX["${aa}_${i}"]} >> $COUNT_FILE
  done
  echo >> $COUNT_FILE
done
sed -i '$d' amino_acid_counts.txt
# 输出总结信息
echo "分析完成。结果已保存到:"
echo "- 氨基酸计数矩阵: $COUNT_FILE"
echo "- 矩阵维度: $(echo $AMINO_ACIDS | wc -w) 种字符 x $CAS12M_LEN 个位置"

