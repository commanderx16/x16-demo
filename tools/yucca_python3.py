# yucca -- dialect-agnostic static analyzer for 8-bit BASIC programs
# Version 1.1-pre
# GG Migrated to python3

# Copyright (c)2012 Chris Pressey, Cat's Eye Technologies
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

import re
import sys
import fileinput
from optparse import OptionParser


class Error(object):
    """An object representing one of the possible violations that yucca
    can raise in objection to a given BASIC program.

    """
    def __init__(self, line, line_number):
        self.line = line
        self.line_number = line_number


class UndefinedStatement(Error):
    def __str__(self):
        return '?UNDEFINED STATEMENT "%s" IN: %s' % (
            str(self.line_number).strip(), self.line.description)


class ComputedJump(Error):
    def __str__(self):
        return '?COMPUTED JUMP TO "%s" IN: %s' % (
            str(self.line_number).strip(), self.line.description)


class OutOfSequence(Error):
    def __str__(self):
        return '?OUT OF SEQUENCE LINE "%s" IN: %s' % (
            str(self.line_number).strip(), self.line.description)


class LineNumber(object):
    """An object representing the line number of a line in a
    BASIC program.

    The object retains any whitespace encountered while parsing
    the line, and outputs it in its string representation.

    """
    def __init__(self, text):
        self.text = text
        self.number = -1
        try:
            self.number = int(text)
        except ValueError:
            pass
    
    def __str__(self):
        return self.text

    def is_computed(self):
        return re.match(r'^\s*\d+\s*$', self.text) is None


class BasicCommand(object):
    @classmethod
    def create(class_, text):
        match = re.match(r'^(\s*rem)(.*)$', text, re.I)
        if match:
            return Remark(match.group(1), match.group(2))
        match = re.match(r'^(\s*goto)(.*?)$', text, re.I)
        if match:
            return Goto(match.group(1), LineNumber(match.group(2)))
        match = re.match(r'^(\s*gosub)(.*?)$', text, re.I)
        if match:
            return Gosub(match.group(1), LineNumber(match.group(2)))
        # I doubt many BASICs allow a computed goto right after a 'THEN'...
        match = re.match(r'^(\s*if(.*?)then)(\s*\d+\s*)$', text, re.I)
        if match:
            return IfThenLine(match.group(1), LineNumber(match.group(3)))
        match = re.match(r'^(\s*if(.*?)then)(.*?)$', text, re.I)
        if match:
            return IfThen(match.group(1), BasicCommand.create(match.group(3)))
        # We do this check *after* the above two, so as to not accidentally
        # match something like IF A THEN PRINT "HI":GOTO 50...
        match = re.match(r'^(\s*if(.*?)goto)(.*?)$', text, re.I)
        if match:
            return IfThenLine(match.group(1), LineNumber(match.group(3)))
        match = re.match(r'^(\s*on(.*?)go(to|sub))(.*?)$', text, re.I)
        if match:
            line_numbers = [LineNumber(x) for x in match.group(4).split(',')]
            return OnLines(match.group(1), line_numbers)
        return GenericCommand(text)

    def referenced_line_numbers(self):
        raise NotImplementedError


class GenericCommand(BasicCommand):
    def __init__(self, text):
        self.text = text

    def __str__(self):
        return self.text

    def referenced_line_numbers(self):
        return []


class Remark(BasicCommand):
    def __init__(self, command, text):
        self.command = command
        self.text = text

    def __str__(self):
        return "%s%s" % (self.command, self.text)

    def referenced_line_numbers(self):
        return []


class IfThen(BasicCommand):
    def __init__(self, body, subsequent):
        self.body = body
        self.subsequent = subsequent

    def __str__(self):
        return "%s%s" % (self.body, self.subsequent)

    def referenced_line_numbers(self):
        return self.subsequent.referenced_line_numbers()


class IfThenLine(BasicCommand):
    def __init__(self, body, line_number):
        self.body = body
        self.line_number = line_number

    def __str__(self):
        return "%s%s" % (self.body, self.line_number)

    def referenced_line_numbers(self):
        return [self.line_number]


