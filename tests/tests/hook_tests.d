module tests.hook_tests;

import dunit;
import tests.config;

import std.algorithm;
import portage.hook;

@Tag("HookTests")
class HookTests
{
    mixin UnitTest;

    @Test
    @Tag("HookTests.basicTest")
    void basicTest()
    {
        Hook hook;
        assertEquals(hook.packageName(), "");
        assertEquals(hook.exe(), "");
        assertEquals(hook.phases(), []);
        assertFalse(hook.isValid());
    }

    @Test
    @Tag("HookTests.copyTest")
    void copyTest()
    {
        Hook hook = "test/test";
        assertEquals(hook.packageName(), "test/test");

        auto copy = hook;
        assertEquals(copy.packageName(), "test/test");
    }

    @Test
    @Tag("HookTests.parseTest")
    void parseTest()
    {
        Hook hook = "test/test";
        assertEquals(hook.packageName(), "test/test");

        Hook.Status res = hook.parse(TESTS_ASSET_DIRECTORY);
        assertEquals(res, Hook.Status.Success);
        assertTrue(hook.isValid());

        assertEquals(hook.phases(), ["compile", "instprep"]);
        bool equal = hook.phases() == ["instprep"];
        assertFalse(equal);
        // TESTS_ASSET_DIRECTORY ends with trailing slash to exe path contains it too
        assertEquals(hook.exe(), TESTS_ASSET_DIRECTORY ~ "/test/test");

        assertTrue(hook.hasPhase("compile"));
        assertTrue(hook.hasPhase("instprep"));
        assertFalse(hook.hasPhase(""));
        assertFalse(hook.hasPhase("prepare"));
    }

    @Test
    @Tag("HookTests.packageNameValidatorTest")
    void packageNameValidatorTest()
    {
        assertTrue(Hook.validatePackageName("test/test"));
        assertTrue(Hook.validatePackageName("test/test2"));
        assertTrue(Hook.validatePackageName("test/test+"));
        assertTrue(Hook.validatePackageName("test+/test"));
        assertTrue(Hook.validatePackageName("test2/test"));
        assertTrue(Hook.validatePackageName("dev-test2/test"));
        assertTrue(Hook.validatePackageName("dev-test2/dev-test"));

        assertFalse(Hook.validatePackageName("test/"));
        assertFalse(Hook.validatePackageName("/test"));
        assertFalse(Hook.validatePackageName("test"));
        assertFalse(Hook.validatePackageName("/"));

        assertFalse(Hook.validatePackageName("test//"));
        assertFalse(Hook.validatePackageName("test//test"));
        assertFalse(Hook.validatePackageName("test/??"));
    }
}
