#!/usr/bin/env cwl-runner

class: Workflow
description: "GGR_ChIP-seq - Quantification"

requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement

inputs:
  - id: "#input_bam_files"
    type:
      type: array
      items: File
  - id: "#input_pileup_bedfiles"
    type:
      type: array
      items: File
  - id: "#input_peak_xls_files"
    type:
      type: array
      items: File
  - id: "#input_read_count_dedup_files"
    type:
      type: array
      items: File
  - id: "#input_genome_sizes"
    type: File

outputs:
  - id: "#bigwig_raw_files"
    source: "#bedgraph2bigwig-raw.output_bigwig"
    type:
      type: array
      items: File
  - id: "#bigwig_norm_files"
    source: "#bamcoverage.output_bam_coverage"
    type:
      type: array
      items: File
  - id: "#bigwig_extended_files"
    source: "#bdg2bw-extend.output_bigwig"
    type:
      type: array
      items: File
  - id: "#bigwig_extended_norm_files"
    source: "#bdg2bw-extend-norm.output_bigwig"
    type:
      type: array
      items: File

steps:
  - id: "#bedtools_genomecov"
    run: {import: "../../map/bedtools-genomecov.cwl"}
    scatter: "#bedtools_genomecov.ibam"
    inputs:
      - id: "#bedtools_genomecov.ibam"
        source: "#input_bam_files"
      - id: "#bedtools_genomecov.g"
        source: "#input_genome_sizes"
      - id: "#bedtools_genomecov.bg"
        default: true
    outputs:
      - id: "#bedtools_genomecov.output_bedfile"
  - id: "#bedgraph2bigwig-raw"
    run: {import: "../../quant/bedGraphToBigWig.cwl"}
    scatter: "#bedgraph2bigwig-raw.bed_graph"
    inputs:
      - id: "#bedgraph2bigwig-raw.bed_graph"
        source: "#bedtools_genomecov.output_bedfile"
      - id: "#bedgraph2bigwig-raw.genome_sizes"
        source: "#input_genome_sizes"
      - id: "bedgraph2bigwig-raw.output_suffix"
        valueFrom: ".raw.bw"
    outputs:
      - id: "#bedgraph2bigwig-raw.output_bigwig"
  - id: "#bamcoverage"
    run: {import: "../../quant/deeptools-bamcoverage.cwl"}
    scatter: "#bamcoverage.bam"
    inputs:
      - id: "#bamcoverage.bam"
        source: "#input_bam_files"
      - id: "#bamcoverage.output_suffix"
        valueFrom: ".norm.bw"
    outputs:
      - id: "#bamcoverage.output_bam_coverage"
  - id: "#extend-reads"
    run: {import: "../../quant/bedtools-slop.cwl"}
    scatter: "#extend-reads.i"
    inputs:
      - id: "#extend-reads.i"
        source: "#input_pileup_bedfiles"
      - id: "#extend-reads.g"
        source: "#input_genome_sizes"
      - id: "#extend-reads.b"
        default: 0
    outputs:
      - id: "#extend-reads.stdoutfile"
  - id: "#clip-off-chrom"
    run: {import: "../../quant/bedClip.cwl"}
    scatter: "#clip-off-chrom.bed_file"
    inputs:
      - id: "#clip-off-chrom.bed_file"
        source: "#extend-reads.stdoutfile"
      - id: "#clip-off-chrom.genome_sizes"
        source: "#input_genome_sizes"
    outputs:
      - id: "#clip-off-chrom.bed_file_clipped"
  - id: "#bdg2bw-extend"
    run: {import: "../../quant/bedGraphToBigWig.cwl"}
    scatter: "#bdg2bw-extend.bed_graph"
    inputs:
      - id: "#bdg2bw-extend.bed_graph"
        source: "#clip-off-chrom.bed_file_clipped"
      - id: "#bdg2bw-extend.genome_sizes"
        source: "#input_genome_sizes"
      - id: "bdg2bw-extend.output_suffix"
        default: ".fragment_extended.bw"
    outputs:
      - id: "#bdg2bw-extend.output_bigwig"
  - id: "#scale-bedgraph"
    run: {import: "../../peak_calling/scale-bedgraph.cwl"}
    scatter:
      - "#scale-bedgraph.bedgraph_file"
      - "#scale-bedgraph.read_count_file"
    scatterMethod: dotproduct
    inputs:
      - id: "#scale-bedgraph.bedgraph_file"
        source: "#input_pileup_bedfiles"
      - id: "#scale-bedgraph.read_count_file"
        source: "#input_read_count_dedup_files"
    outputs:
      - id: "#scale-bedgraph.bedgraph_scaled"
  - id: "#bdg2bw-extend-norm"
    run: {import: "../../quant/bedGraphToBigWig.cwl"}
    scatter: "#bdg2bw-extend-norm.bed_graph"
    inputs:
      - id: "#bdg2bw-extend-norm.bed_graph"
        source: "#scale-bedgraph.bedgraph_scaled"
      - id: "#bdg2bw-extend-norm.genome_sizes"
        source: "#input_genome_sizes"
      - id: "bdg2bw-extend-norm.output_suffix"
        default: ".fragment_extended_norm.bw"
    outputs:
      - id: "#bdg2bw-extend-norm.output_bigwig"

