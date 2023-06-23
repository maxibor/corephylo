/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// // Validate input parameters
WorkflowCorephylo.initialise(params, log)

def checkPathParamList = [ params.genomes ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.genomes) { ch_input = file(params.genomes) } else { exit 1, 'Genomes samplesheet not specified!' }

/*

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DATABASES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_bakta_db = Channel.fromPath(params.bakta_db, checkIfExists: true).first()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { GUNZIP                                       } from '../modules/nf-core/gunzip/main'
include { BAKTA                                        } from '../modules/nf-core/bakta/main'
include { PANAROO_RUN                                  } from '../modules/nf-core/panaroo/run/main'
include { CLONALFRAMEML                                } from '../modules/nf-core/clonalframeml/main'
include { MASKRC                                       } from '../modules/local/maskrc/main'
include { IQTREE as IQTREE_PRE ; IQTREE as IQTREE_POST } from '../modules/nf-core/iqtree/main'
include { RAPIDNJ                                      } from '../modules/nf-core/rapidnj/main'
include { SNPSITES                                     } from '../modules/nf-core/snpsites/main'
include { SNPDISTS                                     } from '../modules/nf-core/snpdists/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS                  } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary

workflow COREPHYLO {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    // ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    INPUT_CHECK.out.fasta
        .branch {
            decompressed: ! it[1].toString().tokenize(".")[-1].contains('gz')
            compressed: it[1].toString().tokenize(".")[-1].contains('gz')
        }
        .set { genomes_fork }

    genomes_fork.decompressed
        .view()

    GUNZIP (
        genomes_fork.compressed
    )
    ch_versions = ch_versions.mix(GUNZIP.out.versions)

    GUNZIP.out.gunzip
        .mix( genomes_fork.decompressed )
        .set { genomes_pre_processed }

    BAKTA (
        genomes_pre_processed,
        ch_bakta_db,
        [],
        []
    )
    ch_versions = ch_versions.mix(BAKTA.out.versions)

    BAKTA.out.gff
        .map {meta, gff -> [gff] }
        .collect()
        .set { gffs }

    PANAROO_RUN(
        gffs
    )
    ch_versions = ch_versions.mix(PANAROO_RUN.out.versions)

    PANAROO_RUN.out.aln
        .map { it ->
            def meta = [:]
            meta.id = "core_genome"
            [meta, it]
        }
        .set { core_genome_ch }

    IQTREE_PRE (
        core_genome_ch,
        []
    )
    ch_versions = ch_versions.mix(IQTREE_PRE.out.versions)

    CLONALFRAMEML(
        IQTREE_PRE.out.phylogeny
        .join (core_genome_ch)
    )
    ch_versions = ch_versions.mix(CLONALFRAMEML.out.versions)

    MASKRC(
        CLONALFRAMEML.out.newick
        .join(CLONALFRAMEML.out.status)
        .join(core_genome_ch)
    )
    ch_versions = ch_versions.mix(MASKRC.out.versions)

    RAPIDNJ (
        MASKRC.out.aln
    )

    IQTREE_POST (
        MASKRC.out.aln,
        []
    )

    SNPSITES(
        MASKRC.out.aln
    )
    ch_versions = ch_versions.mix(SNPSITES.out.versions)

    SNPDISTS(
        MASKRC.out.aln
    )
    ch_versions = ch_versions.mix(SNPDISTS.out.versions)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.adaptivecard(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
