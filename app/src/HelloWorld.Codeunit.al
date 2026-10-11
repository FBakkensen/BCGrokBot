namespace FlemmingBakkensen.BCGrokBot;

/// <summary>
/// Sample codeunit that returns a greeting. Used to verify the build and test toolchain.
/// </summary>
codeunit 50100 "Hello World"
{
    Access = Public;
    /// <summary>
    /// Returns the greeting text.
    /// </summary>
    /// <returns>The text 'Hello, World!'.</returns>
    procedure GetGreeting(): Text
    begin
        exit('Hello, World!');
    end;
}
