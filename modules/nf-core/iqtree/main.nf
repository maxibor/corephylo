process IQTREE {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? 'bioconda::iqtree=2.1.4_beta' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/iqtree:2.1.4_beta--hdcc8f71_0' :
        'quay.io/biocontainers/iqtree:2.1.4_beta--hdcc8f71_0' }"

    input:
    tuple val(meta), path(alignment)
    val constant_sites

    output:
    tuple val(meta), path("*.treefile")      , emit: phylogeny
    tuple val(meta), path("*.log")           , emit: log
    tuple val(meta), path("*.rootstrap.nex") , emit: rootstrap, optional: true
    tuple val(meta), path("*.bionj")         , emit: bionj, optional: true
    tuple val(meta), path("*.contree")       , emit: contree, optional: true
    tuple val(meta), path("*.roottest.csv")  , emit: roottest, optional: true
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def fconst_args = constant_sites ? "-fconst $constant_sites" : ''
    def memory      = task.memory.toString().replaceAll(' ', '')
    def prefix = task.ext.prefix ?: "${meta.id}"
    def cpus = task.ext.cpu_auto ? "AUTO -ntmax ${task.cpus}" : "${task.cpus}"
    """
    iqtree \\
        $args \\
        -pre $prefix \\
        $fconst_args \\
        -s $alignment \\
        -nt $cpus \\
        -mem $memory

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: \$(echo \$(iqtree -version 2>&1) | sed 's/^IQ-TREE multicore version //;s/ .*//')
    END_VERSIONS
    """
}
