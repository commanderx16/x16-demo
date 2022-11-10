#!/usr/bin/env python3

# Copyright (c) 2019, Frank Buss
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

import sys
import argparse
import os
import codecs

# parse arguments
parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
    description='Converts a BAS files (text format) to PRGs (X16 native format) with the emulator.')
parser.add_argument('emulator', help='path to the x16emu program')
parser.add_argument('input', help='the input directory with BAS files')
parser.add_argument('output', help='the PRG output directory')
args = parser.parse_args()

for f in os.listdir(args.input):
    if f.upper().endswith('.BAS'):
        basFilename = args.input + "/" + f
        print("converting file %s..." % basFilename, flush=True)
        prg = f.upper()[:-4] + ".PRG"
        prgFilename = args.output + "/" + prg
        prg = prg + ".TMP"

        # read BASIC text file
        with codecs.open(basFilename, "rb") as input:
            bas = input.read()

        # add SAVE and exit command, and save as temporary file
        bas = bas + ('\nSAVE "' + prg + '\nPOKE $9FB4,0\nSYS $FFFF\n"').encode('iso-8859-1')
        tempFilename = args.input + ".tmp"
        with open(tempFilename, "wb") as output:
            output.write(bas)

        # call the emulator to create the PRG file
        # do not require sound output (needed for CI)
        os.system(args.emulator + " -sound none -bas " + tempFilename)
        
        # copy output to the final directoy
        os.rename(prg, prgFilename)

        # remove the temporary file
        os.remove(tempFilename)
