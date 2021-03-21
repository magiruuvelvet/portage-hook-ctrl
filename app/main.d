import std.stdio;
import std.array;
import std.getopt;
import std.format;
import std.string;

import config;
import portage.hook;
import portage.hook_database;

void print_options(ref const Option[] options)
{
    writeln("Usage: portage-hook-ctrl [options]");
    writeln("Options:");

    struct Switch
    {
        string switches;
        string help;
    }

    Switch[] switches;
    foreach (ref const option; options)
    {
        string build_switches_part()
        {
            string part;
            if (option.optShort.length != 0)
            {
                part ~= option.optShort;
                if (option.optLong.length != 0)
                {
                    part ~= ", ";
                }
            }
            if (option.optLong.length != 0)
            {
                part ~= option.optLong;
            }
            return part;
        }

        switches ~= [Switch(build_switches_part(), option.help)];
    }

    // remove default injected uncustomizable help option from getopt
    if (options[options.length - 1].optLong == "--help")
    {
        switches = switches[0..switches.length - 1];
    }

    // find longest switch
    ulong length = 0;
    foreach (ref const sw; switches)
    {
        if (sw.switches.length > length)
        {
            length = sw.switches.length;
        }
    }

    // print all options
    foreach (ref const sw; switches)
    {
        writef("    %s", sw.switches);
        for (auto i = 0; i < length - sw.switches.length; ++i)
        {
            write(" ");
        }
        writefln("        %s", sw.help);
    }
}

void print_error(Args...)(in string fmt, Args args)
{
    stderr.writefln("portage-hook-ctrl: %s", format(fmt, args));
}

int main(string[] args)
{
    bool optionHelp = false;
    bool optionVersion = false;
    string packageName = "\0\0\0";
    string ebuildPhase = "\0\0\0";
    bool showHooks = true;
    bool run = false;
    bool debugOutput = false;

    // parse command line options
    // PERSONAL NOTE: look for a better command line parsing library for D, getopt sucks and has shitty defaults
    //                it also injects a help option by default with no way to turn it off or even customize it
    //                there is also no way to check for the presence of options, when an emptry string is valid for example
    ///               but the option must be explicitly provided on the command line
    const auto options = ((){
        try {
            return getopt(
                args,
                std.getopt.config.passThrough,
                std.getopt.config.caseSensitive,
                "help|h",       "Show this help and quit.", &optionHelp,
                "version|v",    "Show application version and quit.", &optionVersion,
                "pkg|p",        "Package category and name separated with a forward slash.", &packageName,
                "phase",        "Current ebuild phase.", &ebuildPhase,
                "show-hooks",   "Show available hooks for the given package. (default)", &showHooks,
                "run",          "Runs the current hook.", &run,
                "debug",        "Print messages which are hidden by default to avoid spamming the emerge output.", &debugOutput,
            );
        } catch (Exception e) {
            // this is an ugly hack, see personal note above
            return GetoptResult(false, [Option("", "", e.message.dup)]);
        }
    }());

    // check if error ocurred during parsing
    if (options.options.length == 1)
    {
        print_error("error ocurred during command line parsing: %s", options.options[0].help);
        return 1;
    }

    // print help output if requested and exit
    if (optionHelp)
    {
        print_options(options.options);
        return 0;
    }

    // print version output if requested and exit
    if (optionVersion)
    {
        writefln("portage-hook-ctrl %s", Config.Version);
        return 0;
    }

    // sanitize and/or normalize user input
    packageName = packageName.strip();
    ebuildPhase = ebuildPhase.strip();

    // HACK: check for option presence using a hack
    bool packageNamePresent = false;
    bool ebuildPhasePresent = false;
    if (packageName != "\0\0\0") packageNamePresent = true;
    if (ebuildPhase != "\0\0\0") ebuildPhasePresent = true;

    // validate given package name
    if (!Hook.validatePackageName(packageName))
    {
        print_error("a valid package name must be suplied! example: sys-kernel/gentoo-sources");
        return 1;
    }

    // ebuild phase is required when using the --run option
    if (run && !ebuildPhasePresent)
    {
        print_error("an ebuild phase must be specified when using the --run option!");
        return 1;
    }

    // ebuild phase may not be empty if present
    if (ebuildPhasePresent && ebuildPhase.length == 0)
    {
        print_error("the ebuild phase must not be empty!");
        return 1;
    }

    // should the hook be executed instead of doing a dry run
    if (run)
    {
        showHooks = false;
    }

    // DONE PARSING AND VALIDATING STUFF, LETS GO

    auto hook = HookDatabase.findHook(packageName);
    if (hook is null)
    {
        if (debugOutput)
        {
            print_error("no hooks found for package %s", packageName);
            stderr.writefln("%s", HookDatabase.lastErrorMessage());
        }
        return 0; // don't abort portage just because there were no hooks for the package
    }

    if (showHooks)
    {
        writefln("Available hooks for package: %s", packageName);
        foreach (ref const phase; hook.phases())
        {
            writefln(" - %s", phase);
        }

        return 0;
    }

    if (run)
    {
        if (hook.hasPhase(ebuildPhase))
        {
            writefln("%s%s>>> Running %s hook for [%s]...%s",
                "\033[1m", "\033[38;2;188;18;160m", ebuildPhase, packageName, "\033[0m");
        }
        auto exitStatus = hook.run(ebuildPhase);

        if (debugOutput)
        {
            if (exitStatus == Hook.EbuildPhaseNotPresent)
            {
                print_error("no %s hook found for package %s", ebuildPhase, packageName);
            }
            else if (exitStatus == Hook.HookNotParsed)
            {
                print_error("hook not parsed yet");
            }
            else if (exitStatus == Hook.InsufficientEnvironment)
            {
                print_error("not running inside portage!");
            }
        }

        // normalize exit status for better integration into portage
        // cancel merge when non-zero exit status for example
        if (exitStatus == Hook.EbuildPhaseNotPresent)
        {
            exitStatus = 0;
        }
        else if (exitStatus < 0)
        {
            exitStatus = 255;
        }

        return exitStatus;
    }

    return 255;
}
