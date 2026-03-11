process maskAln {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/mask_alignment/", mode: "copy"

    input:
    tuple val(input_ID), path(aln_file)
    tuple val(input_ID), path(mask_file)

    output:
    tuple val(input_ID), path("*.aln.masked.fasta"), emit: masked_aln
    path "*"

    script:
    """
    raccoon mask ${aln_file} --mask-file ${mask_file}
    """
}

process iqtree {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/tree/", pattern: "*", mode: "copy"

    input:
    tuple val(input_ID), path(aln_file)

    output:
    tuple val(input_ID), path("*.treefile"), emit: treefile
    path "*.fasta.state", emit: asr_file, optional: true
    path "*"

    script:
    // Parse any extra flags
    extra = ""
    extra += " -m ${params.tree_model}"
    if (params.outgroup) {
        extra += " -asr -o '${params.outgroup}'"
    }
    """
    iqtree -s ${aln_file} -czb -blmin 0.00000001 ${extra}
    """
}

process treePrune {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/pruned_tree/", pattern: "*", mode: "copy"

    input:
    tuple val(input_ID), path(treefile)

    output:
    tuple val(input_ID), path("*.pruned.tree"), emit: pruned_tree
    path "*"

    script:
    // Parse any extra flags
    extra = ""
    if (params.outgroup) {
        extra += " -t '${params.outgroup}'"
    }
    """
    jclusterfunk prune -i "${treefile}" -o '${input_ID}.pruned.tree' ${extra}
    """
}

process treeQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/tree-qc/", mode: "copy"

    input:
    tuple val(input_ID), path(treefile)
    tuple val(input_ID), path(masked_aln)
    path asr_file

    output:
    path "*"

    script:
    // Parse any extra flags
    extra = ""

    if (asr_file.name != 'NO_FILE') {
        extra += " --asr-state ${asr_file}"
    }
    if (params.long_branch_sd) {
        extra += " --long-branch-sd ${params.long_branch_sd}"
    }
    if (params.run_adar == true) {
        extra += " --run-adar"
    }
    if (params.adar_window) {
        extra += " --adar-window ${params.adar_window}"
    }
    if (params.adar_min_count) {
        extra += " --adar-min-count ${params.adar_min_count}"
    }
    if (params.run_apobec == true) {
        extra += " --run-apobec"
    }
    if (params.tip_fields) {
        extra += " --tip-fields ${params.tip_fields}"
    } 
    if (params.tip_field_delimiter) {
    extra += " --tip-field-delimiter ${params.tip_field_delimiter}"
    }
    if (params.tip_date_field) {
    extra += " --tip-date-field ${params.tip_date_field}"
    }
    if (params.midpoint_root == true) {
    extra += " --midpoint-root"
    }


    if (params.fig_height) {
        extra += " --height ${params.fig_height}"
    }
    
    """
    raccoon tree-qc --tree '${treefile}' --alignment ${masked_aln} ${extra}
    """
}
