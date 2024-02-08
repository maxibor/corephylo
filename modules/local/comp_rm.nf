process COMP_RM {
    tag "${meta.id}"
    label 'process_single'

    conda (params.enable_conda ? "bioconda::pysam=0.22" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pysam:0.22.0--py38h15b938a_0' :
        'quay.io/biocontainers/pysam:0.22.0--py38h15b938a_0' }"

    input:
    tuple val(meta), path(cfml_em)

    output:
    path("*_rm.tsv"), emit: rm_tsv

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension = task.ext.extension ?: 'fas'

    """
    compute_rm.py $cfml_em $prefix
    """
}
