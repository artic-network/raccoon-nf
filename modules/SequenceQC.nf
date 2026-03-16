process seqQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/seq-qc/", mode: "copy"
    
    debug true

    input:
    tuple val(input_ID), path(input_fasta)
    path input_metadata
    val min_length
    val max_n

    output:
    tuple val(input_ID), path("*.seq_qc.fasta"), emit: seq_qc_fasta
    path "*"

    script:
    // Parse any extra flags
    extra = ""
    if (input_metadata.name != 'NO_FILE') {
        extra += " --metadata ${input_metadata}"
    }
    if (params.metadata_delimiter) {
        extra += " --metadata-delimiter '${params.metadata_delimiter}'"
    }
    if (params.metadata_id_field) {
        extra += " --metadata-id-field ${params.metadata_id_field}"
    }
    if (params.metadata_location_field) {
        extra += " --metadata-location-field ${params.metadata_location_field}"
    }
    if (params.metadata_date_field) {
        extra += " --metadata-date-field ${params.metadata_date_field}"
    }
    if (params.seq_id_delimiter) {
        extra += " --seq-id-delimiter '${params.seq_id_delimiter}'"
    }
    if (params.seq_id_field_index) {
        extra += " --seq-id-field-index ${params.seq_id_field_index}"
    }
    if (params.header_separator) {
        extra += " --header-separator '${params.header_separator}'"
    }
    if (params.custom_header_fields) {
        extra += " --header-fields '${params.custom_header_fields}'"
    } else {
        extra += " --header-fields '${params.header_fields}'"
    }

    """
    echo -e "\nFound the following fasta file(s): ${input_fasta}\n\nFound the following metadata file(s): ${input_metadata}"
    raccoon seq-qc --fasta ${input_fasta} --outfile ${input_ID}.seq_qc.fasta --min-length ${min_length} --max-n-content ${max_n} ${extra}
    """
}

process mafftAlign {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/mafft/", pattern: "*.aln.fasta", mode: "copy"

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

    publishDir "output/${input_ID}/aln-qc/", mode: "copy"
    
    input:
    tuple val(input_ID), path(aln_fasta)
    
    output:
    tuple val(input_ID), path("mask_sites.csv"), emit: mask
    path "*"

    script:
    // Parse any extra flags
    extra = ""
    // Standardise n content thresholds between aln-qc and seq-qc
    extra += " --max-n-content ${params.max_n_content}"
    
    if (params.cluster_window) {
        extra += " --cluster-window ${params.cluster_window}"
    }
    if (params.cluster_count) {
        extra += " --cluster-count ${params.cluster_count}"
    }
    if (params.no_flag_clustered == true) {
        extra += " --no-flag-clustered"
    }
    if (params.no_flag_n_adjacent == true) {
        extra += " --no-flag-n-adjacent"
    }
    if (params.no_flag_gap_adjacent == true) {
        extra += " --no-flag-gap-adjacent"
    }
    if (params.no_flag_frame_break == true) {
        extra += " --no-flag-frame-break"
    }
    if (params.flag_removal_threshold == true) {
        extra += " --flag-removal-threshold ${params.flag_removal_threshold}"
    }
    
    """
    raccoon aln-qc ${aln_fasta} ${extra}
    """
}