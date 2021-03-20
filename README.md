# Portage Hook Controller

This is a small application to run hooks for each package and
ebuild phase in Gentoo's package manager Portage.

The idea is similar to Arch Linux pacman libalpm, but you
can write actual scripts which are run, instead of a primitive
config file with some commands in it. Also the layout is much
cleaner than in libalpm so you don't get lost finding your
custom hooks again.

What this hook runner can't do for you is to run scripts based
on files which were modified. You need a fixed package name.

## Install

1. Get build dependencies

 - [D](https://dlang.org/) Compiler (tested with LDC2)
 - CMake (latest from Gentoo repos)

2. Compile with CMake as usual

```sh
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
```

The binary can be found under `build/bin`.

## Configure

Put this snippet in your Portage `bashrc` (`/etc/portage/bashrc`):

```sh
# invoke emerge hook trigger for each package and ebuild phase (except depend)
# hooks are stored in /etc/portage/hooks
if [[ ! -z "$EBUILD_PHASE" && "$EBUILD_PHASE" != "depend" ]]; then
    echo -e "\e[1m>>> \e[38;2;120;120;39m[${CATEGORY}/${PN}]\e[0m\e[1m Running ebuild phase \e[38;2;48;90;116m$EBUILD_PHASE\e[0m\e[1m...\e[0m"
    portage-hook-ctrl --pkg "${CATEGORY}/${PN}" --phase "$EBUILD_PHASE" --run
fi
```

Create a directory `hooks` inside your Portage config directory.

The directory structure of hooks is the same as in the repositories with
a package category and name.

The hook script must be located inside the correct category directory and
must be the exact package name. Make sure that the executable bit is set
on all hooks, otherwise they will not run. This is also a nice way to toggle
hooks without renaming the file. Alongside the hook script you must also
place a hook definition file. The filename is the package name with the
`.hook` file extension added. The file contains a list of supported ebuild
phases by your script. Only phases listed in this file will be executed
with your script.

You can write your hooks in whatever scripting or programming language you
want. The first argument which is passed to your hook is the current ebuild
phase. You can obtain the ebuild phase names from the `$EBUILD_PHASE` env
var as seen above in the bashrc snippet.

A list of ebuild phases invoked in exactly that order:

 - `pretend` (verifying ebuild manifests, not sure about that phase as it isn't run for every package)
 - `clean`
 - `setup`
 - `unpack` (executed before the `src_unpack` function)
 - `prepare` (executed before the `src_prepare` function)
 - `configure` (executed before the `src_configure` function)
 - `compile` (executed before the `src_compile` function)
 - `test` (executed before running unit tests)
 - `install` (executed before the `src_install` function)
 - `instprep` (prepare the installation image before merged into the system, the env var `$ED` points to the `DESTDIR` of the package, useful to remove unneeded files and bloat)
 - `preinst`
 - `prerm`
 - `postrm`
 - `cleanrm`
 - `postinst` (executed after the package is merged into the system)
 - `clean`

Note that the clean phase is run twice.

ALL HOOKS ARE ALWAYS RUN **BEFORE** THE NATIVE EBUILD FUNCTIONS!
If you need to run a hook after ebuild does its own stuff you need to hack in
the script at the next ebuild phase and hope for the best.

If you need examples you can take a look [here](https://github.com/magiruuvelvet/gentoo-portage-config/tree/master/hooks).

A typical shell script hook would look like this:

```sh
#!/bin/sh

postinst() {
    echo doing some stuff with the installed files from package
}

case "$1" in
    postinst) postinst ;;
    *) : ;;
esac
```