class Goto(BasicCommand):
    def __init__(self, command, line_number):
        self.command = command
        self.line_number = line_number

    def __str__(self):
        return "%s%s" % (self.command, self.line_number)

    def referenced_line_numbers(self):
        return [self.line_number]


class Gosub(BasicCommand):
    def __init__(self, command, line_number):
        self.command = command
        self.line_number = line_number

    def __str__(self):
        return "%s%s" % (self.command, self.line_number)

    def referenced_line_numbers(self):
        return [self.line_number]


class OnLines(BasicCommand):
    def __init__(self, body, line_numbers):
        self.body = body
        self.line_numbers = line_numbers

    def __str__(self):
        return "%s%s" % (self.body,
                         ','.join(str(x) for x in self.line_numbers))

    def referenced_line_numbers(self):
        return self.line_numbers


class BasicLine(object):
    def __init__(self, text, text_file_line):
        self.line_number = None
        self.text_file_line = text_file_line
        if text is None:
            self.command = None
            return
        text = text.rstrip('\r\n')
        self.text = text
        match = re.match(r'^(\s*\d+\s*)(.*?)$', text)
        if match:
            self.line_number = LineNumber(match.group(1))
            text = match.group(2)

        self.commands = []

        index = 0
        start = 0
        state = 'start'
        while index < len(text):
            if state in ('start', 'cmd'):
                match = re.match(r'^rem', text[index:], re.I)
                if match:
                    state = 'remark'
                else:
                    state = 'cmd'
            if state == 'cmd':
                if text[index] == '"':
                    state = 'quoted'
                elif text[index] == ':':
                    cmd = BasicCommand.create(text[start:index])
                    self.commands.append(cmd)
                    start = index + 1
                    state = 'start'
            elif state == 'quoted':
                if text[index] == '"':
                    state = 'cmd'
            elif state == 'remark':
                pass
            index += 1
        cmd = BasicCommand.create(text[start:index])
        self.commands.append(cmd)

    def __str__(self):
        text = ':'.join(str(x) for x in self.commands)
        if self.line_number:
            return "%s%s" % (self.line_number, text)
        else:
            return text

    @property
    def description(self):
        """A description of this line, used in violation reports."""
        if self.line_number:
            return str(self)
        else:
            return "%s (immediate mode, text file line %d)" % \
                (self, self.text_file_line)

    def referenced_line_numbers(self):
        line_numbers = []
        for command in self.commands:
            line_numbers.extend(command.referenced_line_numbers())
        return line_numbers

    def strip_remarks(self):
        new_commands = []
        for command in self.commands:
            if not isinstance(command, Remark):
                new_commands.append(command)
        if new_commands:
            new_line = BasicLine(None, self.text_file_line)
            new_line.line_number = self.line_number
            new_line.commands = new_commands
            return new_line
        else:
            return None


