#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.0
doc: RNA-seq 04 quantification
requirements:
 - class: ScatterFeatureRequirement
 - class: StepInputExpressionRequirement
 - class: InlineJavascriptRequirement
 - class: SubworkflowFeatureRequirement
inputs:
   input_bam_files:
     type: File[]
   nthreads:
     default: 1
     type: int
   rsem_reference_files:
     doc: RSEM genome reference files - generated with the rsem-prepare-reference command
     type: Directory
   annotation_file:
     doc: GTF annotation file
     type: File
   input_transcripts_bam_files:
     type: File[]
   input_genome_sizes:
     type: File
   bamtools_forward_filter_file:
     doc: JSON filter file for forward strand used in bamtools (see bamtools-filter command)
     type: File
   bamtools_reverse_filter_file:
     doc: JSON filter file for reverse strand used in bamtools (see bamtools-filter command)
     type: File
outputs:
   featurecounts_counts:
     doc: Normalized fragment extended reads bigWig (signal) files
     type: File[]
     outputSource: featurecounts/output_files
   rsem_isoforms_files:
     doc: RSEM isoforms files
     type: File[]
     outputSource: rsem-calc-expr/isoforms
   rsem_genes_files:
     doc: RSEM genes files
     type: File[]
     outputSource: rsem-calc-expr/genes
   bam_plus_files:
     doc: BAM files containing only reads in the forward (plus) strand.
     type: File[]
     outputSource: split_bams/bam_plus_files
   bw_raw_plus_files:
     doc: Raw bigWig files from BAM files containing only reads in the forward (plus) strand.
     type: File[]
     outputSource: bdg2bw-raw-plus/output_bigwig
   bw_norm_plus_files:
     doc: Normalized by RPKM bigWig files from BAM files containing only reads in the forward (plus) strand.
     type: File[]
     outputSource: bamcoverage-plus/output_bam_coverage
   bam_minus_files:
     doc: BAM files containing only reads in the reverse (minus) strand.
     type: File[]
     outputSource: split_bams/bam_minus_files
   bw_raw_minus_files:
     doc: Raw bigWig files from BAM files containing only reads in the reverse (minus) strand.
     type: File[]
     outputSource: bdg2bw-raw-minus/output_bigwig
   bw_norm_minus_files:
     doc: Normalized by RPKM bigWig files from BAM files containing only reads in the forward (plus) strand.
     type: File[]
     outputSource: bdg2bw-norm-minus/output_bigwig
