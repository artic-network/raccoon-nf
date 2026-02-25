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
    """
    iqtree -s ${aln_file} -m HKY -czb -blmin 0.00000001 -asr -o 'PP_003MAAS.2||2019'
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
    """
    jclusterfunk prune -i "${treefile}" -t 'PP_003MAAS.2||2019' -o '${input_ID}.pruned.tree'
    """
}

process treeQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_ID}/tree-qc/", mode: "copy"

    input:
    tuple val(input_ID), path(pruned_treefile)
    tuple val(input_ID), path(masked_aln)
    path asr_file

    output:
    path "*"

    script:
    """
    raccoon tree-qc --phylogeny '${pruned_treefile}' --alignment ${masked_aln} --asr-state ${asr_file}
    """
}
