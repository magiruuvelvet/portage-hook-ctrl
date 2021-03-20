module tests.filesystem_tests;

import dunit;
import tests.config;

import fs = utils.filesystem;

@Tag("FilesystemTests")
class FilesystemTests
{
    mixin UnitTest;

    @Test
    @Tag("FilesystemTests.isRegularFile")
    void isRegularFile()
    {
        // should be true
        bool res = fs.is_regular_file(TESTS_ASSET_DIRECTORY ~ "file");
        assertTrue(res);
        res = fs.is_regular_file(TESTS_ASSET_DIRECTORY ~ "symlink");
        assertTrue(res);

        // should be false
        res = fs.is_regular_file(TESTS_ASSET_DIRECTORY ~ "dir");
        assertFalse(res);
    }

    @Test
    @Tag("FilesystemTests.isDirectory")
    void isDirectory()
    {
        // should be true
        bool res = fs.is_directory(TESTS_ASSET_DIRECTORY ~ "dir");
        assertTrue(res);
        res = fs.is_directory(TESTS_ASSET_DIRECTORY ~ "dirlink");
        assertTrue(res);

        // should be false
        res = fs.is_directory(TESTS_ASSET_DIRECTORY ~ "file");
        assertFalse(res);
    }

    @Test
    @Tag("FilesystemTests.isExecutable")
    void isExecutable()
    {
        // should be true
        bool res = fs.is_executable(TESTS_ASSET_DIRECTORY ~ "exe");
        assertTrue(res);

        // should be false
        res = fs.is_executable(TESTS_ASSET_DIRECTORY ~ "file");
        assertFalse(res);
    }
}