steps:
   basename:
     run: ../utils/basename.cwl
     in:
       file_path:
         source: input_bam_files
         valueFrom: $(self.basename)
       sep:
         valueFrom: \.Aligned\.out\.sorted
     scatter: file_path
     out:
     - basename
   featurecounts:
     run: ../quant/subread-featurecounts.cwl
     in:
       B:
         valueFrom: ${return true}
       g:
         valueFrom: gene_id
       output_filename:
         source: basename/basename
         valueFrom: $(self + ".featurecounts.counts.txt")
       p:
         valueFrom: ${return true}
       s:
         valueFrom: ${return 0}
       t:
         valueFrom: exon
       annotation_file: annotation_file
       T: nthreads
       input_files:
         source: input_bam_files
         valueFrom: ${if (Array.isArray(self)) return self; return [self]; }
     scatterMethod: dotproduct
     scatter:
     - input_files
     - output_filename
     out:
     - output_files
   rsem-calc-expr:
     run: ../quant/rsem-calculate-expression.cwl
     in:
       reference_name:
         source: rsem_reference_files
         valueFrom: |
           ${
             var trans_file_str = self.listing.map(function(e){return e.location}).filter(function(e){return e.match(/\.transcripts\.fa$/)})[0];
             return trans_file_str.match(/.*[\\\\\\/](.*)\.transcripts\.fa$/)[1];
           }
       reference_files: rsem_reference_files
       no-bam-output:
         valueFrom: ${return true}
       quiet:
         valueFrom: ${return true}
       seed:
         valueFrom: ${return 1234}
       sample_name:
         source: basename/basename
         valueFrom: $(self + ".rsem")
       bam: input_transcripts_bam_files
       num-threads: nthreads
       paired-end:
           valueFrom: ${return true}
     scatterMethod: dotproduct
     scatter:
     - bam
     - sample_name
     out:
     - isoforms
     - genes
     - rsem_stat
   split_bams:
     in:
       bamtools_reverse_filter_file: bamtools_reverse_filter_file
       bamtools_forward_filter_file: bamtools_forward_filter_file
       input_bam_files: input_bam_files
       input_basenames: basename/basename
     run: ../quant/split-bams-by-strand-and-index.cwl
     out:
     - bam_plus_files
     - bam_minus_files
   bamcoverage-minus:
     run: ../quant/deeptools-bamcoverage.cwl
     scatter: bam
     in:
       binSize:
         valueFrom: ${return 1}
       numberOfProcessors: nthreads
       bam: split_bams/bam_minus_files
       output_suffix:
         valueFrom: .norm-minus-pre-negated-bw
       normalizeUsing:
         valueFrom: RPKM
     out:
     - output_bam_coverage
   bw2bdg-minus:
     run: ../quant/bigWigToBedGraph.cwl
     scatter: bigwig_file
     in:
       bigwig_file: bamcoverage-minus/output_bam_coverage
     out:
     - output_bedgraph
   negate_minus_bdg_norm:
     run: ../quant/negate-minus-strand-bedgraph.cwl
     scatter:
     - bedgraph_file
     - output_filename
     scatterMethod: dotproduct
     in:
       bedgraph_file: bw2bdg-minus/output_bedgraph
       output_filename:
         source: basename/basename
         valueFrom: $(self + ".norm-minus-bdg")
     out:
     - negated_minus_bdg
   bdg2bw-raw-minus:
     run: ../quant/bedGraphToBigWig.cwl
     scatter: bed_graph
     in:
       output_suffix:
         valueFrom: .bw
       genome_sizes: input_genome_sizes
       bed_graph: negate_minus_bdg/negated_minus_bdg
     out:
     - output_bigwig
   bdg2bw-norm-minus:
     run: ../quant/bedGraphToBigWig.cwl
     scatter: bed_graph
     in:
       output_suffix:
         valueFrom: .Aligned.minus.norm.bw
       genome_sizes: input_genome_sizes
       bed_graph: negate_minus_bdg_norm/negated_minus_bdg
     out:
     - output_bigwig
   bedtools_genomecov_minus:
     run: ../map/bedtools-genomecov.cwl
     scatter: ibam
     in:
       bg:
         valueFrom: ${return true}
       g: input_genome_sizes
       ibam: split_bams/bam_minus_files
     out:
     - output_bedfile
   bedsort_genomecov_minus:
     run: ../quant/bedSort.cwl
     scatter: bed_file
     in:
       bed_file: bedtools_genomecov_minus/output_bedfile
     out:
     - bed_file_sorted
   negate_minus_bdg:
     run: ../quant/negate-minus-strand-bedgraph.cwl
     scatterMethod: dotproduct
     scatter:
     - bedgraph_file
     - output_filename
     in:
       bedgraph_file: bedsort_genomecov_minus/bed_file_sorted
       output_filename:
         source: basename/basename
         valueFrom: $(self + ".Aligned.minus.raw.bdg")
     out:
     - negated_minus_bdg
   bamcoverage-plus:
     run: ../quant/deeptools-bamcoverage.cwl
     scatter: bam
     in:
       binSize:
         valueFrom: ${return 1}
       numberOfProcessors: nthreads
       bam: split_bams/bam_plus_files
       output_suffix:
         valueFrom: .norm.bw
       normalizeUsing:
         valueFrom: RPKM
     out:
     - output_bam_coverage
   bedtools_genomecov_plus:
     run: ../map/bedtools-genomecov.cwl
     scatter: ibam
     in:
       bg:
         valueFrom: ${return true}
       g: input_genome_sizes
       ibam: split_bams/bam_plus_files
     out:
     - output_bedfile
   bdg2bw-raw-plus:
     run: ../quant/bedGraphToBigWig.cwl
     scatter: bed_graph
     in:
       output_suffix:
         valueFrom: .raw.bw
       genome_sizes: input_genome_sizes
       bed_graph: bedsort_genomecov_plus/bed_file_sorted
     out:
     - output_bigwig
   bedsort_genomecov_plus:
     run: ../quant/bedSort.cwl
     scatter: bed_file
     in:
       bed_file: bedtools_genomecov_plus/output_bedfile
     out:
     - bed_file_sorted