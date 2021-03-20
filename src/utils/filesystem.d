module utils.filesystem;

import io = std.file;
import stat = core.sys.posix.sys.stat;

/++
 + Checks if the given path is a directory or a symbolic link
 + to a directory.
 + This function doesn't throw, but returns false instead.
 +/
bool is_directory(in string dirPath) nothrow
{
    try
    {
        if (io.isDir(dirPath))
        {
            return true;
        }
        else if (io.isSymlink(dirPath))
        {
            const string target = io.readLink(dirPath);

            // relative path
            if (target.length > 0 && target[0] != '/')
            {
                return is_directory(dirPath ~ '/' ~ target);
            }

            // absolute path
            else
            {
                return is_directory(target);
            }
        }
        else
        {
            return false;
        }
    }
    catch (Exception)
    {
        return false;
    }
}

/++
 + Checks if the given file is a regular file or a symbolic link
 + to a regular file.
 + This function doesn't throw, but returns false instead.
 +/
bool is_regular_file(in string filePath) nothrow
{
    try
    {
        if (io.isFile(filePath))
        {
            return true;
        }
        else if (io.isSymlink(filePath))
        {
            const string target = io.readLink(filePath);

            // relative path
            if (target.length > 0 && target[0] != '/')
            {
                return is_regular_file(filePath ~ '/' ~ target);
            }

            // absolute path
            else
            {
                return is_regular_file(target);
            }
        }
        else
        {
            return false;
        }
    }
    catch (Exception)
    {
        return false;
    }
}

/++
 + Checks if the given file is user, group and world executable.
 + This function doesn't throw, but returns false instead.
 +
 + TODO: resolve link target and check on the actual file
 + NOTE: symlinks are always executable, directories can be executable too
 +/
bool is_executable(in string file) nothrow
{
    try
    {
        const auto attr = io.getAttributes(file);
        return attr & stat.S_IXUSR && attr & stat.S_IXGRP && attr & stat.S_IXOTH;
    }
    catch (Exception)
    {
        return false;
    }
}
