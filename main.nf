#!/usr/bin/env nextflow

include { seqQC; mafftAlign; alnQC } from './modules/SequenceQC.nf'
include { maskAln; iqtree; treePrune; treeQC } from './modules/MaskingAndTreeQC.nf'

workflow seq_qc {
    // Define the input channels
    take:
    inFasta_ch
    inMetadata_ch
    inMinLen_ch
    inMaxN_ch

    // Call the functions
    main:
    seqQC(inFasta_ch, inMetadata_ch, inMinLen_ch, inMaxN_ch)
    mafftAlign(seqQC.out.seq_qc_fasta)
    alnQC(mafftAlign.out.aln)
    
    emit:
    aln_tuple = mafftAlign.out.aln
    mask_tuple = alnQC.out.mask
}

workflow mask_aln {
    // Define the input channels
    take:
    aln_in
    mask_in

    main:
    maskAln(aln_in, mask_in)

    emit:
    maskAln_tuple = maskAln.out.masked_aln

}

workflow tree_qc {
    // Define the input channels
    take:
    aln_in

    main:
    iqtree(aln_in)
    if (params.outgroup) {
        treePrune(iqtree.out.treefile)
        treeQC(treePrune.out.pruned_tree, aln_in, iqtree.out.asr_file)
    } else {
        treeQC(iqtree.out.treefile, aln_in, params.asr_file)
    }
    


}

workflow {
    
    // Define the workflow inputs
    print (workflow.profile)
    // Initially check if the profile is test or not - this is to let epi2me run the test profile.
    if (workflow.profile.contains("test")) {
        input_fasta = file("${projectDir}/assets/test_data")
    } else {   
        input_fasta = file("${params.fasta}")
    }
    print input_fasta
    // check if params.fasta is a directory or a file.
    if ( input_fasta.extension.equals("fasta") || input_fasta.extension.equals("fa")) {
        inFasta_ch = Channel.fromPath(input_fasta).map { [it.baseName, it] }
    } else {
        input_dir_files = file(input_fasta).list()
        fasta_extensions = [".fasta", ".fa"]
        matching_files =  input_dir_files.findAll { a -> fasta_extensions.any { a.contains(it) } }
        input_files = matching_files.collect {"$input_fasta/$it"}
        inFasta_ch = Channel.fromPath(input_files).collect().map { [input_fasta.baseName, it] }
    }
    print input_fasta
    // Metadata is optional, and can also be either a file or dir
    // Will deal with optional input as per https://nextflow-io.github.io/patterns/optional-input/
    input_metadata = file("${params.metadata}")
    if ( input_metadata.extension.equals("csv") || input_metadata.extension.equals("tsv") || input_metadata.extension.equals("tab")) { 
        inMetadata_ch = Channel.fromPath("${input_metadata}")
    } else if (file("${params.metadata}").name != 'NO_FILE') {
        input_dir_files = file("${params.metadata}").list()
        metadata_extensions = [".csv", ".tsv", ".tab"]
	    matching_files =  input_dir_files.findAll { a -> metadata_extensions.any { a.contains(it) } }
	    input_metadata_files = matching_files.collect {"$input_metadata/$it"}
        inMetadata_ch = Channel.fromPath(input_metadata_files).collect()
    } else {
        print ("No Metadata provided")
        inMetadata_ch = Channel.fromPath("${input_metadata}")
    }
    // Extra inputs
    inMinLen_ch = Channel.value("${params.min_length}")
    inMaxN_ch = Channel.value("${params.max_n_content}")

    // Run the workflow
    // Choose to stop after alignment
    if (params.alignment_only == true) {
        seq_qc(inFasta_ch,inMetadata_ch,inMinLen_ch,inMaxN_ch)
    } else {
        seq_qc(inFasta_ch,inMetadata_ch,inMinLen_ch,inMaxN_ch)
        // Choose to use the generated mask or not
        if (params.run_mask == true) {
            mask_aln(seq_qc.out.aln_tuple, seq_qc.out.mask_tuple)
            tree_qc(mask_aln.out.maskAln_tuple)
        } else {
            tree_qc(seq_qc.out.aln_tuple)
        }
    }
}