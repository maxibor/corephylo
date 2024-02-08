#!/usr/bin/env python

import argparse
import pysam
from glob import glob
from pathlib import Path
from textwrap import wrap
import logging
import sys
from collections import defaultdict

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


def write_xmfa(seqdict, gene_order_pan, genomes, pan_fa, gene_aln_len, outfile):
    """Write XMFA file from ClonalFrameML input from Panaroo core-genome gene alignments

    Args:
        seqdict (dict): Dictionary of sequences for each genome for each gene
        gene_order_pan (list): Ordered list of genes from Panaroo pangenome
        genomes(list): List of genomes in pangenome
        pan_fa(str): Panaroo pan_genome_reference.fa
        gene_aln_len (dict): Dictionary of gene alignment lengths
        outfile(str): Path to output XMFA file
    """
    i = 0
    core_len = {genome: 0 for genome in genomes}
    not_in_pang = []
    gene_order = []
    not_in_pang = []
    for gene in seqdict:
        if gene in gene_order_pan:
            gene_order.append(gene)
        else:
            not_in_pang.append(gene)
    not_in_pang = sorted(not_in_pang)
    logging.warning(f"{len(not_in_pang)} genes not in Panaroo {pan_fa}: {', '.join(not_in_pang)}")
    with open(outfile, "w") as fw:
        for gene in gene_order+not_in_pang:
            for genome in genomes:
                core_len[genome] += len(seqdict[gene][genome])
                if genome in seqdict[gene]:
                    fw.write(f">{genome}:{i}-{i+gene_aln_len[gene]} {gene}\n")
                    fw.write("\n".join(wrap(seqdict[gene][genome], 60)) + "\n")
                else:
                    logging.warning(f"Genome {genome} is missing gene {gene}")
                    fw.write(f">{genome}\n")
                    fw.write("\n".join(wrap("-" * gene_aln_len[gene], 60)) + "\n")
            i += gene_aln_len[gene] + 1000
            fw.write("=\n")
    logging.info(f"Total length of core genome with CFML intergenic inserts: {i} bp")
    logging.info(f"XMFA file written to {outfile}")

def create_xmfa(gene_al_dir, pan_fa, extension="fas", outfile="corecomb.xmfa"):
    """Create XMFA file from ClonalFrameML input from Panaroo core-genome gene alignments"""
    logging.info(f"Reading gene order from {pan_fa}")
    gene_order = []
    for record in pysam.FastxFile(pan_fa):
        gene_order.append(record.name)

    logging.info(f"Reading gene alignments from {gene_al_dir} *.{extension} files")
    fas = [Path(p) for p in glob(f"{gene_al_dir}/*.{extension}")]

    seqdict = {}
    genomes = set()
    gene_aln_len = defaultdict(int)
    core_len = {}
    for gene in fas:
        gene_name = gene.name.split(".")[0]
        seqdict[gene_name] = {}
        for record in pysam.FastxFile(gene):
            gene_aln_len[gene_name] = max(gene_aln_len[gene_name], len(record.sequence))
            recname = record.name.split(";")[0]
            genomes.add(recname)
            seqdict[gene_name][recname] = replace_ambiguous(record.sequence)
            if gene_name not in core_len:
                core_len[gene_name] = {recname: len(record.sequence)}
            else:
                core_len[gene_name][recname] = len(record.sequence)
    logging.info(f"Total length of core genome : {sum(gene_aln_len.values())} bp")

    write_xmfa(
        seqdict=seqdict,
        gene_order_pan=gene_order,
        genomes=genomes,
        pan_fa=pan_fa,
        gene_aln_len=gene_aln_len,
        outfile=outfile,
    )

def parse_args():
    """Parse command-line arguments"""
    parser = argparse.ArgumentParser(description="Create XMFA file from Panaroo core-genome gene alignments")
    parser.add_argument(
        "--gene_al_dir",
        help="Path to directory containing core-genome gene alignments",
        type=str,
        default="core_gene_alignments",
    )
    parser.add_argument(
        "--pan_fa",
        default="pan_genome_reference.fa",
        type=str,
        help="Path to Panaroo pan_genome_reference.fa",
    )
    parser.add_argument(
        "--extension",
        default="fas",
        type=str,
        help="File extension of core-genome gene alignments",
    )
    parser.add_argument(
        "--outfile",
        default="corecomb.xmfa",
        type=str,
        help="Path to output XMFA file",
    )
    return parser.parse_args()

def main():
    """Coordinate argument parsing and program execution."""
    args = parse_args()
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    create_xmfa(
        gene_al_dir=args.gene_al_dir,
        pan_fa=args.pan_fa,
        extension=args.extension,
        outfile=args.outfile,
    )


if __name__ == "__main__":
    sys.exit(main())
