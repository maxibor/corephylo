process CONCAT_FASTA {
    label 'process_single'

    conda (params.enable_conda ? "bioconda::pysam=0.22" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.0--py38h15b938a_0' :
        'quay.io/biocontainers/pysam:0.22.0--py38h15b938a_0' }"

    input:
    tuple val(meta), path(multifasta)

    output:
    tuple val(meta), path({ "outgroup.${extension}" } ), emit: fa

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    extension = task.ext.extension ?: 'fa'

    """
    concat_fasta.py \\
        --seqname ${prefix} \\
        $args \\
        ${multifasta} \\
        outgroup.${extension}
    """
}
