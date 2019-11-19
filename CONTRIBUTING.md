# Contributing to Commander X16 Demo Code

:+1::tada: First off, thanks for taking the time to contribute! :tada::+1:

How Can I Contribute?
  * [Reporting Bugs](#reporting-bugs)
  * [Pull Requests](#pull-requests)

## Reporting Bugs
Bugs are tracked as [GitHub issues](https://guides.github.com/features/issues/).

Before reporting a bug, ensure it is new, and add a short, simple way to reproduce it.

### Known issues
#### Demo xyz is not working on my emulator.
Because the emulator is growing faster, sometime the last pushed demo code need the last version of the emulator.

If a code does not work (like sprites) download always the LAST version of the emulator **before submitting** a bug report.

## Pull Requests
The easiest way of contributing is forking the repository and submitting a pull request.

Please follow these steps to have your contribution considered by the maintainers:

### For Basic files:

1. Contribute with source file ending in .bas extension (not binary). Filename must be without space and lowercase
2. Bas file must be in ASCII UTF-8 with uppercase letters 
3. If needed renumber them using the renumber tool (see tools directory)
4. If subroutine, provide at least one usage example

5. Do not forget to add AUTHOR AND LICENSE information in the head of the file via REMs

### For Assembly code:

1. Group your code in one directory per project
2. Include a Makefile per project
3. Include the directory in the main Makefile, adding it to the SUBDIRS variable (first line) 
4. Test it (see HOW TO COMPILE in the README.md)
5. Do not forget to add AUTHOR AND LICENSE information in the head of the file via ';' comments

## Documentation
For documentation download a copy of the [Commander X16 Programmers Reference](https://github.com/commanderx16/x16-docs).

Commander X16 has a BASIC V2 version derived from the C64 one. It will grow and offer more commands in the future.
Take a look at [Commander X16 ROM project](https://github.com/commanderx16/x16-rom) for a short introduction to the Basic and Kernel services.
