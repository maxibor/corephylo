#!/usr/bin/env python

import argparse
import pysam
from glob import glob
from pathlib import Path
from textwrap import wrap
import logging

logging.basicConfig(level=logging.INFO)

def replace_ambiguous(seq, alphabet=set(["A", "T", "C", "G", "N", "-"])):
    """Replace ambiguous characters in a sequence with Ns.
    Args:
        seq (str): Sequence to be cleaned.
        alphabet (set): Set of characters allowed.
    Returns:

    """
    seq = seq.upper()
    all_chars = set(seq)
    replace_chars = all_chars - alphabet
    trans_table = str.maketrans({char: "N" for char in replace_chars})
    return seq.translate(trans_table)

def write_xmfa(seqdict, gene_order, genomes, gene_aln_len, outfile):
    """Write XMFA file from ClonalFrameML input from Panaroo core-genome gene alignments

    Args:
        seqdict (dict): Dictionary of sequences for each genome for each gene
        gene_order (list): Ordered list of genes
        genomes(list): List of genomes in pangenome
        gene_aln_len (dict): Dictionary of gene alignment lengths
        outfile(str): Path to output XMFA file
    """
    i = 0
    with open(outfile, "w") as fw:
        for gene in gene_order:
            if gene in seqdict:
                fw.write(f"# {gene}\n")
                for genome in genomes:
                    if genome in seqdict[gene]:
                        fw.write(f">{genome}:{i}-{i+gene_aln_len[gene]}\n")
                        fw.write("\n".join(wrap(seqdict[gene][genome], 60)) + "\n")
                    else:
                        logging.warning(f"Genome {genome} is missing gene {gene}")
                        fw.write(f">{genome}\n")
                        fw.write("\n".join(wrap("-" * gene_aln_len[gene], 60)) + "\n")
                i += gene_aln_len[gene]
                fw.write("=\n")

def create_xmfa(args):
    """Create XMFA file from ClonalFrameML input from Panaroo core-genome gene alignments"""
    gene_al_dir = args.gene_al_dir
    pan_fa = args.pan_fa
    exclude = args.exclude
    extension = args.extension
    outfile = args.outfile

    logging.info(f"Reading gene order from {pan_fa}")
    gene_order = []
    for record in pysam.FastxFile(pan_fa):
        gene_order.append(record.name)

    logging.info(f"Reading gene alignments from {gene_al_dir} *.{extension} files")
    fas = [Path(p) for p in glob(f"{gene_al_dir}/*.{extension}")]
    if exclude:
        logging.info(f"Excluding genome {exclude}")

    seqdict = {}
    genomes = set()
    gene_aln_len = {}
    for gene in fas:
        gene_name = gene.name.split(".")[0]
        seqdict[gene_name] = {}
        for record in pysam.FastxFile(gene):
            gene_aln_len[gene_name] = len(record.sequence)
            recname = record.name.split(";")[0]
            if exclude != recname:
                genomes.add(recname)
            seqdict[gene_name][recname] = replace_ambiguous(record.sequence)
    genomes = sorted(genomes)

    logging.info(f"Writing XMFA file to {outfile}")
    write_xmfa(
        seqdict=seqdict,
        gene_order=gene_order,
        genomes=genomes,
        gene_aln_len=gene_aln_len,
        outfile=outfile,
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create XMFA file from core-genome alignments.")
    parser.add_argument(
        "--gene_al_dir",
        help="Path to directory containing core-genome gene alignments",
        default="core_gene_alignments",
    )
    parser.add_argument(
        "--pan_fa",
        default="pan_genome_reference.fa",
        help="Path to Panaroo pan_genome_reference.fa",
    )
    parser.add_argument(
        "--exclude",
        help="Name of genome to exclude from XMFA",
        default=None,
    )
    parser.add_argument(
        "--extension",
        default="fas",
        help="File extension of core-genome gene alignments",
    )
    parser.add_argument(
        "--outfile",
        default="corecomb.xmfa",
        help="Path to output XMFA file",
    )

    args = parser.parse_args()
    create_xmfa(args)
