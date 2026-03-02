process seqQC {
    container "${params.container}@${params.container_sha}"
    conda "${HOME}/miniconda3/envs/raccoon"

    publishDir "output/${input_fasta.baseName}/seq-qc/", mode: "copy"
    
    debug true

    input:
    path input_fasta
    path input_metadata
    val min_length
    val max_n

    output:
    tuple val(input_fasta.baseName), path("*.seq_qc.fasta"), emit: seq_qc_fasta
    path "*"

    script:
    // This bit of logic checks if the input is a single fasta or a directory of fastas
    if ( input_fasta.extension.equals("fasta") || input_fasta.extension.equals("fa")) {
        input_file = input_fasta;
    } else {
        input_path = file(input_fasta.toRealPath())
	    input_dir_files = input_path.list()
        fasta_extensions = [".fasta", ".fa"]
	    matching_files =  input_dir_files.findAll { a -> fasta_extensions.any { a.contains(it) } }
	    input_file = matching_files.collect {"$input_fasta/$it"}.join(" ")
    }
    if ( input_metadata.extension.equals("csv") || input_metadata.extension.equals("tsv")) { 
        input_metadata_file =  input_metadata
    } else {
        input_path = file(input_metadata.toRealPath())
	    input_dir_files = input_path.list()
        metadata_extensions = [".csv", ".tsv",".tab"]
	    matching_files =  input_dir_files.findAll { a -> metadata_extensions.any { a.contains(it) } }
	    input_metadata_file = matching_files.collect {"$input_metadata/$it"}.join(" ")
    }
    
    // Parse any extra flags
    extra = ""

    """
    echo -e "\nInput --fasta: ${input_fasta}\nFound the following file(s): ${input_file}\n\nInput --metadata: ${input_metadata}\nFound the following metadata file(s): ${input_metadata_file}"
    raccoon seq-qc ${input_file} -o ${input_fasta.baseName}.seq_qc.fasta --metadata ${input_metadata_file} --min-length ${min_length} --max-n-content ${max_n} ${extra}
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
    """
    raccoon aln-qc ${aln_fasta}
    """
}