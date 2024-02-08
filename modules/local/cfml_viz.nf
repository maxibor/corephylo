process CFML_VIZ {
    tag "${meta.id}"
    label 'process_single'

    conda (params.enable_conda ? "bioconda::r-phangorn=2.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-phangorn:2.4.0--r351h9d2a408_0' :
        'quay.io/biocontainers/r-phangorn:2.4.0--r351h9d2a408_0' }"

    input:
    tuple val(meta), path(newick), path(pos_ref), path(ml_fasta), path(status)

    output:
    path("*.pdf"), emit: pdf

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = task.ext.extension ?: 'fas'

    """
    cfml_results.R $prefix
    """
}
