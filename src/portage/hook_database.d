module portage.hook_database;

import config;
import portage.hook;
import fs = utils.filesystem;

static struct HookDatabase
{
    @disable this();

    /// stores the last error of the `findHook()` function
    static HookStatus lastError = HookStatus.Success;

    /++
     + Finds and parses the hook for the given package name.
     +
     + Returns:
     +   a pointer to the found hook or a null pointer if no hook was found
     +/
    static const(Hook*) findHook(in string pkgName)
    {
        if (!fs.is_directory(Config.PortageHookDir))
        {
            return null;
        }

        auto hook = new Hook(pkgName);
        lastError = hook.parse(Config.PortageHookDir);
        if (lastError != HookStatus.Success)
        {
            hook.destroy();
            return null;
        }

        return hook;
    }
}
