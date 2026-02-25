process seqQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "results/${input_fasta.baseName}/seq-qc/"

    input:
    path input_fasta
    path input_metadata
    val min_length
    val max_n

    output:
    tuple val(input_fasta.baseName), path("*.seq_qc.fasta"), emit: seq_qc_fasta
    path "*"

    script:
    """
    raccoon seq-qc ${input_fasta} -o ${input_fasta.baseName}.seq_qc.fasta --metadata ${input_metadata} --metadata-id-field accessionVersion --metadata-location-field geoLocCountry --metadata-date-field sampleCollectionDate --min-length ${min_length} --max-n-content ${max_n}
    """
}

process mafftAlign {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "results/${input_ID}/mafft/", pattern: "*.aln.fasta"

    input:
    tuple val(input_ID), path(qc_fasta)

    output:
    tuple val(input_ID), path("*.aln.fasta"), emit: aln

    script:
    """
    mafft ${qc_fasta} > ${input_ID}.aln.fasta
    """
}

process alnQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "results/${input_ID}/aln-qc/"
    
    input:
    tuple val(input_ID), path(aln_fasta)
    
    output:
    tuple val(input_ID), path("mask_sites.csv"), emit: mask
    path "*"

    script:
    """
    raccoon aln-qc ${aln_fasta}
    """
}