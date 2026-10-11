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
        Assert.AreEqual('Hello, World!', HelloWorld.GetGreeting(), 'Unexpected greeting');
    end;
}
