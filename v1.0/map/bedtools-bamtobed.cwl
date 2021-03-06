 class: CommandLineTool
 cwlVersion: v1.0
 requirements:
    InlineJavascriptRequirement: {}
 hints:
    DockerRequirement:
      dockerPull: dukegcb/bedtools
 inputs:
    bedpe:
      type: boolean?
      inputBinding:
        position: 1
        prefix: -bedpe
      doc: |
        Write BEDPE format.
        - Requires BAM to be grouped or sorted by query.
    color:
      type: string?
      inputBinding:
        position: 1
        prefix: -color
      doc: |
        An R,G,B string for the color used with BED12 format.
        Default is (255,0,0).
    ed:
      type: boolean?
      inputBinding:
        position: 1
        prefix: -ed
      doc: |
        Use BAM edit distance (NM tag) for BED score.
        - Default for BED is to use mapping quality.
        - Default for BEDPE is to use the minimum of
        the two mapping qualities for the pair.
        - When -ed is used with -bedpe, the total edit
        distance from the two mates is reported.
    cigar:
      type: string?
      inputBinding:
        position: 1
        prefix: -cigar
      doc: |
        Add the CIGAR string to the BED entry as a 7th column.
    mate1:
      type: boolean?
      inputBinding:
        position: 1
        prefix: -mate1
      doc: "When writing BEDPE (-bedpe) format, \nalways report mate one as the first BEDPE \"block\".\n"
    splitD:
      type: boolean?
      inputBinding:
        position: 1
        prefix: -splitD
      doc: |
        Split alignments based on N and D CIGAR operators.
        Forces -split.
    tag:
      type: boolean?
      inputBinding:
        position: 1
        prefix: -tag
      doc: |
        Use other NUMERIC BAM alignment tag for BED score.
        - Default for BED is to use mapping quality.
        Disallowed with BEDPE output.
    split:
      type: boolean?
      inputBinding:
        position: 1
        prefix: -split
      doc: |
        Report "split" BAM alignments as separate BED entries.
        Splits only on N CIGAR operations.
    bam:
      type: File
      inputBinding:
        position: 3
        prefix: -i
      doc: Input BAM file to be converted to BED format
    bed12:
      type: boolean?
      inputBinding:
        position: 1
        prefix: -bed12
      doc: |
        Write "blocked" BED format (aka "BED12"). Forces -split.
 outputs:
    output_bedfile:
      type: File
      outputBinding:
        glob: $(inputs.bam.path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, "") + '.bed')
 baseCommand:
  - bedtools
  - bamtobed
#description: "Tool:    bedtools bamtobed (aka bamToBed)\nVersion: v2.25.0\nSummary: Converts BAM alignments to BED6 or BEDPE format.\n\nUsage:   bedtools bamtobed [OPTIONS] -i <bam> \n\nOptions: \n\t-bedpe\tWrite BEDPE format.\n\t\t- Requires BAM to be grouped or sorted by query.\n\n\t-mate1\tWhen writing BEDPE (-bedpe) format, \n\t\talways report mate one as the first BEDPE \"block\".\n\n\t-bed12\tWrite \"blocked\" BED format (aka \"BED12\"). Forces -split.\n\n\t\thttp://genome-test.cse.ucsc.edu/FAQ/FAQformat#format1\n\n\t-split\tReport \"split\" BAM alignments as separate BED entries.\n\t\tSplits only on N CIGAR operations.\n\n\t-splitD\tSplit alignments based on N and D CIGAR operators.\n\t\tForces -split.\n\n\t-ed\tUse BAM edit distance (NM tag) for BED score.\n\t\t- Default for BED is to use mapping quality.\n\t\t- Default for BEDPE is to use the minimum of\n\t\t  the two mapping qualities for the pair.\n\t\t- When -ed is used with -bedpe, the total edit\n\t\t  distance from the two mates is reported.\n\n\t-tag\tUse other NUMERIC BAM alignment tag for BED score.\n\t\t- Default for BED is to use mapping quality.\n\t\t  Disallowed with BEDPE output.\n\n\t-color\tAn R,G,B string for the color used with BED12 format.\n\t\tDefault is (255,0,0).\n\n\t-cigar\tAdd the CIGAR string to the BED entry as a 7th column."
 stdout: $(inputs.bam.path.replace(/^.*[\\\/]/, '').replace(/\.[^/.]+$/, "") + '.bed')