class BasicProgram(object):
    r"""An object which represents a BASIC program.

    Rudimentary parsing of lines of commands:

    >>> b = BasicProgram('10 PRINT "HELLO"\n'
    ...                  '20 GOTO 10\n')
    >>> b.dump()
    10 PRINT "HELLO"
    20 GOTO 10
    >>> len(b.lines)
    2
    >>> print(b.lines[0].commands[0])
    PRINT "HELLO"
    >>> print(b.lines[1].commands[0].__class__.__name__)
    Goto

    Checking for jumps to non-existant line numbers:

    >>> b = BasicProgram()
    >>> b.add_line('10 PRINT "HELLO"', 1)
    >>> b.add_line('20 GOTO 30', 2)
    >>> len(b.lines)
    2
    >>> for e in b.check_line_numbers(): print(e)
    ?UNDEFINED STATEMENT "30" IN: 20 GOTO 30

    Checking for GOSUB and ON GOTO, and retaining case in
    error messages:

    >>> b = BasicProgram('5 goSUb 10\n'
    ...                  '7goSUb8\n'
    ...                  '10 oN (X+1 )* 5  gOtO 100,6')
    >>> for e in b.check_line_numbers(): print(e)
    ?UNDEFINED STATEMENT "8" IN: 7goSUb8
    ?UNDEFINED STATEMENT "100" IN: 10 oN (X+1 )* 5  gOtO 100,6
    ?UNDEFINED STATEMENT "6" IN: 10 oN (X+1 )* 5  gOtO 100,6

    Whitespace and case is retained when dumping a program:

    >>> b = BasicProgram('5 goSUb 10\n'
    ...                  '7gOSub8\n'
    ...                  '9   rem WHAT? ??:>?: >?\n'
    ...                  '\n'
    ...                  '800   PRINT::print:ZORK  30\n'
    ...                  '10 oN   ERROR  gOtO 100, 6,7,  800  ,3\n'
    ...                  ' 99 what  \n'
    ...                  'if50then60\n'
    ...                  '50ifthisstuffistruegoto70\n'
    ...                  '60 If  This Stuff Is True  Then   Print:GoTo  9\n'
    ... )
    >>> b.dump()
    5 goSUb 10
    7gOSub8
    9   rem WHAT? ??:>?: >?
    <BLANKLINE>
    800   PRINT::print:ZORK  30
    10 oN   ERROR  gOtO 100, 6,7,  800  ,3
     99 what  
    if50then60
    50ifthisstuffistruegoto70
    60 If  This Stuff Is True  Then   Print:GoTo  9

    Remarks may contain colons:

    >>> b = BasicProgram('10 REM HELLO: GOTO 20')
    >>> len(b.lines[0].commands)
    1
    >>> print(b.lines[0].commands[0].__class__.__name__)
    Remark
    >>> b.check_line_numbers()
    []

    Immediate mode commands are checked, and can be stripped:

    >>> b = BasicProgram('10 REM HELLO\n'
    ...                  'PRINT "HELLO"\n'
    ...                  'GOTO 20')
    >>> for e in b.check_line_numbers(): print(e)
    ?UNDEFINED STATEMENT "20" IN: GOTO 20 (immediate mode, text file line 3)
    >>> b.strip_immediate_mode_commands()
    >>> b.dump()
    10 REM HELLO
    >>> b.check_line_numbers()
    []

    Remarks, both on numbered lines and immediate mode, can be
    stripped:

    >>> b = BasicProgram('10 PRINT "HI":REM HELLO\n'
    ...                  'PRINT "HELLO"\n'
    ...                  'REM WHAT?\n'
    ...                  '20 GOTO 30\n'
    ...                  '30 REM THIS IS BUNK, MAN\n')
    >>> b.strip_remarks()
    >>> b.dump()
    10 PRINT "HI"
    PRINT "HELLO"
    20 GOTO 30
    >>> for e in b.check_line_numbers(): print(e)
    ?UNDEFINED STATEMENT "30" IN: 20 GOTO 30

    Proper (sequential) ordering of line numbers can be checked for.

    >>> b = BasicProgram('10 PRINT "HI":REM HELLO\n'
    ...                  'PRINT "IMMEDIATE MODE"\n'
    ...                  '20 GOTO 30\n'
    ...                  '30 PRINT "HI"\n')
    >>> b.check_ascending()
    []
    >>> b = BasicProgram('10 PRINT\n'
    ...                  '20 PRINT\n'
    ...                  '20 GOTO 30\n'
    ...                  '30 PRINT\n'
    ...                  '40 GOTO 30\n'
    ...                  '60 GOTO 30\n'
    ...                  'PRINT "IMMEDIATE MODE"\n'
    ...                  '50 GOTO 30\n')
    >>> for e in b.check_ascending(): print(e)
    ?OUT OF SEQUENCE LINE "20" IN: 20 GOTO 30
    ?OUT OF SEQUENCE LINE "50" IN: 50 GOTO 30

    Computed GOTOs/GOSUBs can be detected.  Note that a line number
    computation cannot appear after the THEN in an IF...THEN because
    it cannot readily be distinguished from a command.

    >>> b = BasicProgram('10 GOTO A * 4\n'
    ...                  '20 EARTH:AIR:WATER:FIRE:GOSUB 6+7\n'
    ...                  '30 GOTO 30\n'
    ...                  '35 GOTO 35.0\n'
    ...                  '40 IFATHENP*40\n'
    ...                  '50 IFAGOTOP*40\n'
    ...                  '60 ONAGOTO10,20,70\n'
    ...                  'GOSUB -10*-1\n')
    >>> for e in b.check_computed_jumps(): print(e)
    ?COMPUTED JUMP TO "A * 4" IN: 10 GOTO A * 4
    ?COMPUTED JUMP TO "6+7" IN: 20 EARTH:AIR:WATER:FIRE:GOSUB 6+7
    ?COMPUTED JUMP TO "35.0" IN: 35 GOTO 35.0
    ?COMPUTED JUMP TO "P*40" IN: 50 IFAGOTOP*40
    ?COMPUTED JUMP TO "-10*-1" IN: GOSUB -10*-1 (immediate mode, text file line 8)

    Computed GOTOs/GOSUBs are not analyzed for validity as jump targets.

    >>> for e in b.check_line_numbers(): print(e)
    ?UNDEFINED STATEMENT "70" IN: 60 ONAGOTO10,20,70

    >>> b = BasicProgram('418 IF IR%>=92 THEN ON IR%-91 GOTO 361,311,321,331')
    >>> print(b.lines[0].commands[0].__class__.__name__)
    IfThen
    >>> len([e for e in b.check_computed_jumps()])
    0

    Symbolic constants defined within the program can be collected
    and expanded.

    >>> b = BasicProgram('[value]=10\n'
    ...                  '[xyz]=PRINT\n'
    ...                  '10 FORI=1TO[value]:[xyz]I:NEXT\n')
    >>> b.dump()
    [value]=10
    [xyz]=PRINT
    10 FORI=1TO[value]:[xyz]I:NEXT
    >>> d = b.collect_symbols()
    >>> sorted(d.keys())
    ['value', 'xyz']
    >>> d['value']
    '10'
    >>> d['xyz']
    'PRINT'
    >>> b.dump()
    10 FORI=1TO[value]:[xyz]I:NEXT
    >>> b.expand_symbols(d)
    >>> b.dump()
    10 FORI=1TO10:PRINTI:NEXT

    """
    def __init__(self, text=None):
        self.lines = []
        if text is not None:
            text_file_line = 1
            for line in text.rstrip('\r\n').split('\n'):
                self.add_line(line, text_file_line)
                text_file_line += 1

    def add_line(self, line, text_file_line):
        self.lines.append(BasicLine(line, text_file_line))

    def check_ascending(self):
        errors = []
        last_line_number = None
        for line in self.lines:
            if line.line_number is not None:
                if last_line_number is not None:
                    if line.line_number.number <= last_line_number.number:
                        errors.append(OutOfSequence(line, line.line_number))
                last_line_number = line.line_number
        return errors

    def check_line_numbers(self):
        referenced = {}
        defined = {}
        errors = []
        text_file_line = 1
        for line in self.lines:
            if line.line_number is not None:
                location = line.line_number.number  
            else:
                location = "IMMEDIATE MODE (line %d)" % line.text_file_line
            defined[location] = line
            referenced[location] = line.referenced_line_numbers()
            text_file_line += 1
        for (location, referenced_line_numbers) in referenced.items():
            for referenced_line_number in referenced_line_numbers:
                if referenced_line_number.is_computed():
                    continue
                if referenced_line_number.number not in defined:
                    errors.append(UndefinedStatement(defined[location],
                        referenced_line_number))
        return errors

    def check_computed_jumps(self):
        errors = []
        for line in self.lines:
            for line_number in line.referenced_line_numbers():
                if line_number.is_computed():
                    errors.append(ComputedJump(line, line_number))
        return errors

    def strip_immediate_mode_commands(self):
        new_lines = []
        for line in self.lines:
            if line.line_number is not None:
                new_lines.append(line)
        self.lines = new_lines

    def strip_remarks(self, program_lines_only=False):
        new_lines = []
        for line in self.lines:
            if program_lines_only and line.line_number is None:
                new_lines.append(line)
                continue
            new_line = line.strip_remarks()
            if new_line is not None:
                new_lines.append(new_line)
        self.lines = new_lines

    def collect_symbols(self):
        symbols = {}
        new_lines = []
        for line in self.lines:
            match = re.match(r'^\[(.*?)\]=(.*?)$', line.text)
            if match:
                symbols[match.group(1)] = match.group(2)
            else:
                new_lines.append(line)
        self.lines = new_lines
        return symbols

    def expand_symbols(self, symbols):
        new_lines = []
        for line in self.lines:
            text = line.text
            text_file_line = line.text_file_line
            for symbol in symbols:
                pattern = re.escape('[%s]' % symbol)
                text = re.sub(pattern, symbols[symbol], text)
            new_line = BasicLine(text, text_file_line)
            new_lines.append(new_line)
        self.lines = new_lines

    def dump(self):
        for line in self.lines:
            print(line)


