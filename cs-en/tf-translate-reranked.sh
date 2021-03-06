#!/bin/bash

echo "Running on $HOSTNAME"

model_dir=`dirname $0`

#language-independent variables (toolkit locations)
. $model_dir/../vars

#language-dependent variables (source and target language)
. $model_dir/vars

# temporary files
tmpfile_src=`mktemp -p $model_dir`
tmpfile_nbest=`mktemp -p $model_dir`

$model_dir/preprocess.sh > $tmpfile_src

#left-to-right n-best list
CUDA_VISIBLE_DEVICES=$device python3 $nematus_home/nematus/translate.py  < $tmpfile_src \
     -m $model_dir/model.l2r.ens{1,2,3,4}.npz \
     -k 50 --n-best > $tmpfile_nbest

#rescoring
$model_dir/../scripts/reverse_nbest.py < $tmpfile_nbest | \
CUDA_VISIBLE_DEVICES=$device python3 $nematus_home/nematus/rescore.py \
     -m $model_dir/model.r2l.ens{1,2,3,4}.npz \
     -b 50 -s $tmpfile_src | \
$model_dir/rerank_normalize.py 12 1 | \
$model_dir/../scripts/reverse.py | \
$model_dir/postprocess.sh

rm $tmpfile_src
rm $tmpfile_nbest
