import std.stdio;
import std.string;

import config;
import portage.hook;
import portage.hook_database;
import argparse;

void print_error(Args...)(in string fmt, Args args)
{
    stderr.writefln("portage-hook-ctrl: %s", format(fmt, args));
}

int main(string[] args)
{
    // parse command line options
    ArgumentParser parser = args;
    parser.addHelpOption("Show this help and quit.");
    parser.addArgument("v", "version",      "Show application version and quit.", Argument.Boolean);
    parser.addArgument("p", "pkg",          "Package category and name separated with a forward slash.");
    parser.addArgument("",  "phase",        "Current ebuild phase.");
    parser.addArgument("",  "show-hooks",   "Show available hooks for the given package. (default)", Argument.Boolean);
    parser.addArgument("",  "run",          "Runs the current hook.", Argument.Boolean);
    parser.addArgument("",  "debug",        "Print messages which are hidden by default to avoid spamming the emerge output.", Argument.Boolean);

    const auto res = parser.parse();

    // check if error ocurred during parsing
    if (res != ArgumentParserResult.Success)
    {
        print_error("error ocurred during command line parsing: %s", res);
        return 1;
    }

    // receive command line options
    const bool optionHelp = parser.exists("help");
    const bool optionVersion = parser.exists("version");
          string packageName = parser.get("pkg");
          string ebuildPhase = parser.get("phase");
    const bool ebuildPhasePresent = parser.exists("phase");
          bool showHooks = true;
    const bool run = parser.exists("run");
    const bool debugOutput = parser.exists("debug");

    // print help output if requested and exit
    if (optionHelp)
    {
        writeln("Usage: portage-hook-ctrl [options]");
        writeln("Options:");
        writeln(parser.help(true));
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
