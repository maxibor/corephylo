process CORECOMB {
    label 'process_single'

    conda (params.enable_conda ? "bioconda::pysam=0.22" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.0--py38h15b938a_0' :
        'quay.io/biocontainers/pysam:0.22.0--py38h15b938a_0' }"

    input:
    path(core_gene_alignments)
    path(pan_genome_reference)

    output:
    path("corecomb.xmfa"), emit: xmfa

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def extension = task.ext.extension ?: 'fas'

    """
    corecomb.py \\
        --gene_al_dir . \\
        --pan_fa $pan_genome_reference \\
        --extension $extension \\
        --outfile corecomb.xmfa
    """
}