def main():
    parser = OptionParser()
    parser.add_option("-A", "--no-check-ascending",
                      dest="check_ascending",
                      default=True,
                      action="store_false",
                      help="do not check that line numbers are given in "
                           "strictly ascending order")
    parser.add_option("-C", "--allow-computed-jumps",
                      dest="allow_computed_jumps",
                      default=False,
                      action="store_true",
                      help="acknowledge that the program contains computed "
                           "GOTOs/GOSUBs, which cannot be analyzed by yucca; "
                           "without this flag, any occurrence of a computed "
                           "jump will be rejected as an error")
    parser.add_option("-I", "--strip-immediate-mode",
                      dest="strip_immediate_mode",
                      action="store_true",
                      help="strip immediate mode commands (implies -o)")
    parser.add_option("-L", "--no-check-line-numbers",
                      dest="check_line_numbers",
                      default=True,
                      action="store_false",
                      help="do not check that all target line numbers exist")
    parser.add_option("-o", "--dump-output",
                      dest="dump_output",
                      action="store_true",
                      help="dump (possibly transformed) program to standard "
                           "output; implied by other options")
    parser.add_option("-p", "--program-lines-only",
                      dest="program_lines_only",
                      action="store_true",
                      help="have transformations only affect program lines, "
                           "not immediate mode lines")
    parser.add_option("-R", "--strip-remarks",
                      dest="strip_remarks",
                      action="store_true",
                      help="strip all REM statements from program (implies -o)")
    parser.add_option("-t", "--test",
                      action="store_true", dest="test", default=False,
                      help="run internal test cases and exit")
    parser.add_option("-x", "--expand-symbols",
                      dest="expand_symbols",
                      action="store_true",
                      help="expand symbolic names defined in the source file "
                           "(implies -o)")

    (options, args) = parser.parse_args()

    if options.test:
        import doctest
        (fails, something) = doctest.testmod(sys.modules[__name__], verbose=True)
        if fails == 0:
            sys.exit(0)
        else:
            sys.exit(1)

    p = BasicProgram()
    text_file_line = 1
    for line in fileinput.input(args):
        p.add_line(line, text_file_line)
        text_file_line += 1

    if options.expand_symbols:
        options.dump_output = True
        symbols = p.collect_symbols()
        p.expand_symbols(symbols)

    if options.strip_immediate_mode:
        options.dump_output = True
        p.strip_immediate_mode_commands()

    if options.strip_remarks:
        options.dump_output = True
        p.strip_remarks(program_lines_only=options.program_lines_only)

    errors = []
    if options.check_ascending:
        errors += p.check_ascending()
    if not options.allow_computed_jumps:
        errors += p.check_computed_jumps()
    if options.check_line_numbers:
        errors += p.check_line_numbers()
    if len(errors) > 0:
        for error in errors:
            sys.stderr.write("%s\n" % error)
        sys.exit(1)

    if options.dump_output:
        p.dump()

    sys.exit(0)

if __name__ == "__main__":
    main()