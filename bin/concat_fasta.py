#!/usr/bin/env python

import argparse
from textwrap import wrap

def concatenate_fasta(input_file, output_file, seqname, linker):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        sequences = []
        current_seq = ''
        for line in infile:
            if line.startswith('>'):
                if current_seq:
                    sequences.append(current_seq)
                current_seq = ''
            else:
                current_seq += line.strip()
        if current_seq:
            sequences.append(current_seq)

        # Join sequences with the linker
        concatenated_sequence = wrap(linker.join(sequences), 80)

        # Write the concatenated sequence to output file
        outfile.write(f">{seqname}\n")
        for s in concatenated_sequence:
            outfile.write(f"{s}\n")

def main():
    parser = argparse.ArgumentParser(description="Concatenate all sequences in a multi-FASTA file with a linker.")
    parser.add_argument('input', help="Input multi-FASTA file")
    parser.add_argument('output', help="Output FASTA file")
    parser.add_argument('--linker', default='NNNNNNNNNNNNNNNNNN', help="Linker sequence to separate the sequences (default: 'NNNNNNNNNNNNNN')")
    parser.add_argument('--seqname', help='Output FASTA sequence name', default='outgroup')
    args = parser.parse_args()

    concatenate_fasta(args.input, args.output, args.seqname, args.linker)

if __name__ == "__main__":
    main()
