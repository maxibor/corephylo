process ROOT_REMOVE {
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::biopython=1.81" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython:1.81' :
        'quay.io/biocontainers/biopython:1.81' }"

    input:
    tuple val(meta), path(input_tree)

    output:
    tuple val(meta), path("core_genome_root_no_outgroup.nwk"), emit: nwk

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def extension = task.ext.extension ?: 'fas'

    """
    root_and_remove_outgroup.py \\
        --tree_file ${input_tree} \\
        --root_node x \\
        --output_file core_genome_root_no_outgroup.nwk
    """
}
