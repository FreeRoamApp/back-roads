#!/bin/sh
# mv ./lang/es/paths_es.json ./lang/es-ES/paths_es.json
# mv ./lang/pt/paths_pt.json ./lang/pt-PT/paths_pt.json
# mv ./lang/zh/paths_zh.json ./lang/zh-CN/paths_zh.json
rm -r ./lang/es
rm -r ./lang/pt
rm -r ./lang/zh
mv ./lang/es-ES ./lang/es
mv ./lang/pt-PT ./lang/pt
mv ./lang/zh-CN ./lang/zh
