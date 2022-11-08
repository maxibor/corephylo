process MASKRC {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::maskrc-svg=0.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/maskrc-svg:0.5--1' :
        'quay.io/biocontainers/maskrc-svg:0.5--1' }"

    input:
    tuple val(meta), path(cfml_tree), path(cfml_rec), path(aln)

    output:
    tuple val(meta), path("*.aln"), emit: aln
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    """
    maskrc-svg.py \\
        $cfml \\
        $args \\
        --aln ${aln} \\
        --symbol "-" \\
        --out ${prefix}.masked.aln

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        maskrc-svg: \$( echo \$(maskrc-svg.py --version 2>&1) | sed 's/^.*maskrc-svg.py //' )
    END_VERSIONS
    """
}
