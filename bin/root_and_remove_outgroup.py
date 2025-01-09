#!/usr/bin/env python

import argparse
from Bio import Phylo

def root_and_remove_node(tree_file, root_node, output_file):
    """Root a tree at a specific node, remove the node, and save the result.

    Args:
        tree_file (str): Path to the input Newick tree file.
        root_node (str): Name of the node to root the tree at.
        output_file (str): Path to save the modified Newick tree.
    """
    # Read the tree
    tree = Phylo.read(tree_file, "newick")

    # Root the tree at the specified node
    try:
        tree.root_with_outgroup(root_node)
    except ValueError:
        raise ValueError(f"Node '{root_node}' not found in the tree.")

    # # Remove the node by collapsing it
    # for clade in tree.find_clades():
    #     if clade.name == root_node:
    #         parent = tree.root
    #         parent.branch_length = None
    #         parent.clades.remove(clade)
    #         break
    # else:
    #     raise ValueError(f"Node '{root_node}' could not be removed.")

    # # Write the modified tree to the output file

    all_nodes = []
    for t in tree.get_terminals():
        if t.name != root_node:
            all_nodes.append(t.name)

    common_ancestor = tree.common_ancestor(all_nodes)

    Phylo.write(common_ancestor, output_file, "newick")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Root a Newick tree at a specified node, remove the node, and save the result.")
    parser.add_argument("--tree_file", required=True, help="Path to the input Newick tree file.")
    parser.add_argument("--root_node", required=True, help="Name of the node to root the tree at.")
    parser.add_argument("--output_file", required=True, help="Path to save the modified Newick tree.")

    args = parser.parse_args()

    try:
        root_and_remove_node(args.tree_file, args.root_node, args.output_file)
        print(f"Modified tree saved to {args.output_file}")
    except Exception as e:
        print(f"Error: {e}")
