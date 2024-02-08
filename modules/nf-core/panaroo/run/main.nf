process PANAROO_RUN {
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::panaroo=1.2.9" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/panaroo:1.2.9--pyhdfd78af_0':
        'quay.io/biocontainers/panaroo:1.2.9--pyhdfd78af_0' }"

    input:
    path(gff)

    output:
    path("results/*")                                      , emit: results
    path("results/aligned_gene_sequences/*.fas")           , optional: true, emit: fas
    path("results/core_gene_alignment.aln")                , optional: true, emit: aln
    path("results/pan_genome_reference.fa")                 , optional: true, emit: pan_genome_reference
    path "versions.yml"                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    panaroo \\
        $args \\
        -t $task.cpus \\
        -o results \\
        -i *.gff3 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        panaroo: \$(echo \$(panaroo --version 2>&1) | sed 's/^.*panaroo //' ))
    END_VERSIONS
    """
}
