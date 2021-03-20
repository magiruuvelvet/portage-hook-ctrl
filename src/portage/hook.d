module portage.hook;

import std.string;
import std.array;
import std.regex;
import std.algorithm;
import io = std.file;
import fs = utils.filesystem;

struct Hook
{
public:
    /// Status codes of `parse()` method.
    enum Status
    {
        Success = 0,            /// no errors during parsing
        InvalidPath,            /// the given root path is not valid or readable
        InvalidPackageName,     /// the given package name is not valid
        DefinitionFileNotFound, /// no valid hook definition file was found
        DefinitionFileInvalid,  /// definition file is not a valid utf-8 plain text file
        ExeFileNotFound,        /// the hook has no executable to run
        ExeFileNotRunnable,     /// the hook executable is not runnable
    }

public:
    /++
     + Constructs a new hook with package category and name.
     +/
    this(in string pkgName)
    {
        this._pkgName = pkgName;
    }

    /++
     + Is the hook valid?
     + Run `parse()` first or this always returns false.
     +/
    bool isValid() const
    {
        return this._valid;
    }

    /++
     + Package category and name.
     +/
    auto packageName() const
    {
        return this._pkgName;
    }

    /++
     + Full path to the hook executable.
     + This property is empty before `parse()` wasn't called.
     +/
    auto exe() const
    {
        return this._exe;
    }

    /++
     + List of supported ebuild phases of the hook.
     + This property is empty before `parse()` wasn't called.
     +/
    auto phases() const
    {
        return this._phases;
    }

    /++
     + Checks if the hook has a given ebuild phase.
     +/
    bool hasPhase(in string phase) const
    {
        return this._phases.canFind(phase);
    }

    /++
     + Helper function to validate if a package name is valid.
     + Format: `category/name`
     +/
    static bool validatePackageName(in string pkgName)
    {
        static immutable string portage_pkg_name_validator = r"^\w+\/\w+$";
        auto match = pkgName.matchAll(portage_pkg_name_validator);
        return cast(bool) match;
    }

    /++
     + Parses the hook definition from the given package name.
     + If the package name is empty this function instantly returns false.
     +
     + Params:
     +   rootPath = full path to the directory where hooks are stored (example: `/etc/portage/hooks`)
     +
     + Returns:
     +   Whenever the parsing of the hook definition file was successful
     +   and the hook binary is world executable.
     +/
    Status parse(in string rootPath = "/etc/portage/hooks")
    {
        // hooks was already parsed, return immediately
        if (this._valid)
        {
            return Status.Success;
        }

        // check if a root path was given first
        if (rootPath.length == 0)
        {
            return Status.InvalidPath;
        }

        // check if the root path is absolute
        if (rootPath[0] != '/')
        {
            return Status.InvalidPath;
        }

        // check if the package name is valid
        if (this._pkgName.length == 0 || !this.validatePackageName(this._pkgName))
        {
            return Status.InvalidPackageName;
        }

        // check if root path is a directory
        if (!fs.is_directory(rootPath))
        {
            return Status.InvalidPath;
        }

        // $rootpath/category/name.hook
        const string defFile = rootPath ~ '/' ~ this._pkgName ~ ".hook";
        if (!fs.is_regular_file(defFile))
        {
            return Status.DefinitionFileNotFound;
        }

        // parse definition file
        try
        {
            // read file and split into lines
            string contents = io.readText(defFile);
            string[] phasesRaw = contents.splitLines();

            // insert all non-empty lines into the ebuild phases array
            foreach (const string phase; phasesRaw)
            {
                const string phaseStripped = phase.strip();
                if (phaseStripped.length != 0)
                {
                    this._phases.insertInPlace(this._phases.length, phaseStripped);
                }
            }
        }
        catch (Exception)
        {
            return Status.DefinitionFileInvalid;
        }

        // now check on the executable
        const string exe = rootPath ~ '/' ~ this._pkgName;
        if (!fs.is_regular_file(exe))
        {
            return Status.ExeFileNotFound;
        }
        if (!fs.is_executable(exe))
        {
            return Status.ExeFileNotRunnable;
        }

        // set executable path on hook
        this._exe = exe;

        // make hook valid
        this._valid = true;

        return Status.Success;
    }

private:
    // hook properties
    string _pkgName;
    string _exe;
    string[] _phases;

    // state variables
    bool _valid = false;
}
