#!/usr/bin/env cwl-runner
cwlVersion: 'cwl:draft-3'
class: CommandLineTool
description: "Get number of processed reads from Bowtie log."

hints:
  - class: DockerRequirement
    dockerImageId: 'dukegcb/workflow-utils'

requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement

inputs:
  - { id: preseq_c_curve_outfile,  type: File, inputBinding: {} }

outputs:
    - id: output
      type: File
      outputBinding:
        glob: $(inputs.preseq_c_curve_outfile.path.replace(/^.*[\\\/]/, '') + '.read_percentage.unique')

baseCommand: percent-uniq-reads-from-preseq.sh
stdout: $(inputs.preseq_c_curve_outfile.path.replace(/^.*[\\\/]/, '') + '.read_percentage.unique')
