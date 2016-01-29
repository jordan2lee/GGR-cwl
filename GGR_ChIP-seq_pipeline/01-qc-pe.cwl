#!/usr/bin/env cwl-runner

class: Workflow
description: "GGR_ChIP-seq - QC PE"
requirements:
  - class: ScatterFeatureRequirement

inputs:
  - id: "#input_fastq_files"
    type:
      type: array
      items: File
    description: "Input fastq files"
  - id: "#default_adapters_file"
    type: File
    description: "Adapters file"
  - id: "#se_or_pe"
    description: "Single ended or paired end read"
    type: string

outputs:
  - id: "#output_read_counts"
    source: "#count_raw_reads.output_read_count"
    description: "Raw read counts of fastq files"
    type:
      type: array
      items: File
  - id: "#output_fastqc_report_files"
    source: "#fastqc.output_qc_report_file"
    description: "FastQC reports in zip format"
    type:
      type: array
      items: File
  - id: "#output_fastqc_data_file"
    source: "#extract_fastqc_data.output_fastqc_data_file"
    type:
      type: array
      items: File
  - id: "#output_custom_adapters"
    source: "#overrepresented_sequence_extract.output_custom_adapters"
    type:
      type: array
      items: File

steps:
  - id: "#count_raw_reads"
    run: {import: "../qc/count-fastq-reads.cwl" }
    scatter: "#count_raw_reads.input_fastq_file"
    inputs:
      - id: "#count_raw_reads.input_fastq_file"
        source: "#input_fastq_files"
    outputs:
      - id: "#count_raw_reads.output_read_count"
  - id: "#fastqc"
    run: {import: "../qc/fastqc.cwl" }
    scatter: "#fastqc.input_fastq_file"
    inputs:
      - id: "#fastqc.input_fastq_file"
        source: "#input_fastq_files"
    outputs:
      - id: "#fastqc.output_qc_report_file"
  - id: "#extract_fastqc_data"
    run: {import: "../qc/extract_fastqc_data.cwl" }
    scatter: "#extract_fastqc_data.input_qc_report_file"
    inputs:
      - id: "#extract_fastqc_data.input_qc_report_file"
        source: "#fastqc.output_qc_report_file"
    outputs:
      - id: "#extract_fastqc_data.output_fastqc_data_file"
  - id: "#overrepresented_sequence_extract"
    run: {import: "../qc/overrepresented_sequence_extract.cwl" }
    scatter: "#overrepresented_sequence_extract.input_fastqc_data"
    inputs:
      - id: "#overrepresented_sequence_extract.input_fastqc_data"
        source: "#extract_fastqc_data.output_fastqc_data_file"
      - id: "#overrepresented_sequence_extract.default_adapters_file"
        source: "#default_adapters_file"
      - id: "#overrepresented_sequence_extract.se_or_pe"
        source: "#se_or_pe"
    outputs:
      - id: "#overrepresented_sequence_extract.output_custom_adapters"
