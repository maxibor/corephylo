process MSACONVERTER {
    tag "$meta.id"
    label 'process_single'

    conda (params.enable_conda ? 'bioconda::msaconverter=0.0.4-0' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/msaconverter:0.0.4--pyhdfd78af_0' :
        'quay.io/biocontainers/msaconverter:0.0.4--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(msa)
    val (input_format)
    val (output_format)

    output:
    tuple val(meta), path({"*.${ext}"}), emit: converted_msa
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def ext = output_format.toString().toLowerCase().take(3)
    """
    msaconverter \\
        $args \\
        -i $msa \\
        -o ${prefix}.${ext} \\
        -p ${input_format} \\
        -q ${output_format}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iqtree: 0.0.4
    END_VERSIONS
    """
}
