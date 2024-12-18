process PANAROO_INTEGRATE {
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::panaroo=1.2.9" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/panaroo:1.2.9--pyhdfd78af_0':
        'quay.io/biocontainers/panaroo:1.2.9--pyhdfd78af_0' }"

    input:
    path(gff)
    path(panaroo_in)

    output:
    path("results_outgroup/*")                            , emit: results
    path("results_outgroup/aligned_gene_sequences/*.fas") , optional: true, emit: fas
    path("results_outgroup/core_gene_alignment.aln")      , optional: true, emit: aln
    path("results_outgroup/pan_genome_reference.fa")      , optional: true, emit: pan_genome_reference
    path "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p panaroo_results
    ls | grep -v panaroo_results | xargs -I {} mv {} panaroo_results
    mv panaroo_results/$gff .

    panaroo-integrate \\
        $args \\
        -t $task.cpus \\
        -d panaroo_results \\
        -o results_outgroup \\
        -i $gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        panaroo: \$(echo \$(panaroo --version 2>&1) | sed 's/^.*panaroo //' ))
    END_VERSIONS
    """
}
