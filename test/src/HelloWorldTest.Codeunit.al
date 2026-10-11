namespace FlemmingBakkensen.MyBCApp.Test;

using FlemmingBakkensen.MyBCApp;
using System.TestLibraries.Utilities;

codeunit 50150 "Hello World Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure GreetingIsHelloWorld()
    var
        HelloWorld: Codeunit "Hello World";
    begin
        // [SCENARIO] GetGreeting returns the fixed greeting
        // [WHEN] the greeting is requested
        // [THEN] it is 'Hello, World!'
        Assert.AreEqual('Hello, World!', HelloWorld.GetGreeting(), 'Unexpected greeting');
    end;
}
