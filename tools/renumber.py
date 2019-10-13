#!/usr/bin/env python3

# Renumber a BASIC PROGRAM.
# Manage GOTO AND GOSUB Calls too

# Copyright (c) 2019, Giovanni Giorgi
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


import sys,re
from pathlib import Path
import click

LINE_FINDER=re.compile("([0-9]+)", re.IGNORECASE)


def collect_numbers(fname, start_from=10, increment=10):
    old2new={}    
    new_line_number=start_from
    with open(fname, "r") as f:
        for current_line in f:    
            possibile_number=LINE_FINDER.findall(current_line)
            #print(current_line,possibile_number)
            if(len(possibile_number)>=1):
                current_number=int(possibile_number[0])
                old2new[current_number]=new_line_number
                new_line_number=new_line_number+increment
    return old2new

def renumber_file(fname,old2new, postfix=".new"):
    dest_filename=fname+postfix
    with open(dest_filename, "w") as dest:
        with open(fname,"r") as source:
            for current_line in source:
                possibile_number=LINE_FINDER.findall(current_line)
                if(len(possibile_number)>=1):
                    new_number=old2new[int(possibile_number[0])]
                    ## renumbered_line=re.sub("([0-9]+) ",str(new_number)+" ",current_line,count=1)           
                    renumbered_line=LINE_FINDER.sub(str(new_number),current_line,count=1)                    
                    #print(current_line," ->", renumbered_line)
                    dest.write(renumbered_line)
                else:
                    dest.write(current_line)
    return dest_filename

def fix_goto_gosub(fname,old2new):
    """
    A second pass is needed to correct the GOTO/GOSUB
    This code also work with on...goto/gosub 
    """
    GOTO_FINDER=re.compile(r'GO(TO|SUB| TO) ([0-9]+)([:]*)', re.IGNORECASE)
    temp_filename=fname+".tmp"
    with open(temp_filename, "w") as dest:
        with open(fname,"r") as source:
            for current_line in source:
                possible_goto=GOTO_FINDER.findall(current_line)
                dest_line=current_line
                for m in GOTO_FINDER.finditer(current_line.rstrip("\n\r")):
                    goto_str=m.group(1)
                    old_line=int(m.group(2))
                    new_goto_number=old2new[old_line]
                    # Compose the new GO TO GOSUB etc
                    new_goto="GO"+m.group(1)+" "+str(new_goto_number)+m.group(3)
                    # Single replace
                    dest_line=dest_line.replace(m.group(0), new_goto,1)
                    #print ("s/"+m.group(0)+"/"+new_goto+"/",dest_line)
                dest.write(dest_line)    
    return (Path(temp_filename)).replace(fname)

@click.option("--start",  default=10, help="Start renumber from")
@click.option("--increment",  default=10, help="Increment factor")
@click.argument("basic_files", nargs=-1, required=True)
@click.command()
def main(basic_files: list, start,increment):
    """ Renumber BASIC v2 Programs
        Support GOTO/GOSUB renumbering via a simple two-pass algorithm

        Known limitations: also renumber strings containing GOTO <number> because it is unable to skip 
        quoted strings.

        Author: Giovanni Giorgi 
    """
    for fname in basic_files:
        print("Renumbering",fname)
        old2new=collect_numbers(fname,start,increment)        
        dest_filename=renumber_file(fname,old2new)
        fix_goto_gosub(dest_filename,old2new)
        Path(dest_filename).replace(fname)


if __name__ == "__main__":
    main()
