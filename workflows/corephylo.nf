/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

if (params.genomes) { ch_input = file(params.genomes) } else { exit 1, 'Genomes samplesheet not specified!' }


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
include { BAKTA_BAKTA                                  } from '../modules/nf-core/bakta/bakta/main'
include { PANAROO_RUN                                  } from '../modules/nf-core/panaroo/run/main'
include { PANAROO_INTEGRATE                            } from '../modules/local/panaroo/integrate/main'
include { CLONALFRAMEML                                } from '../modules/nf-core/clonalframeml/main'
include { CORECOMB                                     } from '../modules/local/corecomb'
include { COMP_RM                                      } from '../modules/local/comp_rm'
include { CFML_VIZ                                     } from '../modules/local/cfml_viz'
include { IQTREE as IQTREE_PRE ;
          IQTREE as IQTREE_POST ;
          IQTREE as IQTREE_ROOT                        } from '../modules/nf-core/iqtree/main'
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

    GUNZIP (
        genomes_fork.compressed
    )
    ch_versions = ch_versions.mix(GUNZIP.out.versions)

    GUNZIP.out.gunzip
        .mix( genomes_fork.decompressed )
        .set { genomes_pre_processed }

    BAKTA_BAKTA (
        genomes_pre_processed,
        ch_bakta_db,
        [],
        []
    )
    ch_versions = ch_versions.mix(BAKTA_BAKTA.out.versions)

    BAKTA_BAKTA.out.gff.dump(tag: 'bakta_gff', pretty: true)

    BAKTA_BAKTA.out.gff
        .branch {
            ingroup: it[0]['group'] == 'ingroup'
            outgroup: it[0]['group'] == 'outgroup'
        }
        .set { gffs }

    gffs.ingroup.map {meta, gff -> [gff] }.collect().set { ingroup_gffs }
    gffs.outgroup.map {meta, gff -> [gff] }.set{ outgroup_gff }

    if (params.root_method == 'outgroup') {
        PANAROO_RUN (
            ingroup_gffs
        )
    } else {
        PANAROO_RUN (
            ingroup_gffs.mix(outgroup_gff).collect()
        )
    }

    ch_versions = ch_versions.mix(PANAROO_RUN.out.versions)

    core_genome_ch = Channel.empty()

    if (params.root_method == 'outgroup') {
        PANAROO_INTEGRATE(
            outgroup_gff,
            PANAROO_RUN.out.results
        )

        core_genome_ch = core_genome_ch.mix(
            PANAROO_INTEGRATE.out.aln
                .map {
                    def meta = [:]
                    meta.id = "core_genome"
                    [meta, it]
                }
        )

        CORECOMB(
            PANAROO_INTEGRATE.out.fas,
            PANAROO_INTEGRATE.out.pan_genome_reference
        )
    } else {

        core_genome_ch = core_genome_ch.mix(
            PANAROO_RUN.out.aln
                .map { it ->
                    def meta = [:]
                    meta.id = "core_genome"
                    [meta, it]
                }
        )

        CORECOMB (
            PANAROO_RUN.out.fas,
            PANAROO_RUN.out.pan_genome_reference
        )
    }

    core_genome_ch.dump(tag: 'core_genome_ch', pretty: true)

    IQTREE_PRE (
        core_genome_ch,
        []
    )
    ch_versions = ch_versions.mix(IQTREE_PRE.out.versions)

    CLONALFRAMEML(
        IQTREE_PRE.out.phylogeny,
        CORECOMB.out.xmfa
    )
    ch_versions = ch_versions.mix(CLONALFRAMEML.out.versions)

    COMP_RM(
        CLONALFRAMEML.out.em
    )

    CFML_VIZ(
        CLONALFRAMEML.out.newick.join(
            CLONALFRAMEML.out.pos_ref
        ).join(
            CLONALFRAMEML.out.ml_fasta
        ).join(
            CLONALFRAMEML.out.status
        )
    )

    RAPIDNJ (
        CLONALFRAMEML.out.filtered
    )

    IQTREE_POST (
        CLONALFRAMEML.out.filtered,
        []
    )

    if (params.root_method == 'nonrev') {
        IQTREE_ROOT (
            CLONALFRAMEML.out.filtered,
            []
        )
    }

    SNPSITES(
        CLONALFRAMEML.out.filtered
    )
    ch_versions = ch_versions.mix(SNPSITES.out.versions)

    SNPDISTS(
        CLONALFRAMEML.out.filtered
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
